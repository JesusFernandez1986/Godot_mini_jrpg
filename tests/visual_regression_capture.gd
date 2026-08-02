extends SceneTree

const OUTPUT_DIR := "/tmp/cronicas_visual_review"
const MAIN_SCENE: PackedScene = preload("res://Main.tscn")

class AnimationBoard extends Node2D:
	var elapsed := 0.0
	var direction_mode := false

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(960, 1920 if not direction_mode else 980)), Color("20252d"), true)
		if direction_mode:
			draw_directions()
		else:
			draw_states()

	func draw_states() -> void:
		for row in CharacterAnimationSystem.STATES.size():
			var state: String = CharacterAnimationSystem.STATES[row]
			draw_string(ThemeDB.fallback_font, Vector2(8, 28 + row * 116), state, HORIZONTAL_ALIGNMENT_LEFT, 92, 13, Color.WHITE)
			for character_index in 8:
				var x := 112.0 + character_index * 104.0
				var y := 108.0 + row * 116.0
				draw_rect(Rect2(x - 45, y - 100, 90, 105), Color("11151b"), true)
				GameUI.animated_party_character(self, preload("res://assets/party_animation_atlas_v2.png"), character_index, Vector2(x, y), Vector2(72, 102), state, "south", elapsed, _tint(character_index))
				if row == 0: draw_string(ThemeDB.fallback_font, Vector2(x - 18, 18), str(character_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 36, 12, Color("ffe39a"))

	func draw_directions() -> void:
		for row in CharacterAnimationSystem.DIRECTIONS.size():
			var direction: String = CharacterAnimationSystem.DIRECTIONS[row]
			draw_string(ThemeDB.fallback_font, Vector2(8, 35 + row * 116), direction, HORIZONTAL_ALIGNMENT_LEFT, 92, 12, Color.WHITE)
			for character_index in 8:
				var x := 112.0 + character_index * 104.0
				var y := 108.0 + row * 116.0
				draw_rect(Rect2(x - 45, y - 100, 90, 105), Color("11151b"), true)
				GameUI.animated_party_character(self, preload("res://assets/party_animation_atlas_v2.png"), character_index, Vector2(x, y), Vector2(72, 102), "walk", direction, elapsed, _tint(character_index))

	func _tint(character_index: int) -> Color:
		var tints := [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color("65cfc4"), Color("b67586"), Color("d6b7ef"), Color("d3a35f")]
		return tints[character_index]

func _initialize() -> void:
	call_deferred("capture_all")

func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	for sample in [["states_00", 0.0], ["states_18", 0.18], ["states_36", 0.36]]:
		await capture_board(str(sample[0]), float(sample[1]), false)
	await capture_board("directions", 0.18, true)
	await capture_game_screens()
	print("VISUAL_CAPTURE_COMPLETE ", OUTPUT_DIR)
	quit()

func capture_board(file_name: String, elapsed: float, directions: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 980 if directions else 1920)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var board := AnimationBoard.new()
	board.elapsed = elapsed
	board.direction_mode = directions
	viewport.add_child(board)
	root.add_child(viewport)
	await process_frame
	await process_frame
	viewport.get_texture().get_image().save_png(OUTPUT_DIR.path_join(file_name + ".png"))
	viewport.queue_free()
	await process_frame

func capture_game_screens() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 540)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var game := MAIN_SCENE.instantiate()
	game.save_base_dir = "user://tests/visual_capture"
	viewport.add_child(game)
	root.add_child(viewport)
	await process_frame
	await save_game_screen(viewport, game, "screen_title")
	game.start_vertical_slice_demo()
	await save_game_screen(viewport, game, "screen_vertical_demo")
	game.new_game()
	game.game_state = "world_map"
	game.chapter = 5
	game.unlocked_locations = ["valdoria", "brumaforja", "celestia", "sylvaran", "sanctuary"]
	await save_game_screen(viewport, game, "screen_world")
	game.current_city = "celestia"
	game.game_state = "city"
	await save_game_screen(viewport, game, "screen_city")
	for dungeon_id in DungeonExplorationSystem.DUNGEON_IDS:
		DungeonExplorationSystem.enter(game.dungeon_exploration_state, dungeon_id)
		game.current_dungeon = dungeon_id
		game.game_state = "dungeon_crawl"
		await save_game_screen(viewport, game, "screen_dungeon_" + dungeon_id)
	await save_game_screen(viewport, game, "screen_dungeon")
	game.start_world_encounter({"id":"visual", "enemy":"hollow_sentinel"}, "world")
	game.action_animation = "special"
	game.action_time = 0.28
	game.action_duration = 0.9
	game.enemy_animation = "hurt"
	game.start_battle_impact(84, "lightning", true)
	await save_game_screen(viewport, game, "screen_battle")
	game.party_battle = {}
	game.open_game_menu("world_map")
	game.menu_tab = 5
	await save_game_screen(viewport, game, "screen_menu")
	game.start_directed_scene("council_of_memory", "world_map", "visual", "celestia")
	for guard in 12:
		if not game.narrative_system.current_choices(game.narrative_state).is_empty(): break
		game.dialogue_system.reveal_line()
		game.advance_directed_scene()
	game.dialogue_system.reveal_line()
	await save_game_screen(viewport, game, "screen_dialogue")
	game.game_state = "victory"
	await save_game_screen(viewport, game, "screen_victory")
	viewport.queue_free()
	await process_frame

func save_game_screen(viewport: SubViewport, game: Node, file_name: String) -> void:
	game.queue_redraw()
	await create_timer(0.4).timeout
	game.queue_redraw()
	await process_frame
	viewport.get_texture().get_image().save_png(OUTPUT_DIR.path_join(file_name + ".png"))
