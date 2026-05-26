extends YAMLTest

# Issue #4 nested lists via double hyphen

func run():
	_check(yaml, expected)
	return passed()


var yaml = """animations:
  Idle:
    directions:
      - - 0
        - - 1
          - 0.1
    type: 1
offset:
  - 0
  - 0
type: 0
"""
var expected = {
	"animations":{
		"Idle":{
			"directions":[[0, [1, 0.1]]],
			"type":1
			}
		},
		"offset":[0,0],
		"type":0
		}
