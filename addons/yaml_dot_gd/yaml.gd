extends RefCounted
class_name YAMLParser

# Node types kept for compatibility with any external references.
const NODE_DICT = 0
const NODE_LIST = 1

# Block scalar header tokens.
const _BLOCK_HEADERS = ["|", ">", "|-", ">-", "|+", ">+"]

# ---------------------------------------------------------------------------
# Line cursor: holds the split lines and a mutable index we fully control.
# Using an explicit index (instead of `for i in range(...)`) is what allows
# block scalars to be consumed by lookahead and lets us re-examine a line
# after a nested block returns. This avoids the old `i -= 1` no-op bug.
# ---------------------------------------------------------------------------
class _Cursor:
	var lines: PackedStringArray
	var i: int = 0

	func _init(text: String) -> void:
		lines = text.split("\n", true)

	# Index of the next significant (non-empty, non-comment) line, or -1.
	func peek() -> int:
		var j = i
		while j < lines.size():
			var s = lines[j].rstrip("\r")
			var st = s.lstrip(" \t")
			if st.is_empty() or st[0] == "#":
				j += 1
				continue
			return j
		return -1

	func line_at(idx: int) -> String:
		return lines[idx].rstrip("\r")


# ---------------------------------------------------------------------------
# Public entry point.
# ---------------------------------------------------------------------------
func parse(yaml_content: String) -> Variant:
	var cur = _Cursor.new(yaml_content)
	var j = cur.peek()
	if j == -1:
		return null
	return _parse_block(cur, _get_indent_level(cur.line_at(j)))


# Parse all sibling nodes at exactly `indent`. Decides map vs list from the
# first significant line at that indent.
func _parse_block(cur: _Cursor, indent: int) -> Variant:
	var j = cur.peek()
	if j == -1:
		return null
	var line0 = cur.line_at(j)
	if _get_indent_level(line0) != indent:
		return null
	var content0 = _strip_inline_comment(line0.substr(indent))
	if _is_list_line(content0):
		return _parse_list(cur, indent)
	return _parse_map(cur, indent)


func _parse_map(cur: _Cursor, indent: int) -> Dictionary:
	var result = {}
	while true:
		var j = cur.peek()
		if j == -1:
			break
		var raw = cur.line_at(j)
		var ind = _get_indent_level(raw)
		if ind != indent:
			break
		var content = _strip_inline_comment(raw.substr(indent))
		if _is_list_line(content):
			break
		var kv = _split_key_value(content)
		var key = _unquote_key(kv[0])
		var value_str = kv[1]
		cur.i = j + 1

		if value_str == null:
			result[key] = _parse_value_after_key(cur, indent)
		elif value_str in _BLOCK_HEADERS:
			result[key] = _consume_block_scalar(cur, value_str, indent)
		else:
			result[key] = _parse_scalar_or_quoted(value_str)
	return result


# After a "key:" with no inline value, decide between a nested block, a
# same-indent block sequence, or a plain null.
func _parse_value_after_key(cur: _Cursor, indent: int) -> Variant:
	var nj = cur.peek()
	if nj == -1:
		return null
	var nraw = cur.line_at(nj)
	var nind = _get_indent_level(nraw)
	var ncontent = _strip_inline_comment(nraw.substr(nind))
	if nind > indent:
		return _parse_block(cur, nind)
	# A block sequence may be indented at the SAME column as its key.
	if nind == indent and _is_list_line(ncontent):
		return _parse_list(cur, indent)
	return null


