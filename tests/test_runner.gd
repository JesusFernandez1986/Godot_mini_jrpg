extends SceneTree

func _initialize() -> void:
	call_deferred("run_all")

func run_all() -> void:
	cleanup_orphan_test_data()
	var suite := TestSuite.new()
	UnitTests.run(suite)
	await IntegrationTests.run(suite, self)
	print("\n", suite.summary())
	if not suite.failures.is_empty():
		print("\nFAILED TESTS:")
		for failure in suite.failures:
			print(" - ", failure)
	quit(1 if suite.failed > 0 else 0)

func cleanup_orphan_test_data() -> void:
	var test_root := "user://tests"
	var root_directory := DirAccess.open(test_root)
	if root_directory == null:
		return
	for directory_name in root_directory.get_directories():
		var child_path := test_root.path_join(directory_name)
		var child_directory := DirAccess.open(child_path)
		if child_directory != null:
			for file_name in child_directory.get_files():
				DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path.path_join(file_name)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path))
