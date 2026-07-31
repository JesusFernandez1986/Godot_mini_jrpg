class_name TestSuite
extends RefCounted

var passed := 0
var failed := 0
var failures: Array[String] = []
var current_section := ""

func section(name: String) -> void:
	current_section = name
	print("\n[TEST SECTION] ", name)

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  PASS  ", message)
	else:
		failed += 1
		var rendered := "%s: %s" % [current_section, message]
		failures.append(rendered)
		print("  FAIL  ", message)

func equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (esperado=%s, real=%s)" % [message, str(expected), str(actual)])

func greater_or_equal(actual: float, expected: float, message: String) -> void:
	check(actual >= expected, "%s (mínimo=%s, real=%s)" % [message, expected, actual])

func summary() -> String:
	return "TEST_SUMMARY passed=%d failed=%d" % [passed, failed]
