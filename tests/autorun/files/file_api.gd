extends YAMLTest

# parse_file / parse_all_file / save_file. The whole API is static -- nothing here
# constructs a YAMLParser.

const DIR = "res://.godot/yaml_file_api_test"

func run() -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path = DIR.path_join("round_trip.yaml")

	var data = {
		"name": "test",
		"count": 3,
		"nested": {"a": [1, 2], "b": null},
		"items": [{"id": 1}, {"id": 2}],
	}

	_expect("save_file", YAMLParser.save_file(path, data), true)
	_expect("parse_file", YAMLParser.parse_file(path), data)

	# A file written with a document marker still reads back as one document.
	var multi = DIR.path_join("multi.yaml")
	var f = FileAccess.open(multi, FileAccess.WRITE)
	f.store_string("---\na: 1\n---\nb: 2\n")
	f.close()
	_expect("parse_file first doc", YAMLParser.parse_file(multi), {"a": 1})
	_expect("parse_all_file", YAMLParser.parse_all_file(multi), [{"a": 1}, {"b": 2}])

	# An unreadable path is reported, not fatal. Both push_error; the errors below
	# are expected and do not fail the run.
	_expect("parse_file missing", YAMLParser.parse_file(DIR.path_join("nope.yaml")), null)
	_expect("parse_all_file missing", YAMLParser.parse_all_file(DIR.path_join("nope.yaml")), [])
	_expect("save_file bad dir", YAMLParser.save_file("res://no/such/dir/x.yaml", data), false)

	return passed()


func _expect(what: String, got, expected) -> void:
	if got == expected:
		if pass_state == -1:
			pass_state = 0
		return
	pass_state = 1
	print("   %s" % what)
	print("   got: ", got)
	print("   exp: ", expected)