func _parse_list(cur: _Cursor, indent: int) -> Array:
	var result = []
	while true:
		var j = cur.peek()
		if j == -1:
			break
		var raw = cur.line_at(j)
		var ind = _get_indent_level(raw)
		if ind != indent:
			break
		var content = _strip_inline_comment(raw.substr(indent))
		var stripped = content.lstrip(" ")
		if not stripped.begins_with("-"):
			break

		# Column where item content begins (after the dash and its spaces).
		var dash_col = indent + (content.length() - stripped.length())
		var after = stripped.substr(1)  # everything after the dash
		var after_trimmed = after.lstrip(" ")
		var item_indent = dash_col + 1 + (after.length() - after_trimmed.length())
		var item_text = after_trimmed.strip_edges()
		cur.i = j + 1

		# Empty dash: value lives on the following deeper lines.
		if item_text.is_empty():
			var nj = cur.peek()
			if nj != -1 and _get_indent_level(cur.line_at(nj)) > indent:
				result.append(_parse_block(cur, _get_indent_level(cur.line_at(nj))))
			else:
				result.append(null)
			continue

		# Nested list: "- - x" means this item is itself a list.
		if after_trimmed.begins_with("-"):
			result.append(_parse_nested_dash_list(cur, j, item_indent, indent))
			continue

		var kv = _split_key_value(item_text)
		if kv[1] == null and not item_text.ends_with(":"):
			# Plain scalar item.
			result.append(_parse_scalar_or_quoted(item_text))
		else:
			# Map item: first pair is inline, remaining keys sit at item_indent.
			var d = {}
			var k = _unquote_key(kv[0])
			var v = kv[1]
			if v == null:
				var nj = cur.peek()
				if nj != -1 and _get_indent_level(cur.line_at(nj)) >= item_indent \
						and _get_indent_level(cur.line_at(nj)) > indent:
					d[k] = _parse_block(cur, _get_indent_level(cur.line_at(nj)))
				else:
					d[k] = null
			elif v in _BLOCK_HEADERS:
				# A sibling key at item_indent must terminate the block, so the
				# block's own content has to be deeper than item_indent - 1.
				d[k] = _consume_block_scalar(cur, v, item_indent - 1)
			else:
				d[k] = _parse_scalar_or_quoted(v)
			_merge_item_keys(cur, d, item_indent)
			result.append(d)
	return result


# Collect additional "key: value" pairs of a list item's map (lines at exactly
# item_indent that are not themselves list entries).
func _merge_item_keys(cur: _Cursor, d: Dictionary, item_indent: int) -> void:
	while true:
		var j = cur.peek()
		if j == -1:
			break
		var raw = cur.line_at(j)
		if _get_indent_level(raw) != item_indent:
			break
		var content = _strip_inline_comment(raw.substr(item_indent))
		if _is_list_line(content):
			break
		var kv = _split_key_value(content)
		var k = _unquote_key(kv[0])
		var v = kv[1]
		cur.i = j + 1
		if v == null:
			d[k] = _parse_value_after_key(cur, item_indent)
		elif v in _BLOCK_HEADERS:
			d[k] = _consume_block_scalar(cur, v, item_indent)
		else:
			d[k] = _parse_scalar_or_quoted(v)


# Handle "- - x" by reconstructing a sub-document at item_indent: the remainder
# of the dash line (re-padded) plus the following lines that belong to it.
func _parse_nested_dash_list(cur: _Cursor, header_idx: int, item_indent: int, parent_indent: int) -> Variant:
	var raw0 = cur.line_at(header_idx)
	var stripped = raw0.substr(parent_indent).lstrip(" ")
	var after = stripped.substr(1).lstrip(" ")  # text after the first dash
	var synth = PackedStringArray()
	synth.append(" ".repeat(item_indent) + after)
	while cur.i < cur.lines.size():
		var r = cur.line_at(cur.i)
		if r.strip_edges() == "":
			synth.append("")
			cur.i += 1
			continue
		if _get_indent_level(r) < item_indent:
			break
		synth.append(r)
		cur.i += 1
	var sub = _Cursor.new("\n".join(synth))
	return _parse_block(sub, item_indent)


# Consume a block scalar (| or >) by lookahead. The block ends at the first
# non-blank line whose indent is less than the block's established indent.
func _consume_block_scalar(cur: _Cursor, header: String, parent_indent: int) -> String:
	var style = ML_LITERAL if header.begins_with("|") else ML_FOLDED
	var chomping = "clip"
	if header.ends_with("-"):
		chomping = "strip"
	elif header.ends_with("+"):
		chomping = "keep"

	var collected = []
	var block_indent = -1
	while cur.i < cur.lines.size():
		var raw = cur.line_at(cur.i)
		if raw.strip_edges() == "":
			collected.append("")
			cur.i += 1
			continue
		var ind = _get_indent_level(raw)
		if block_indent == -1:
			if ind <= parent_indent:
				break
			block_indent = ind
		elif ind < block_indent:
			break
		collected.append(raw.substr(block_indent) if raw.length() >= block_indent else "")
		cur.i += 1

	return _process_multiline_content(collected, style, chomping)


# Multiline state markers (kept for _process_multiline_content signature parity).
const ML_LITERAL = 1
const ML_FOLDED = 2


