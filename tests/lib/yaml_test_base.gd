class_name YAMLTest

## -1 = No run yet, 0 = pass, 1 = fail
var pass_state:= -1
## Report lines collected during the run. The runner folds these into its result.
var output: Array[String] = []

func get_test_name():
	return get_script().resource_path.get_file()


func run() -> bool:
	return passed()

func passed():
	return pass_state == 0

func _log(text: String) -> void:
	output.append(text)

func _check(yaml: String, expected) -> bool:
	var got = YAMLParser.parse(yaml)
	#var ok = _eq(got, expected)
	var ok = got == expected
	if ok:
		if pass_state == -1:
			pass_state = 0
	else:
		pass_state = 1
		_log(str("   got: ", got))
		_log(str("   exp: ", expected))

	var dump = YAMLParser.dump(got)
	var reparse = YAMLParser.parse(dump)
	var reparse_ok = reparse == expected
	if not reparse_ok:
		pass_state = 1
		_log(str("   reparse got: ", got))
		_log(str("   exp: ", expected))
	
	return passed()
