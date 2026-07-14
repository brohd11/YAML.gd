extends YAMLTest

# Document markers. Before these were handled, a leading `---` was read as a list
# entry by _is_list_line and the whole document was destroyed:
# parse("---\nname: test") returned [[[null]]].

func run() -> bool:
	_check(leading_marker, leading_marker_exp)
	_check(trailing_marker, trailing_marker_exp)
	_check(marker_in_block_scalar, marker_in_block_scalar_exp)
	_check(marker_with_content, marker_with_content_exp)
	_check(list_doc, list_doc_exp)

	# parse() takes the first document; parse_all() takes every one.
	_expect(YAMLParser.parse(two_docs), {"a": 1})
	_expect(YAMLParser.parse_all(two_docs), [{"a": 1}, {"b": 2}])
	_expect(YAMLParser.parse_all(leading_marker), [{"name": "test", "value": 1}])
	_expect(YAMLParser.parse_all(""), [])
	_expect(YAMLParser.parse_all("# just a comment\n"), [])

	# A dash is a list entry only when alone or followed by a space, so "- -" still
	# nests but "---" does not.
	_expect(YAMLParser.parse("- - a\n- b"), [["a"], "b"])

	return passed()


# Compare a value the test computed itself (no dump round-trip).
func _expect(got, expected) -> void:
	if got == expected:
		if pass_state == -1:
			pass_state = 0
		return
	pass_state = 1
	_log(str("   got: ", got))
	_log(str("   exp: ", expected))


var leading_marker = """---
name: test
value: 1
"""
var leading_marker_exp = {"name": "test", "value": 1}


var trailing_marker = """---
a: 1
...
"""
var trailing_marker_exp = {"a": 1}


# A marker is only a marker in column 0. Block scalar content is always indented
# deeper than its key, so this `---` is literal text, not a document break.
var marker_in_block_scalar = """key: |
  ---
  not a marker
"""
var marker_in_block_scalar_exp = {"key": "---\nnot a marker\n"}


# "--- foo" puts the document's root node on the marker line.
var marker_with_content = """--- hello
"""
var marker_with_content_exp = "hello"


var list_doc = """---
- a
- b
"""
var list_doc_exp = ["a", "b"]


var two_docs = """---
a: 1
---
b: 2
"""
