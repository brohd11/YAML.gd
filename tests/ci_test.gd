extends SceneTree

var all_tests = load("res://tests/all_tests.gd")

func _init() -> void:
	var all_passed = all_tests.run()
	var exit = 0 if all_passed else 1
	quit(exit)
