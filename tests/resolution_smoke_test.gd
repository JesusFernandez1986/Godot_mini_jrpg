extends SceneTree

const OUTPUT_DIR := "/tmp/cronicas_resolution_smoke"
const MAIN_SCENE: PackedScene = preload("res://Main.tscn")

func _initialize() -> void:
	call_deferred("run_smoke_test")

func run_smoke_test() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	root.content_scale_size = Vector2i(960, 540)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var game := MAIN_SCENE.instantiate()
	game.save_base_dir = "user://tests/resolution_smoke"
	root.add_child(game)
	await process_frame
	var failures: Array[String] = []
	for resolution in PerformanceBudgetSystem.SUPPORTED_RESOLUTIONS:
		root.size = resolution
		await create_timer(0.2).timeout
		game.queue_redraw()
		await process_frame
		var image := root.get_texture().get_image()
		var path := OUTPUT_DIR.path_join("title_%dx%d.png" % [resolution.x, resolution.y])
		if image.is_empty() or image.get_width() <= 0 or image.get_height() <= 0:
			failures.append("No se renderizó %s." % resolution)
		else:
			image.save_png(path)
		if root.content_scale_size != Vector2i(960, 540) or root.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
			failures.append("El escalado cambió al probar %s." % resolution)
	print("RESOLUTION_SMOKE screenshots=%d failures=%d output=%s" % [PerformanceBudgetSystem.SUPPORTED_RESOLUTIONS.size(), failures.size(), OUTPUT_DIR])
	for failure in failures:
		push_error(failure)
	game.queue_free()
	quit(1 if not failures.is_empty() else 0)
