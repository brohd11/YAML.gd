@tool
extends EditorScript

func _run() -> void:
	var all_passed = run()
	print("")
	if all_passed:
		print("✅ ALL TESTS PASSED")
	else:
		print("❌ SOME TESTS FAILED")

static func run():
	var all_passed = true
	var files_passed = test_files()
	if !files_passed:
		all_passed = false
	
	return all_passed


static func test_files():
	var files = [
		"res://addons/yaml_dot_gd/tests/yamls/advanced/test_01.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/advanced/test_02.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/advanced/test_03.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/advanced/test_04.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/advanced/test_05.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/advanced/test_06.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/basic/test_01.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/basic/test_02.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/basic/test_03.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/basic/test_04.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/basic/test_05.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/multiline/test_01.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/multiline/test_02.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/multiline/test_03.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/multiline/test_04.yaml",
		"res://addons/yaml_dot_gd/tests/yamls/multiline/test_05.yaml",
	]
	var all_passed = true
	for f in files:
		var passed = _test_dump_and_read(f)
		if !passed:
			all_passed = false
	
	return all_passed

static func _test_dump_and_read(file_path:String, save_to_file:bool=false):
	if not FileAccess.file_exists(file_path):
		print("Fail - File not present: ", file_path)
		return false
	var text = FileAccess.get_file_as_string(file_path)
	var parser = YAMLParser.new()
	var file_data = parser.parse(text)
	
	var dumped = YAMLParser.dump(file_data)
	var reparsed_data = parser.parse(dumped)
	
	var passed = file_data == reparsed_data
	if passed:
		print("PASSED: ", file_path)
	else:
		print("FAIL: ", file_path)
		print("")
		print("--- Expected ---")
		print(file_data)
		print("")
		print("--- Parsed ---")
		print(reparsed_data)
		
		print("")
		print("--- Dumped ---")
		print(dumped)
	
	if !save_to_file:
		return passed
	
	var new_path = "res://.godot".path_join(file_path.get_base_dir().get_file()).path_join(file_path.get_file())
	DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
	var f = FileAccess.open(new_path, FileAccess.WRITE)
	f.store_string(dumped)
	
	return passed
