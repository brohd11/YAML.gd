extends YAMLTest

func run() -> bool:
	if not _check("a:\n  b:\n    c: 1\n", {"a":{"b":{"c":1}}}):
		_log(str("Regression: FAIL - ", "a:\n  b:\n    c: 1\n"))
	if not _check("a: [[1,2],[3,4]]\n", {"a":[[1,2],[3,4]]}):
		_log(str("Regression: FAIL - ", "a: [[1,2],[3,4]]\n"))
	if not _check("a: |-\n  l1\n  l2\nb: 2\n", {"a":"l1\nl2","b":2}):
		_log(str("Regression: FAIL - ", "a: |-\n  l1\n  l2\nb: 2\n"))
	if not _check("a: >\n  one\n  two\nb: 2\n", {"a":"one two\n","b":2}):
		_log(str("Regression: FAIL - ", "a: >\n  one\n  two\nb: 2\n"))
	if not _check("a: 1 # hi\nb: 2\n", {"a":1,"b":2}):
		_log(str("Regression: FAIL - ", "a: 1 # hi\nb: 2\n"))
	if not _check("a: \"x: y\"\n", {"a":"x: y"}):
		_log(str("Regression: FAIL - ", "a: \"x: y\"\n"))
	return passed()
