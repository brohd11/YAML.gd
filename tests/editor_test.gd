@tool
extends EditorScript

const TestRun = preload("res://tests/test_run.gd")

func _run() -> void:
	print("\n".join(TestRun.run_tests()["output"]))
