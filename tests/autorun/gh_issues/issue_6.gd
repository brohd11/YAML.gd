extends YAMLTest

func run() -> bool:
	_check(yaml, expected)
	_check(yaml2, expected2)
	return passed()

# Issue #6 no blank line between block scalar and sibling key
var yaml = """key2:
  subkey1:
    subsubkey1:
      - ss1key1: ssval1
        ss1key2: |
          multiline
          text
    subsubkey2:
      - ss2key1: ss2val1
        ss2key2: ss2val2
"""
var expected = {
	"key2":{
		"subkey1":{
			"subsubkey1":[{
				"ss1key1":"ssval1",
				"ss1key2":"multiline\ntext\n"
				}],
			"subsubkey2":[{
				"ss2key1":"ss2val1",
				"ss2key2":"ss2val2"
				}]
			}
		}
	}


#Issue #6 block scalar as FIRST key of a list item

var yaml2 = """subsubkey1:
  - ss1key2: |
      multiline
      text
    ss1key1: ssval1
"""
var expected2 = {
	"subsubkey1":[{
		"ss1key2":"multiline\ntext\n",
		"ss1key1":"ssval1"
		}]
	}
