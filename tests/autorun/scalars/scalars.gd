extends YAMLTest

# Plain scalars and scalar typing.
#
# Before plain scalars were handled, `key: a` followed by an indented continuation
# line truncated the REST OF THE DOCUMENT: _parse_map broke on the indent mismatch
# and returned, so parse("key: a\n  b\nother: x") gave {"key": "a"} -- losing both
# the continuation and the sibling key.

func run() -> bool:
	_check(continuation, continuation_exp)
	_check(scalar_block, scalar_block_exp)
	_check(scalar_doc, scalar_doc_exp)
	_check(item_continuation, item_continuation_exp)
	_check(sibling_not_swallowed, sibling_not_swallowed_exp)
	_check(quoted_not_continued, quoted_not_continued_exp)
	_check(empty_dash_scalar, empty_dash_scalar_exp)

	_check(bools, bools_exp)
	_check(numbers, numbers_exp)
	_check(not_numbers, not_numbers_exp)
	_check(block_indent_indicator, block_indent_indicator_exp)
	_check(empty_block_scalar, empty_block_scalar_exp)
	_check(lookalike_strings, lookalike_strings_exp)

	return passed()


# A value running on across deeper lines; each break folds to a single space. The
# sibling key at column 0 must survive.
var continuation = """key: some long
  text continues
other: x
"""
var continuation_exp = {"key": "some long text continues", "other": "x"}


# A block that is itself a plain scalar rather than a map.
var scalar_block = """key:
  long text
  more text
other: x
"""
var scalar_block_exp = {"key": "long text more text", "other": "x"}


# A whole document that is one scalar. This also pins the dump() scalar root:
# dump("hello") used to return "" because a non-collection fell through both
# branches, which broke the reparse half of _check.
var scalar_doc = "hello"
var scalar_doc_exp = "hello"


var item_continuation = """- one long
  item
- two
"""
var item_continuation_exp = ["one long item", "two"]


# The continuation threshold for a list item's map value is item_indent, so a
# sibling key at that column is a key, not a continuation.
var sibling_not_swallowed = """- name: a
  other: z
- name: b
"""
var sibling_not_swallowed_exp = [{"name": "a", "other": "z"}, {"name": "b"}]


# Only PLAIN scalars run on. A quoted one is left alone.
var quoted_not_continued = """key: "quoted"
other: x
"""
var quoted_not_continued_exp = {"key": "quoted", "other": "x"}


var empty_dash_scalar = """-
  just text
"""
var empty_dash_scalar_exp = ["just text"]


# YAML 1.2 core accepts any case. yes/no/on/off stay strings (that is 1.1), which
# matches what _scalar() quotes on the way out.
var bools = """a: True
b: FALSE
c: NULL
d: ~
e: yes
f: off
"""
var bools_exp = {"a": true, "b": false, "c": null, "d": null, "e": "yes", "f": "off"}


var numbers = """a: 1_000_000
b: 0x1F
c: .inf
d: -.inf
e: 42
f: 3.14
"""
var numbers_exp = {"a": 1000000, "b": 31, "c": INF, "d": -INF, "e": 42, "f": 3.14}


# Underscore stripping must not turn ordinary words into numbers.
var not_numbers = """a: snake_case
b: 1_000_widgets
c: _
"""
var not_numbers_exp = {"a": "snake_case", "b": "1_000_widgets", "c": "_"}


# "|2" fixes the content column relative to the parent, so the extra indent on the
# second line is content, not structure. Used to parse as the literal string "|2".
var block_indent_indicator = """key: |2
  line one
    indented two
"""
var block_indent_indicator_exp = {"key": "line one\n  indented two\n"}


# Clip chomping used to append "\\n" unconditionally, so an empty block became "\\n".
var empty_block_scalar = """a: |
b: 2
"""
var empty_block_scalar_exp = {"a": "", "b": 2}


# Strings that LOOK like the scalar forms the parser now types. These only survive
# because dump() quotes anything that would not read back as the same string; the
# reparse half of _check is what actually pins this.
var lookalike_strings = """a: "0x1F"
b: "1_000"
c: ".inf"
d: "True"
e: "42"
"""
var lookalike_strings_exp = {"a": "0x1F", "b": "1_000", "c": ".inf", "d": "True", "e": "42"}
