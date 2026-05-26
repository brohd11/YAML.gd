extends YAMLTest


func run() -> bool:
	_check(yaml, expected)
	return passed()

var yaml = """description: LAMP_DESC
article: LAMP_ART
maxhp: 30
skills:
- skill: tackle
  weight: 1000
- skill: float
  weight: 1
boss: false
music: ''
"""

var expected = {
	"description":"LAMP_DESC",
	"article":"LAMP_ART",
	"maxhp":30,
	"skills":[{
		"skill":"tackle",
		"weight":1000
		},
		{
		"skill":"float",
		"weight":1
		}],
	"boss":false,
	"music":""
	}