# Process collected block-scalar lines according to style and chomping.
func _process_multiline_content(content: Array, style: int, chomping: String) -> String:
	var lines = content.duplicate()

	# Folding: join consecutive non-empty lines with a single space.
	if style == ML_FOLDED:
		var out = []
		var prev_empty = false
		for ln in lines:
			var empty = ln.strip_edges().is_empty()
			if empty:
				out.append("")
				prev_empty = true
			else:
				if not out.is_empty() and not prev_empty \
						and not out[-1].ends_with(" ") and out[-1] != "":
					out[-1] += " " + ln
				else:
					out.append(ln)
				prev_empty = false
		lines = out

	var full_content = "\n".join(lines)

	match chomping:
		"strip":
			full_content = full_content.rstrip("\n")
		"clip":
			full_content = full_content.rstrip("\n") + "\n"
		"keep":
			pass
	return full_content


# ---------------------------------------------------------------------------
# Scalar / value helpers.
# ---------------------------------------------------------------------------

# Parse a value that may be a plain scalar, quoted string, or inline flow.
static func _parse_scalar_or_quoted(s: String) -> Variant:
	return _parse_value(s)


# Convert a string token to the appropriate Godot type.
static func _parse_value(s: String) -> Variant:
	s = s.strip_edges()
	if s.is_empty(): return null
	if s == "null" or s == "~": return null
	if s == "true": return true
	if s == "false": return false
	if s.is_valid_int(): return s.to_int()
	if s.is_valid_float(): return s.to_float()

	# Inline flow sequence.
	if s.begins_with("[") and s.ends_with("]"):
		var inner = s.substr(1, s.length() - 2)
		var result = []
		if not inner.strip_edges().is_empty():
			for item in _split_top_level(inner, ","):
				result.append(_parse_value(item))
		return result

	# Inline flow mapping.
	if s.begins_with("{") and s.ends_with("}"):
		var inner = s.substr(1, s.length() - 2)
		var result = {}
		if not inner.strip_edges().is_empty():
			for item in _split_top_level(inner, ","):
				var idx = _find_top_level(item, ":")
				if idx == -1:
					result[_parse_value(item)] = null
				else:
					var k = _parse_value(item.substr(0, idx))
					var v = item.substr(idx + 1).strip_edges()
					result[k] = null if v.is_empty() else _parse_value(v)
		return result

	# Quoted string.
	if (s.begins_with('"') and s.ends_with('"')) or (s.begins_with("'") and s.ends_with("'")):
		return _parse_quoted_string(s)

	return s


# Parse a quoted string, resolving escape sequences (double-quote style) and
# doubled-quote escapes (single-quote style).
static func _parse_quoted_string(s: String) -> String:
	if s.length() < 2:
		return s
	var quote = s[0]
	var content = s.substr(1, s.length() - 2)
	var result = ""
	var escape = false
	var i = 0
	while i < content.length():
		var c = content[i]
		if quote == "'":
			# In single quotes, only '' is special (escaped single quote).
			if c == "'" and i + 1 < content.length() and content[i + 1] == "'":
				result += "'"
				i += 2
				continue
			result += c
			i += 1
			continue
		# Double-quote escape handling.
		if escape:
			escape = false
			match c:
				"n": result += "\n"
				"t": result += "\t"
				"r": result += "\r"
				"\\": result += "\\"
				"\"": result += "\""
				"'": result += "'"
				_: result += c
			i += 1
			continue
		if c == "\\":
			escape = true
			i += 1
			continue
		result += c
		i += 1
	return result


static func _unquote_key(k: String) -> String:
	k = k.strip_edges()
	if (k.begins_with('"') and k.ends_with('"')) or (k.begins_with("'") and k.ends_with("'")):
		return _parse_quoted_string(k)
	return k


# Split "key: value" on the first top-level ": " (or trailing ":").
# Returns [key, value_or_null].
static func _split_key_value(line: String) -> Array:
	var depth = 0
	var quote = ""
	var i = 0
	while i < line.length():
		var c = line[i]
		if not quote.is_empty():
			if c == quote:
				quote = ""
			i += 1
			continue
		if c == '"' or c == "'":
			quote = c
			i += 1
			continue
		if c == "[" or c == "{":
			depth += 1
		elif c == "]" or c == "}":
			depth -= 1
		elif depth == 0 and c == ":" and (i + 1 >= line.length() or line[i + 1] == " "):
			var v = line.substr(i + 1).strip_edges()
			return [line.substr(0, i).strip_edges(), null if v.is_empty() else v]
		i += 1
	if line.strip_edges().ends_with(":"):
		var key = line.strip_edges()
		return [key.substr(0, key.length() - 1).strip_edges(), null]
	return [line.strip_edges(), null]


