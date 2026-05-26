@tool
extends EditorScript

var all_tests = load("res://tests/all_tests.gd")

func _run() -> void:
	all_tests.run()
