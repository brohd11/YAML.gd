## Modified Fork
This fork is modified with a different parsing function and dump to string function.

Changes sent upstream if accepted.

Supported beyond the original:
 - **Multiline JSON flow.** `[` / `{` may stay open across lines, with comments and blank lines
   inside, and the closing bracket may sit at any indent (including column 0).
 - **Document markers.** `---` and `...`, with `parse_all()` for multi-document files.
 - **Plain scalars.** A value may run on across more-indented lines, and a block (or a whole
   document) may be a bare scalar. Each line break folds to a single space.
 - **Scalar types.** Any case of `true`/`false`/`null`, plus `.inf`, `.nan`, hex (`0x1F`) and
   digit grouping (`1_000`). `yes`/`no`/`on`/`off` stay strings, per the YAML 1.2 core schema.
 - **Block scalar indentation indicators**, e.g. `|2`.
 - **A static API**, including file helpers. Nothing needs to be instantiated.

`dump()` quotes any string that would not read back as that same string, so `parse(dump(x)) == x`.

Known Limitations:
 - No anchors, aliases or merge keys (`&a`, `*a`, `<<:`); they pass through as literal strings.
 - An unterminated flow collection consumes the rest of its document and is then closed
   implicitly, with a warning. It cannot be bounded by indentation, because a legal closing
   bracket may be less indented than the key that opened it.
 - Tabs used for indentation are reported with a warning, not corrected. YAML forbids them.
 - A blank line inside a multiline quoted scalar folds to a single space rather than a newline.
 - A trailing comma in a flow collection yields a trailing null element (`[1, 2, ]` -> `[1, 2, null]`),
   matching the strictness of the YAML and JSON specs, which both reject it outright.
 - A flow mapping's keys are typed, so `{1: a}` has an **int** key, but `dump` writes `1: a`, which
   reads back as the **string** `"1"`. Non-string keys in flow mappings do not round-trip.

Original README
---

![logo](logo.jpg)

# YAML.gd 1.0.0 ![Godot v4.x](https://img.shields.io/badge/Godot-v4.x-%23478cbf) ![Godot v3.x](https://img.shields.io/badge/Godot-v3.x-%23478cbf)

A YAML parser written entirely in GDScript.  
`YAML.gd` allows you to parse YAML content directly within your projects without requiring C++ modules or compilation, making it easy to integrate and use on any platform supported by Godot.

[!["Buy Me A Coffee"](coffee.png)](https://ko-fi.com/lowlevel1989)

## Features

- 100% implemented in GDScript.
- No compilation needed – just drop it into your project.
- Supports:
  - Simple and nested dictionaries.
  - Lists and mixed structures (lists within dictionaries and vice versa).
  - Empty/null values.
  - Multiline blocks (`|`, `>`).
  - Chomping modifiers (`|-`, `|+`) and newline handling.
  - Quoted strings (single and double quotes).
  - Inline comments and blank lines.
  - Automatic type casting (`true`, `false`, numbers, `null`).
- Fully tested with a comprehensive test suite.

## ⚠️ Important Warning

Do **not** edit `.yaml` files directly from the Godot editor.  
The editor may automatically convert spaces to tabs, which **breaks YAML syntax** (YAML requires indentation using **spaces only**).

Use an external editor with proper configuration such as:

- **Vim**
- **VSCode**
- **Sublime Text**
- **Notepad++**

Make sure "tabs to spaces" is enabled.

## Basic usage:

```gdscript
var result = YAMLParser.parse_file("res://assets/yaml_dot_gd/tests/yamls/basic/test_01.yaml")
if typeof(result) == TYPE_DICTIONARY and result.has("name"):
    print(result["name"])
```

The whole API is static -- there is nothing to instantiate:

```gdscript
YAMLParser.parse(text)            # first (or only) document
YAMLParser.parse_all(text)        # every `---` separated document, as an Array
YAMLParser.parse_file(path)       # null + push_error if the file cannot be read
YAMLParser.parse_all_file(path)
YAMLParser.dump(data)             # -> String
YAMLParser.save_file(path, data)  # dump and write; false + push_error on failure
```

## Test Results

```text
=== Running Basic Tests ===
✔️ Test 1: Simple key-value pairs
✔️ Test 2: Nested dictionaries
✔️ Test 3: Simple lists
✔️ Test 4: Mixed structures
✔️ Test 5: Empty values
➡️ Basic Tests: 5/5 passed

=== Running Multiline Tests ===
✔️ Test 1: Literal block
✔️ Test 2: Folded block
✔️ Test 3: Strip chomping
✔️ Test 4: Keep chomping
✔️ Test 5: Quoted string
➡️ Multiline Tests: 5/5 passed

=== Running Advanced Tests ===
✔️ Test 1: Complex nested structure
✔️ Test 2: Multiple levels of nesting
✔️ Test 3: Mixed list types
✔️ Test 4: Comments and empty lines
✔️ Test 5: Miscellaneous edge cases
➡️ Advanced Tests: 5/5 passed

✅ **ALL TESTS PASSED**


