
static func run() -> bool:
	var basic = load("res://tests/scripts/test_basic.gd")
	var advanced = load("res://tests/scripts/test_advanced.gd")
	var multiline = load("res://tests/scripts/test_multiline.gd")

	var dump = load("res://tests/dump/dump_test.gd")
	
	
	var scripts = [
		basic,
		advanced,
		multiline,
		dump,
		]
	print("YAML.gd Tests")
	var all_passed = true
	for script in scripts:
		print("")
		print(" --- Running Test: %s ---" % script.resource_path.get_file())
		var result = script.run()
		if not result:
			all_passed = false
	
	print("")
	print("--- Autorun tests ---")
	var autorun_tests = _get_files_in_dir("res://tests/autorun/")
	for path in autorun_tests:
		var script = load(path)
		var base_script = script.get_base_script()
		if not is_instance_valid(base_script) or base_script != YAMLTest:
			print("Not a YAMLTest: ", path)
			continue
		var test = script.new()
		var name = test.get_test_name()
		print("")
		print("Run: %s" % name)
		var result = test.run()
		if result:
			print("✅ PASSED")
			#print("Test: %s - PASSED" % name)
		else:
			all_passed = false
			print("❌ FAILED")
			#print("Test: %s - FAILED" % name)
	
	
	print("")
	if all_passed:
		print("✅ ALL TESTS PASSED")
	else:
		print("❌ SOME TESTS FAILED")
	
	return all_passed


static func _get_files_in_dir(dir:String):
	var files = []
	var dir_access = DirAccess.open(dir)
	for f in dir_access.get_files():
		var path = dir.path_join(f)
		if f.get_extension() == "gd":
			files.append(path)
	
	for d in dir_access.get_directories():
		var path = dir.path_join(d)
		files.append_array(_get_files_in_dir(path))
	
	return files
