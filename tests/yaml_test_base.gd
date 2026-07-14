class_name YAMLTest

## -1 = No run yet, 0 = pass, 1 = fail
var pass_state:= -1

func get_test_name():
	return get_script().resource_path.get_file()


func run() -> bool:
	return passed()

func passed():
	return pass_state == 0

func _check(yaml: String, expected) -> bool:
	var got = YAMLParser.parse(yaml)
	#var ok = _eq(got, expected)
	var ok = got == expected
	if ok:
		if pass_state == -1:
			pass_state = 0
	else:
		pass_state = 1
		print("   got: ", got)
		print("   exp: ", expected)
	
	var dump = YAMLParser.dump(got)
	var reparse = YAMLParser.parse(dump)
	var reparse_ok = reparse == expected
	if not reparse_ok:
		pass_state = 1
		print("   reparse got: ", got)
		print("   exp: ", expected)
	
	return passed()