# True if a line (already indent-stripped) starts a list entry.
static func _is_list_line(content: String) -> bool:
	var s = content.lstrip(" ")
	if not s.begins_with("-"):
		return false
	return s.length() == 1 or s[1] == " " or s[1] == "-"


# Remove a trailing " #..." comment at top level (outside quotes/brackets).
static func _strip_inline_comment(content: String) -> String:
	var depth = 0
	var quote = ""
	for i in range(content.length()):
		var c = content[i]
		if not quote.is_empty():
			if c == quote:
				quote = ""
			continue
		if c == '"' or c == "'":
			quote = c
			continue
		if c == "[" or c == "{":
			depth += 1
		elif c == "]" or c == "}":
			depth -= 1
		elif depth == 0 and c == "#" and i > 0 and content[i - 1] == " ":
			return content.substr(0, i).strip_edges()
	return content


# Count leading spaces (YAML indentation is spaces only).
static func _get_indent_level(line: String) -> int:
	var indent = 0
	for c in line:
		if c == ' ':
			indent += 1
		else:
			break
	return indent


# Find a delimiter char at bracket-depth 0 outside quotes; -1 if none.
static func _find_top_level(s: String, delim: String) -> int:
	var depth = 0
	var quote = ""
	for i in range(s.length()):
		var c = s[i]
		if not quote.is_empty():
			if c == quote:
				quote = ""
			continue
		if c == '"' or c == "'":
			quote = c
			continue
		if c == "[" or c == "{":
			depth += 1
		elif c == "]" or c == "}":
			depth -= 1
		elif depth == 0 and c == delim:
			return i
	return -1


# Split a string on a single-char delimiter at bracket-depth 0 outside quotes.
static func _split_top_level(s: String, delim: String) -> Array:
	var parts = []
	var buf = ""
	var depth = 0
	var quote = ""
	var i = 0
	while i < s.length():
		var c = s[i]
		if not quote.is_empty():
			buf += c
			if c == quote:
				quote = ""
			i += 1
			continue
		if c == '"' or c == "'":
			quote = c
			buf += c
			i += 1
			continue
		if c == "[" or c == "{":
			depth += 1
		elif c == "]" or c == "}":
			depth -= 1
		if depth == 0 and c == delim:
			parts.append(buf.strip_edges())
			buf = ""
			i += 1
			continue
		buf += c
		i += 1
	parts.append(buf.strip_edges())
	return parts


# ---------------------------------------------------------------------------
# Dump (unchanged behaviour from the original; kept for round-tripping).
# ---------------------------------------------------------------------------
static func dump(data, indent: int = 0) -> String:
	if (data is Dictionary or data is Array) and data.is_empty():
		return "{}" if data is Dictionary else "[]"

	var lines = []
	var pad = "  ".repeat(indent)

	if data is Dictionary:
		for key in data:
			var safe_key = _scalar(key)
			var val = data[key]
			if val is Dictionary or val is Array:
				if val.is_empty():
					lines.append("%s%s: %s" % [pad, safe_key, "{}" if val is Dictionary else "[]"])
				else:
					lines.append("%s%s:" % [pad, safe_key])
					lines.append(dump(val, indent + 1))
			else:
				lines.append("%s%s: %s" % [pad, safe_key, _scalar(val)])
	elif data is Array:
		for item in data:
			if item is Dictionary or item is Array:
				if item.is_empty():
					lines.append("%s- %s" % [pad, "{}" if item is Dictionary else "[]"])
				else:
					lines.append("%s-" % pad)
					lines.append(dump(item, indent + 1))
			else:
				lines.append("%s- %s" % [pad, _scalar(item)])

	return "\n".join(lines)


static func _scalar(val) -> String:
	if val == null:
		return "null"
	if val is bool:
		return "true" if val else "false"
	if val is int or val is float:
		return str(val)

	var s = str(val)
	if s.is_empty():
		return '""'

	var needs_quotes = false
	var lower_s = s.to_lower()
	if lower_s in ["true", "false", "null", "yes", "no", "on", "off", "~"]:
		needs_quotes = true
	elif s.is_valid_float() or s.is_valid_int():
		needs_quotes = true

	var special_chars = [
		":", "{", "}", "[", "]", ",", "&", "*", "#", "?", "|",
		"-", "<", ">", "=", "!", "%", "@", "`", "\n", "\"", "\\"
	]
	if not needs_quotes:
		for c in special_chars:
			if c in s:
				needs_quotes = true
				break

	if s.begins_with(" ") or s.ends_with(" "):
		needs_quotes = true

	if needs_quotes:
		s = s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
		return '"%s"' % s

	return s
