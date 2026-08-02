extends Node2D

const WORLD := Rect2(0, 0, 960, 540)
const HERO_SPEED := 215.0
const PARTY_SHEET: Texture2D = preload("res://assets/party_characters.png")
const PARTY_ANIMATION_ATLAS: Texture2D = preload("res://assets/party_animation_atlas_v2.png")
const PHASE10_PARTY: Texture2D = preload("res://assets/phase10_party.png")
const ELEMENTAL_VFX: Texture2D = preload("res://assets/vfx_elements_v2.png")
const ENEMY_SHEET: Texture2D = preload("res://assets/characters.png")
const PHASE3_ENEMY_SHEET: Texture2D = preload("res://assets/phase3_enemies.png")
const SANCTUARY: Texture2D = preload("res://assets/forest_sanctuary_hd2d.png")
const VALDORIA_CATACOMBS: Texture2D = preload("res://assets/valdoria_catacombs_hd2d.png")
const WORLD_MAP: Texture2D = preload("res://assets/world_map_eryndor.png")
const CITY_VALDORIA: Texture2D = preload("res://assets/city_valdoria.png")
const CITY_BRUMAFORJA: Texture2D = preload("res://assets/city_brumaforja.png")
const CITY_CELESTIA: Texture2D = preload("res://assets/city_celestia.png")
const CITY_SYLVARAN: Texture2D = preload("res://assets/city_sylvaran.png")

const TITLE_OPTIONS := ["DEMO VERTICAL", "NUEVA PARTIDA", "CARGAR PARTIDA", "AJUSTES", "SALIR"]
const LANDMARK_ACTIONS := ["EXPLORAR EL LUGAR", "ACAMPAR HASTA EL AMANECER", "REGRESAR AL MAPA MUNDIAL"]
const MENU_TABS := ["INVENTARIO", "EQUIPO", "PROGRESO", "GRUPO", "DIARIO", "EXTRAS", "SISTEMA"]
const SETTINGS_ROWS := ["master_volume", "music_volume", "sfx_volume", "text_speed_index", "resolution_index", "window_mode", "control_scheme", "reset", "back"]
const SETTINGS_LABELS := ["Volumen maestro", "Volumen de música", "Volumen de efectos", "Velocidad del texto", "Resolución", "Modo de ventana", "Controles", "Restablecer valores", "Volver"]
const BATTLE_COMMANDS := ["ATACAR", "ARTE", "CURAR", "DEFENDER", "OBJETO", "CAMBIAR", "COMBO", "HUIR"]
const CHAPTER_TITLES := [
	"Prólogo · La noche sin nombre",
	"Capítulo I · La fuente del león",
	"Capítulo II · El corazón de la montaña",
	"Capítulo III · El mar que recuerda",
	"Capítulo IV · Los nombres del bosque",
	"Capítulo V · La Corona Hueca",
	"Epílogo · Un juramento compartido"
]

var scene_router := SceneRouter.new()
var game_state: String:
	get:
		return scene_router.current_state
	set(value):
		scene_router.change_state(value)
var settings_manager := SettingsManager.new()
var dialogue_system := DialogueSystem.new()
var narrative_system := NarrativeSystem.new()
var hero_story_system := HeroStorySystem.new()
var city_life_system := CityLifeSystem.new()
var camera_system := CameraSystem.new()
var sanctuary_controller: SanctuaryController
var locations: Array = []
var save_base_dir := SaveSystem.SAVE_DIR
var menu_return_state := "world_map"
var title_index := 0
var city_action_index := 0
var city_activity_active := false
var city_activity_choice := 0
var landmark_action_index := 0
var map_index := 0
var menu_tab := 0
var menu_index := 0
var equipment_member_index := 0
var advancement_member_index := 0
var workshop_recipe_index := 0
var dialogue_choice_index := 0
var settings_index := 0
var settings_return_state := "title"
var slot_index := 0
var slot_return_state := "title"
var pending_overwrite_slot := 0
var world_time := 0.0
var play_seconds := 0.0
var walk_time := 0.0
var is_moving := false
var is_running := false
var facing_direction := "south"
var opened_interactions: Dictionary = {"chest": false, "mechanism": false, "altar": false}
var phase3_state: Dictionary = QuestSystem.create_phase3_state()
var valdoria_position := Vector2(477, 438)
var dungeon_position := Vector2(112, 438)
var dungeon_defeated: Array = []
var battle_context := "guardian"
var current_encounter_id := ""
var pending_phase3_enemy_id := ""
var npc_animation_elapsed := 0.0
var notification := ""
var notification_time := 0.0

var action_animation := "idle"
var action_time := 0.0
var action_duration := 0.0
var pending_destination := ""
var enemy_animation := "idle"
var queued_enemy_turn := false
var queued_defeat := false
var pending_enemy_damage := 0
var battle_impact_time := 1.0
var battle_impact_duration := 0.55
var battle_impact_damage := 0
var battle_impact_element := "physical"
var battle_impact_weak := false
var battle_hit_stop := 0.0
var party_battle: Dictionary = {}
var battle_command_index := 0
var battle_target_index := 0
var resonance_tutorial_seen := false

var current_location := "valdoria"
var current_city := "valdoria"
var current_landmark := ""
var unlocked_locations: Array = []
var visited_cities: Dictionary = {}
var city_dialogue_progress: Dictionary = {}
var chapter := 0
var gold := 85

var party: Array = []
var inventory: Dictionary = {}
var equipment_state: Dictionary = EquipmentSystem.create_state()
var advancement_state: Dictionary = AdvancementSystem.create_state()
var narrative_state: Dictionary = {}
var world_exploration_state: Dictionary = WorldExplorationSystem.create_state()
var city_life_state: Dictionary = {}
var dungeon_exploration_state: Dictionary = DungeonExplorationSystem.create_state()
var hero_story_state: Dictionary = {}
var bestiary_state: Dictionary = BestiarySystem.create_state()
var commerce_state: Dictionary = CommerceSystem.create_state()
var faction_state: Dictionary = FactionSystem.create_state()
var endgame_state: Dictionary = EndgameSystem.create_state()
var completion_state: Dictionary = CompletionSystem.create_state()
var current_dungeon := ""
var phase9_secret_encounter := false
var active_directed_scene := ""
var directed_return_state := "world_map"
var directed_completion := ""
var directed_backdrop := "world"
var directed_scene_elapsed := 0.0
var directed_music_cue := ""
var narrative_music_player: AudioStreamPlayer
var narrative_music_playback: AudioStreamGeneratorPlayback
var narrative_music_phase := 0.0
var extras_bestiary_index := 0
var extras_market_index := 0
var pending_superboss_id := ""

var hero_position := Vector2(315, 400)
var guardians := [Vector2(485, 165), Vector2(735, 300), Vector2(510, 412)]
var defeated := [false, false, false]
var crystals := 0
var encounter_index := -1
var enemy_hp := 0
var enemy_max_hp := 0
var enemy_name := ""
var enemy_intent := ""
var enemy_data: Dictionary = {}
var rng := RandomNumberGenerator.new()

const DUNGEON_ENCOUNTERS := [
	{"id":"rat_1", "enemy":"crypt_rat", "position":Vector2(172,350)},
	{"id":"sentinel_1", "enemy":"hollow_sentinel", "position":Vector2(315,205)},
	{"id":"wisp_1", "enemy":"amber_wisp", "position":Vector2(420,300)},
	{"id":"spider_1", "enemy":"ossuary_spider", "position":Vector2(565,230)},
	{"id":"cultist_1", "enemy":"veil_cultist", "position":Vector2(650,370)},
	{"id":"gargoyle_1", "enemy":"stone_gargoyle", "position":Vector2(820,400)},
	{"id":"miniboss", "enemy":"oathbreaker_knight", "position":Vector2(510,310)},
	{"id":"boss", "enemy":"hollow_lion", "position":Vector2(820,210)}
]

func _ready() -> void:
	configure_viewport_scaling()
	rng.randomize()
	sanctuary_controller = SanctuaryController.new()
	sanctuary_controller.name = "SanctuaryController"
	add_child(sanctuary_controller)
	sanctuary_controller.interaction_requested.connect(handle_world_interaction)
	sanctuary_controller.set_player_position(hero_position)
	camera_system.snap(hero_position)
	locations = WorldExplorationSystem.all_locations(GameDatabase.locations())
	settings_manager.load_settings()
	setup_narrative_music()
	initialize_empty_game()
	var database_errors := GameDatabase.validate()
	database_errors.append_array(DungeonExplorationSystem.validate_definitions())
	database_errors.append_array(hero_story_system.validate_data())
	database_errors.append_array(BestiarySystem.validate_definitions())
	database_errors.append_array(FactionSystem.validate_definitions())
	database_errors.append_array(EndgameSystem.validate_definitions())
	database_errors.append_array(CompletionSystem.validate_definitions())
	if not database_errors.is_empty():
		GameLogger.error("database", "Game database validation failed", {"errors": database_errors})
	GameLogger.info("startup", "Game initialized", {"dialogues": StoryData.dialogue_count() + hero_story_system.dialogue_count(), "locations": locations.size(), "heroes":party.size(), "dungeons":DungeonExplorationSystem.DUNGEONS.size()})
	queue_redraw()

func configure_viewport_scaling() -> void:
	var root_window := get_window()
	root_window.content_scale_size = Vector2i(int(WORLD.size.x), int(WORLD.size.y))
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

func setup_narrative_music() -> void:
	if DisplayServer.get_name() == "headless": return
	narrative_music_player = AudioStreamPlayer.new()
	narrative_music_player.name = "NarrativeMusic"
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.35
	narrative_music_player.stream = generator
	narrative_music_player.volume_db = -22.0
	add_child(narrative_music_player)
	narrative_music_player.play()
	narrative_music_playback = narrative_music_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _exit_tree() -> void:
	narrative_music_playback = null
	if narrative_music_player != null:
		narrative_music_player.stop()
		narrative_music_player.stream = null

func update_narrative_music() -> void:
	if narrative_music_playback == null: return
	var city_cue := str(city_life_system.city(current_city).get("music", "")) if game_state == "city" else ""
	var active_cue := directed_music_cue if not directed_music_cue.is_empty() else city_cue
	var frequency := {"council":146.83, "forge_bell":110.0, "himno_del_leon":164.81, "martillos_de_ceniza":110.0, "mareas_de_cristal":196.0, "nombres_bajo_las_hojas":130.81}.get(active_cue, 130.81) as float
	var audible := (not active_directed_scene.is_empty() and not directed_music_cue.is_empty()) or (game_state == "city" and not city_cue.is_empty())
	var frames := mini(narrative_music_playback.get_frames_available(), 1024)
	for frame_index in frames:
		var sample := 0.0
		if audible:
			sample = (sin(narrative_music_phase) + sin(narrative_music_phase * 1.5) * 0.32) * 0.055
		narrative_music_playback.push_frame(Vector2(sample, sample))
		narrative_music_phase = fmod(narrative_music_phase + TAU * frequency / 22050.0, TAU)

func initialize_empty_game() -> void:
	party = GameDatabase.create_party()
	inventory = GameDatabase.create_initial_inventory()
	equipment_state = EquipmentSystem.create_state()
	advancement_state = AdvancementSystem.create_state()
	narrative_state = narrative_system.create_state()
	hero_story_state = hero_story_system.create_state()
	world_exploration_state = WorldExplorationSystem.create_state()
	city_life_state = city_life_system.create_state()
	dungeon_exploration_state = DungeonExplorationSystem.create_state()
	bestiary_state = BestiarySystem.create_state()
	commerce_state = CommerceSystem.create_state()
	faction_state = FactionSystem.create_state()
	endgame_state = EndgameSystem.create_state()
	completion_state = CompletionSystem.create_state()
	current_dungeon = ""
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)

func new_game() -> void:
	initialize_empty_game()
	current_location = "valdoria"
	current_city = "valdoria"
	current_landmark = ""
	unlocked_locations = []
	visited_cities = {}
	city_dialogue_progress = {"valdoria": 0, "brumaforja": 0, "celestia": 0, "sylvaran": 0}
	chapter = 0
	gold = 85
	play_seconds = 0.0
	hero_position = Vector2(315, 400)
	defeated = [false, false, false]
	crystals = 0
	facing_direction = "south"
	opened_interactions = {"chest": false, "mechanism": false, "altar": false}
	phase3_state = QuestSystem.create_phase3_state()
	valdoria_position = Vector2(477, 438)
	dungeon_position = Vector2(112, 438)
	dungeon_defeated = []
	battle_context = "guardian"
	current_encounter_id = ""
	party_battle = {}
	battle_command_index = 0
	battle_target_index = 0
	resonance_tutorial_seen = false
	active_directed_scene = ""
	world_exploration_state = WorldExplorationSystem.create_state()
	city_life_state = city_life_system.create_state()
	dungeon_exploration_state = DungeonExplorationSystem.create_state()
	hero_story_state = hero_story_system.create_state()
	bestiary_state = BestiarySystem.create_state()
	commerce_state = CommerceSystem.create_state()
	faction_state = FactionSystem.create_state()
	endgame_state = EndgameSystem.create_state()
	completion_state = CompletionSystem.create_state()
	current_dungeon = ""
	phase9_secret_encounter = false
	city_activity_active = false
	city_activity_choice = 0
	landmark_action_index = 0
	dialogue_choice_index = 0
	if sanctuary_controller != null:
		sanctuary_controller.set_player_position(hero_position)
		sanctuary_controller.facing_direction = facing_direction
	camera_system.snap(hero_position)
	start_dialogue(StoryData.get_story_lines(0), "world_map", "intro", "sanctuary")

func _process(delta: float) -> void:
	var reduced_motion := bool((completion_state.get("accessibility", {}) as Dictionary).get("reduced_motion", false))
	battle_hit_stop = maxf(0.0, battle_hit_stop - delta)
	if battle_impact_time < battle_impact_duration:
		battle_impact_time = minf(battle_impact_duration, battle_impact_time + delta)
	if not reduced_motion: world_time += delta
	scene_router.update(delta)
	if sanctuary_controller != null:
		sanctuary_controller.set_active(game_state in ["explore", "valdoria_explore", "dungeon"] and action_duration <= 0.0)
		sanctuary_controller.update_animation(delta)
	if not reduced_motion: npc_animation_elapsed += delta
	if not active_directed_scene.is_empty(): directed_scene_elapsed += delta
	update_narrative_music()
	if game_state == "dialogue":
		dialogue_system.update(delta, settings_manager.text_characters_per_second())
	if game_state != "title":
		play_seconds += delta
	if game_state == "world_map" and action_duration <= 0.0:
		process_world_map_movement(delta)
	if notification_time > 0.0:
		notification_time = maxf(0.0, notification_time - delta)
	if action_duration > 0.0:
		if battle_hit_stop <= 0.0:
			action_time += delta
		if action_time >= action_duration:
			var completed_animation := action_animation
			action_animation = "idle"
			action_time = 0.0
			action_duration = 0.0
			enemy_animation = "idle"
			if completed_animation == "travel" and not pending_destination.is_empty():
				arrive_at_destination(pending_destination)
			elif game_state == "battle":
				if queued_defeat:
					queued_defeat = false
					defeat_enemy()
				elif completed_animation in ["attack", "special", "heal"] and queued_enemy_turn:
					queued_enemy_turn = false
					begin_enemy_attack()
				elif completed_animation == "hurt" and pending_enemy_damage > 0:
					resolve_enemy_attack()
	if game_state in ["explore", "valdoria_explore", "dungeon"]:
		process_world_movement(delta)
		camera_system.update(delta, hero_position, is_running, not sanctuary_controller.nearest_interaction().is_empty())
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match game_state:
		"title":
			handle_title_input(event)
		"settings":
			handle_settings_input(event)
		"save_menu":
			handle_slot_menu_input(event, true)
		"load_menu":
			handle_slot_menu_input(event, false)
		"dialogue":
			handle_dialogue_input(event)
		"world_map":
			handle_world_map_input(event)
		"city":
			handle_city_input(event)
		"landmark":
			handle_landmark_input(event)
		"dungeon_crawl":
			handle_dungeon_crawl_input(event)
		"explore", "valdoria_explore", "dungeon":
			if event.is_action_pressed("interact"):
				sanctuary_controller.request_interaction()
			elif is_menu_event(event):
				open_game_menu(game_state)
		"battle":
			handle_battle_input(event)
		"game_menu":
			handle_game_menu_input(event)
		"victory":
			if event.is_action_pressed("ui_accept"):
				game_state = "title"
				title_index = 0
	queue_redraw()

func is_menu_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.keycode == KEY_M or key_event.keycode == KEY_TAB
	return false

func handle_title_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_V:
		start_vertical_slice_demo()
	elif event.is_action_pressed("ui_up"):
		title_index = wrapi(title_index - 1, 0, TITLE_OPTIONS.size())
	elif event.is_action_pressed("ui_down"):
		title_index = wrapi(title_index + 1, 0, TITLE_OPTIONS.size())
	elif event.is_action_pressed("ui_accept"):
		match title_index:
			0:
				start_vertical_slice_demo()
			1:
				new_game()
			2:
				open_load_menu("title")
			3:
				open_settings("title")
			4:
				get_tree().quit()

func start_vertical_slice_demo() -> void:
	new_game()
	(narrative_state["variables"] as Dictionary)["vertical_slice_active"] = true
	(narrative_state["variables"] as Dictionary)["vertical_slice_complete"] = false
	chapter = 5
	unlocked_locations = ["valdoria"]
	for index in mini(4, party.size()):
		(party[index] as Dictionary)["joined"] = true
		(party[index] as Dictionary)["active"] = true
	current_city = "valdoria"
	current_location = "valdoria"
	current_landmark = ""
	if sanctuary_controller != null:
		sanctuary_controller.configure_world("valdoria")
		sanctuary_controller.set_player_position(valdoria_position)
		sanctuary_controller.facing_direction = facing_direction
	hero_position = valdoria_position
	camera_system.snap(hero_position)
	start_dialogue(Phase3StoryData.VERTICAL_SLICE_INTRO, "valdoria_explore", "vertical_slice_intro", "valdoria")
	show_notification("DEMO VERTICAL · Un juramento, una ciudad y las Ruinas de Eira.")

func is_vertical_slice_active() -> bool:
	return bool((narrative_state.get("variables", {}) as Dictionary).get("vertical_slice_active", false))

func open_settings(return_state: String) -> void:
	settings_return_state = return_state
	settings_index = 0
	game_state = "settings"

func handle_settings_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		settings_manager.save_settings()
		game_state = settings_return_state
	elif event.is_action_pressed("ui_up"):
		settings_index = wrapi(settings_index - 1, 0, SETTINGS_ROWS.size())
	elif event.is_action_pressed("ui_down"):
		settings_index = wrapi(settings_index + 1, 0, SETTINGS_ROWS.size())
	elif event.is_action_pressed("ui_left") and settings_index < 7:
		settings_manager.adjust(SETTINGS_ROWS[settings_index], -1)
	elif event.is_action_pressed("ui_right") and settings_index < 7:
		settings_manager.adjust(SETTINGS_ROWS[settings_index], 1)
	elif event.is_action_pressed("ui_accept"):
		if SETTINGS_ROWS[settings_index] == "reset":
			settings_manager.reset_defaults()
			show_notification("Ajustes restablecidos.")
		elif SETTINGS_ROWS[settings_index] == "back":
			settings_manager.save_settings()
			game_state = settings_return_state

func open_save_menu(return_state: String) -> void:
	slot_return_state = return_state
	slot_index = 0
	pending_overwrite_slot = 0
	game_state = "save_menu"

func open_load_menu(return_state: String) -> void:
	slot_return_state = return_state
	slot_index = 0
	game_state = "load_menu"

func handle_slot_menu_input(event: InputEvent, saving: bool) -> void:
	var count := 4 if saving else 5
	if event.is_action_pressed("ui_cancel"):
		game_state = slot_return_state
	elif event.is_action_pressed("ui_up"):
		slot_index = wrapi(slot_index - 1, 0, count)
		pending_overwrite_slot = 0
	elif event.is_action_pressed("ui_down"):
		slot_index = wrapi(slot_index + 1, 0, count)
		pending_overwrite_slot = 0
	elif event.is_action_pressed("ui_accept"):
		if saving:
			if slot_index == 3:
				game_state = slot_return_state
				return
			var slot := slot_index + 1
			if SaveSystem.has_slot(slot, save_base_dir) and pending_overwrite_slot != slot:
				pending_overwrite_slot = slot
				show_notification("La ranura ya contiene datos. Pulsa Enter de nuevo para sobrescribir.")
				return
			if SaveSystem.save_to_slot(slot, save_payload(), save_base_dir):
				show_notification("Partida guardada en la ranura %d." % slot)
				pending_overwrite_slot = 0
		else:
			if slot_index == 4:
				game_state = slot_return_state
				return
			var loaded := SaveSystem.load_autosave(save_base_dir) if slot_index == 0 else SaveSystem.load_slot(slot_index, save_base_dir)
			if loaded.is_empty():
				show_notification("Esta ranura está vacía o dañada.")
			else:
				apply_loaded_data(loaded)

func handle_dialogue_input(event: InputEvent) -> void:
	if not active_directed_scene.is_empty():
		var choices := narrative_system.current_choices(narrative_state)
		if event.is_action_pressed("ui_up") and dialogue_system.is_line_revealed() and not choices.is_empty():
			dialogue_choice_index = wrapi(dialogue_choice_index - 1, 0, choices.size())
		elif event.is_action_pressed("ui_down") and dialogue_system.is_line_revealed() and not choices.is_empty():
			dialogue_choice_index = wrapi(dialogue_choice_index + 1, 0, choices.size())
		elif event.is_action_pressed("ui_accept"):
			if not dialogue_system.is_line_revealed():
				dialogue_system.reveal_line()
			else:
				advance_directed_scene(dialogue_choice_index if not choices.is_empty() else -1)
		return
	if event.is_action_pressed("ui_accept"):
		if dialogue_system.advance():
			finish_dialogue()
		else:
			action_animation = "talk"
			action_time = 0.0
			action_duration = 0.22
	elif event.is_action_pressed("ui_cancel"):
		finish_dialogue()

func handle_world_map_input(event: InputEvent) -> void:
	if is_menu_event(event):
		open_game_menu("world_map")
	elif event.is_action_pressed("ui_accept") and action_animation != "travel":
		var allowed := unlocked_locations.duplicate()
		for discovered_id in world_exploration_state.get("discovered", []) as Array:
			if discovered_id not in allowed: allowed.append(discovered_id)
		var destination := WorldExplorationSystem.nearest_location(world_exploration_state, locations, allowed)
		if destination.is_empty():
			show_notification("Acércate a un destino, campamento o localización descubierta.")
		elif WorldExplorationSystem.can_enter(world_exploration_state, destination, chapter, unlocked_locations):
			enter_world_location(str(destination["id"]))
		else:
			show_notification("La ruta sigue bloqueada por el capítulo, la bruma o el mar.")
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_C:
			camp_on_world_map()
		elif key_event.keycode == KEY_F:
			fast_travel_to_next_camp()

func handle_city_input(event: InputEvent) -> void:
	if city_activity_active:
		var challenge := city_life_system.activity_challenge(city_life_state, current_city)
		var options: Array = challenge.get("options", []) as Array
		if event.is_action_pressed("ui_cancel"):
			city_activity_active = false
		elif event.is_action_pressed("ui_up"):
			city_activity_choice = wrapi(city_activity_choice - 1, 0, maxi(1, options.size()))
		elif event.is_action_pressed("ui_down"):
			city_activity_choice = wrapi(city_activity_choice + 1, 0, maxi(1, options.size()))
		elif event.is_action_pressed("ui_accept"):
			resolve_city_activity()
		return
	if is_menu_event(event):
		open_game_menu("city")
	elif event.is_action_pressed("ui_up"):
		city_action_index = wrapi(city_action_index - 1, 0, city_actions().size())
	elif event.is_action_pressed("ui_down"):
		city_action_index = wrapi(city_action_index + 1, 0, city_actions().size())
	elif event.is_action_pressed("ui_left") and city_life_system.current_interior(city_life_state, current_city).is_empty():
		city_life_system.change_district(city_life_state, current_city, -1)
		WorldExplorationSystem.advance_time(world_exploration_state, 8.0)
		city_action_index = 0
		show_notification("Llegas a %s." % str(city_life_system.district(city_life_state, current_city).get("name", current_city)))
	elif event.is_action_pressed("ui_right") and city_life_system.current_interior(city_life_state, current_city).is_empty():
		city_life_system.change_district(city_life_state, current_city, 1)
		WorldExplorationSystem.advance_time(world_exploration_state, 8.0)
		city_action_index = 0
		show_notification("Llegas a %s." % str(city_life_system.district(city_life_state, current_city).get("name", current_city)))
	elif event.is_action_pressed("ui_accept"):
		var actions := city_actions()
		if actions.is_empty(): return
		city_action_index = clampi(city_action_index, 0, actions.size() - 1)
		execute_city_action(actions[city_action_index] as Dictionary)

func handle_landmark_input(event: InputEvent) -> void:
	if is_menu_event(event):
		open_game_menu("landmark")
	elif event.is_action_pressed("ui_up"):
		landmark_action_index = wrapi(landmark_action_index - 1, 0, LANDMARK_ACTIONS.size())
	elif event.is_action_pressed("ui_down"):
		landmark_action_index = wrapi(landmark_action_index + 1, 0, LANDMARK_ACTIONS.size())
	elif event.is_action_pressed("ui_accept"):
		match landmark_action_index:
			0: explore_current_landmark()
			1: camp_at_landmark()
			2: return_to_world_map()

func handle_dungeon_crawl_input(event: InputEvent) -> void:
	if is_menu_event(event):
		open_game_menu("dungeon_crawl")
		return
	var direction := Vector2i.ZERO
	if event.is_action_pressed("ui_left"): direction = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"): direction = Vector2i.RIGHT
	elif event.is_action_pressed("ui_up"): direction = Vector2i.UP
	elif event.is_action_pressed("ui_down"): direction = Vector2i.DOWN
	if direction != Vector2i.ZERO:
		var move_result := DungeonExplorationSystem.move(dungeon_exploration_state, direction)
		if bool(move_result.get("success", false)):
			facing_direction = CharacterAnimationSystem.direction_from_vector(Vector2(direction), facing_direction)
			action_animation = "run" if Input.is_key_pressed(KEY_SHIFT) else "walk"
			action_time = 0.0
			action_duration = 0.14
			show_notification(str(move_result.get("message", "")))
			if str(move_result.get("kind", "")) == "encounter":
				phase9_secret_encounter = false
				start_world_encounter({"id":move_result.get("encounter_id", ""), "enemy":move_result.get("enemy", "hollow_sentinel"), "rank_override":"normal", "display_name":"Patrulla de " + str(DungeonExplorationSystem.dungeon(current_dungeon).get("name", current_dungeon))}, "phase9_dungeon")
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		resolve_dungeon_interaction(DungeonExplorationSystem.interact(dungeon_exploration_state, DungeonExplorationSystem.available_abilities(party)))

func resolve_dungeon_interaction(result: Dictionary) -> void:
	show_notification(str(result.get("message", "")))
	if not bool(result.get("success", false)): return
	match str(result.get("kind", "")):
		"leave":
			DungeonExplorationSystem.leave(dungeon_exploration_state)
			game_state = "landmark"
		"floor":
			action_animation = "travel"
			action_time = 0.0
			action_duration = 0.45
		"key", "mechanism", "puzzle", "shortcut":
			action_animation = "mechanism"
			action_time = 0.0
			action_duration = 0.65
		"chest", "secret_chest":
			gold += int(result.get("gold", 0))
			add_item(str(result.get("item", "Poción menor")), "Tesoro recuperado en una mazmorra de Eryndor.", 1)
			var gathering_ids := CommerceSystem.GATHERING_NODES.keys()
			var dungeon_index := DungeonExplorationSystem.DUNGEONS.keys().find(current_dungeon)
			CommerceSystem.gather(commerce_state, str(gathering_ids[posmod(dungeon_index, gathering_ids.size())]), inventory)
			action_animation = "open_chest"
			action_time = 0.0
			action_duration = 0.65
		"trap":
			for member in joined_party():
				member["hp"] = maxi(1, int(member.get("hp", 1)) - int(result.get("damage", 0)))
			action_animation = "hurt"
			action_time = 0.0
			action_duration = 0.55
		"miniboss", "secret_boss":
			phase9_secret_encounter = str(result.get("kind", "")) == "secret_boss"
			start_world_encounter({"id":result.get("encounter_id", ""), "enemy":result.get("enemy", "hollow_sentinel"), "rank_override":"boss" if phase9_secret_encounter else "miniboss", "display_name":result.get("name", "")}, "phase9_dungeon")
		"complete":
			WorldExplorationSystem.explore_landmark(world_exploration_state, current_dungeon)
			gold += 120
			add_item("Fragmento prismático", "Núcleo cartográfico recuperado al completar una mazmorra.", 1)
			DungeonExplorationSystem.leave(dungeon_exploration_state)
			if current_dungeon == "eira_ruins" and is_vertical_slice_active():
				start_dialogue(Phase3StoryData.VERTICAL_SLICE_ENDING, "victory", "vertical_slice_complete", "dungeon")
			else:
				game_state = "landmark"
	autosave()

func handle_battle_input(event: InputEvent) -> void:
	if action_duration > 0.0:
		return
	if event.is_action_pressed("ui_up"):
		battle_command_index = wrapi(battle_command_index - 1, 0, BATTLE_COMMANDS.size())
	elif event.is_action_pressed("ui_down"):
		battle_command_index = wrapi(battle_command_index + 1, 0, BATTLE_COMMANDS.size())
	elif event.is_action_pressed("ui_left"):
		battle_target_index = wrapi(battle_target_index - 1, 0, maxi(1, PartyBattleSystem.living_allies(party_battle).size()))
	elif event.is_action_pressed("ui_right"):
		battle_target_index = wrapi(battle_target_index + 1, 0, maxi(1, PartyBattleSystem.living_allies(party_battle).size()))
	elif event.is_action_pressed("ui_accept"):
		execute_battle_command(battle_command_index)
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode >= KEY_1 and key_event.keycode <= KEY_8:
			execute_battle_command(int(key_event.keycode - KEY_1))

func execute_battle_command(index: int) -> void:
	battle_command_index = clampi(index, 0, BATTLE_COMMANDS.size() - 1)
	match battle_command_index:
		0: attack()
		1: crystal_art()
		2: heal_in_battle()
		3: perform_party_battle_action("defend")
		4: perform_party_battle_action("item", {"target_index": battle_target_index})
		5: perform_party_battle_action("switch", {"target_index": battle_target_index})
		6: perform_party_battle_action("combo")
		7: perform_party_battle_action("flee")

func handle_game_menu_input(event: InputEvent) -> void:
	if is_menu_event(event):
		close_game_menu()
	elif event.is_action_pressed("ui_left"):
		menu_tab = wrapi(menu_tab - 1, 0, MENU_TABS.size())
		menu_index = 0
	elif event.is_action_pressed("ui_right"):
		menu_tab = wrapi(menu_tab + 1, 0, MENU_TABS.size())
		menu_index = 0
	elif event.is_action_pressed("ui_up"):
		menu_index = maxi(0, menu_index - 1)
	elif event.is_action_pressed("ui_down"):
		menu_index = mini(get_menu_item_count() - 1, menu_index + 1)
	elif event.is_action_pressed("ui_accept"):
		activate_menu_item()

func get_menu_item_count() -> int:
	match menu_tab:
		0:
			return maxi(1, inventory.size())
		1:
			return 6
		2:
			return 5
		3:
			return maxi(1, joined_party().size())
		4:
			return maxi(1, journal_menu_entries().size())
		5:
			return 7
		6:
			return 5
	return 1

func activate_menu_item() -> void:
	if menu_tab == 0:
		use_selected_item()
	elif menu_tab == 1:
		activate_equipment_menu_item()
	elif menu_tab == 2:
		activate_advancement_menu_item()
	elif menu_tab == 3:
		var members := joined_party()
		if not members.is_empty():
			var member: Dictionary = members[clampi(menu_index, 0, members.size() - 1)]
			show_notification(str(HeroStorySystem.toggle_active(party, str(member["id"])).get("message", "")))
	elif menu_tab == 4:
		activate_journal_item()
	elif menu_tab == 5:
		activate_extras_item()
	elif menu_tab == 6:
		match menu_index:
			0:
				open_save_menu("game_menu")
			1:
				open_load_menu("game_menu")
			2:
				open_settings("game_menu")
			3:
				close_game_menu()
			4:
				game_state = "title"
				title_index = 0

func activate_extras_item() -> void:
	match menu_index:
		0:
			var catalog := BestiarySystem.catalog()
			var available: Array = []
			for definition in catalog:
				if (bestiary_state.get("records", {}) as Dictionary).has(str(definition["id"])): available.append(definition)
			if available.is_empty():
				show_notification("Aún no has observado criaturas.")
			else:
				var selected: Dictionary = available[extras_bestiary_index % available.size()]
				var scan_message := str(BestiarySystem.scan(bestiary_state, str(selected["id"])).get("message", ""))
				for contract_id in bestiary_state.get("contracts", {}) as Dictionary:
					var claim := BestiarySystem.claim_contract(bestiary_state, str(contract_id))
					if bool(claim.get("success", false)):
						gold += int(claim.get("gold", 0))
						scan_message += " " + str(claim.get("message", ""))
				show_notification(scan_message)
				extras_bestiary_index = wrapi(extras_bestiary_index + 1, 0, available.size())
		1:
			var market_city := current_city if current_city in CommerceSystem.CITIES else "valdoria"
			var products := CommerceSystem.stock(commerce_state, market_city)
			if products.is_empty():
				show_notification("El mercado está cerrado.")
			else:
				var result := CommerceSystem.buy(commerce_state, market_city, extras_market_index % products.size(), gold, inventory, equipment_state)
				gold = int(result.get("gold", gold))
				if bool(result.get("success", false)): extras_market_index = wrapi(extras_market_index + 1, 0, products.size())
				EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
				show_notification(str(result.get("message", "")))
		2:
			activate_next_faction_quest()
		3:
			start_next_endgame_encounter()
		4:
			var difficulty_id := EndgameSystem.cycle_difficulty(endgame_state)
			show_notification("Dificultad: %s." % EndgameSystem.DIFFICULTIES[difficulty_id]["name"])
		5:
			show_notification(str(CompletionSystem.toggle_accessibility(completion_state, "reduced_motion").get("message", "")))
		6:
			var language := CompletionSystem.cycle_language(completion_state)
			completion_state["credits_seen"] = true
			show_notification("Idioma: %s · Créditos registrados." % language.to_upper())
	autosave()

func activate_next_faction_quest() -> void:
	var city_id := current_city if current_city in CommerceSystem.CITIES else "valdoria"
	var chosen: Dictionary = {}
	for definition in FactionSystem.quests():
		if str(FactionSystem.FACTIONS[definition["faction"]]["city"]) != city_id: continue
		var status := str((faction_state["quest_status"] as Dictionary).get(str(definition["id"]), "locked"))
		if status in ["available", "active"]:
			chosen = definition
			break
	if chosen.is_empty():
		show_notification("No hay encargos de facción disponibles en esta ciudad.")
		return
	var quest_id := str(chosen["id"])
	if str((faction_state["quest_status"] as Dictionary)[quest_id]) == "available":
		var accepted := FactionSystem.accept(faction_state, quest_id)
		if not bool(accepted.get("success", false)):
			show_notification(str(accepted.get("message", "")))
			return
	var stage := int((faction_state["quest_stages"] as Dictionary).get(quest_id, 1))
	start_dialogue(FactionSystem.dialogue_lines(quest_id, stage), menu_return_state, "faction_quest:" + quest_id, city_id)

func start_next_endgame_encounter() -> void:
	var encounter: Dictionary
	if (endgame_state.get("arena_cleared", []) as Array).size() < 25:
		encounter = EndgameSystem.start_arena_trial(endgame_state)
	else:
		var boss_index := (endgame_state.get("superbosses_defeated", []) as Array).size()
		if boss_index >= EndgameSystem.SUPERBOSSES.size():
			start_new_game_plus_campaign()
			return
		encounter = EndgameSystem.start_superboss(endgame_state, boss_index)
	if not bool(encounter.get("success", false)):
		show_notification(str(encounter.get("message", "")))
		return
	pending_superboss_id = str(encounter.get("superboss_id", ""))
	start_world_encounter(encounter, "endgame")

func start_new_game_plus_campaign() -> void:
	var next_endgame := endgame_state.duplicate(true)
	var result := EndgameSystem.start_new_game_plus(next_endgame)
	if not bool(result.get("success", false)):
		show_notification(str(result.get("message", "")))
		return
	var carried_party := party.duplicate(true)
	var carried_inventory := inventory.duplicate(true)
	var carried_equipment := equipment_state.duplicate(true)
	var carried_advancement := advancement_state.duplicate(true)
	var carried_bestiary := bestiary_state.duplicate(true)
	var carried_completion := completion_state.duplicate(true)
	var carried_gold := gold
	new_game()
	party = carried_party
	inventory = carried_inventory
	equipment_state = carried_equipment
	advancement_state = carried_advancement
	bestiary_state = carried_bestiary
	completion_state = carried_completion
	endgame_state = next_endgame
	gold = carried_gold
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	show_notification(str(result.get("message", "Nueva Partida + iniciada.")))
	autosave()

func phase5_selected_member(use_advancement_index: bool = false) -> Dictionary:
	var members := joined_party()
	if members.is_empty(): return party[0] as Dictionary
	var index := advancement_member_index if use_advancement_index else equipment_member_index
	return members[clampi(index, 0, members.size() - 1)] as Dictionary

func activate_equipment_menu_item() -> void:
	var members := joined_party()
	if members.is_empty(): return
	if menu_index == 0:
		equipment_member_index = wrapi(equipment_member_index + 1, 0, members.size())
		show_notification("Equipo de %s." % phase5_selected_member()["name"])
		return
	var member := phase5_selected_member()
	var result: Dictionary = {}
	if menu_index >= 1 and menu_index <= 3:
		result = EquipmentSystem.cycle_equipment(equipment_state, str(member["id"]), EquipmentSystem.SLOTS[menu_index - 1])
	elif menu_index == 4:
		var recipes: Array = equipment_state.get("recipes_unlocked", [])
		if recipes.is_empty(): return
		var equipment_id := str(recipes[workshop_recipe_index % recipes.size()])
		result = EquipmentSystem.craft(equipment_state, inventory, equipment_id, gold)
		gold = int(result.get("gold", gold))
		if bool(result.get("success", false)): workshop_recipe_index = wrapi(workshop_recipe_index + 1, 0, recipes.size())
	elif menu_index == 5:
		var weapon_id := EquipmentSystem.equipped_id(equipment_state, str(member["id"]), "weapon")
		result = EquipmentSystem.upgrade(equipment_state, inventory, weapon_id, gold)
		gold = int(result.get("gold", gold))
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	show_notification(str(result.get("message", "Sin cambios.")))

func activate_advancement_menu_item() -> void:
	var members := joined_party()
	if members.is_empty(): return
	if menu_index == 0:
		advancement_member_index = wrapi(advancement_member_index + 1, 0, members.size())
		show_notification("Progreso de %s." % phase5_selected_member(true)["name"])
		return
	var member := phase5_selected_member(true)
	var character_id := str(member["id"])
	var message := ""
	match menu_index:
		1:
			message = str(AdvancementSystem.cycle_job(advancement_state, character_id).get("message", ""))
		2:
			message = str(AdvancementSystem.unlock_next_talent(advancement_state, character_id).get("message", ""))
		3:
			message = str(AdvancementSystem.cycle_skill(advancement_state, character_id).get("message", ""))
		4:
			var formation_id := AdvancementSystem.cycle_formation(advancement_state)
			message = "Formación: %s." % AdvancementSystem.FORMATIONS[formation_id]["name"]
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	show_notification(message)

func activate_journal_item() -> void:
	var entries := journal_menu_entries()
	if entries.is_empty(): return
	var entry: Dictionary = entries[clampi(menu_index, 0, entries.size() - 1)]
	var entry_type := str(entry.get("entry_type", "quest"))
	if entry_type == "hero_chapter":
		if str(entry.get("status", "locked")) != "available":
			show_notification("Ese capítulo personal todavía no está disponible.")
			return
		var story_result := hero_story_system.start_chapter(hero_story_state, str(entry["id"]))
		if bool(story_result.get("success", false)):
			start_dialogue(hero_story_system.chapter_dialogue_lines(str(entry["id"])), menu_return_state, "hero_chapter:" + str(entry["id"]), current_city if current_city in ["valdoria", "brumaforja", "celestia", "sylvaran"] else "world")
		return
	if entry_type == "cross_quest":
		if str(entry.get("status", "locked")) != "available":
			show_notification("Esta conversación cruzada aún no está disponible.")
			return
		start_dialogue(hero_story_system.cross_dialogue_lines(str(entry["id"])), menu_return_state, "cross_quest:" + str(entry["id"]), "world")
		return
	if entry_type == "hero_finale":
		if str(entry.get("status", "locked")) != "available":
			show_notification("Completa los 32 capítulos personales para abrir el final común.")
			return
		hero_story_state["finale_status"] = "active"
		start_dialogue(hero_story_system.finale_dialogue_lines(), menu_return_state, "hero_finale", "sanctuary")
		return
	if entry_type == "faction_quest":
		var quest_id := str(entry["id"])
		var status := str(entry.get("status", "locked"))
		if status == "available":
			var accepted := FactionSystem.accept(faction_state, quest_id)
			if not bool(accepted.get("success", false)):
				show_notification(str(accepted.get("message", "")))
				return
		elif status != "active":
			show_notification("Esta crónica de facción ya está cerrada.")
			return
		var stage := int((faction_state["quest_stages"] as Dictionary).get(quest_id, 1))
		start_dialogue(FactionSystem.dialogue_lines(quest_id, stage), menu_return_state, "faction_quest:" + quest_id, str(FactionSystem.FACTIONS[entry["faction"]]["city"]))
		return
	if str(entry.get("entry_type", "quest")) == "codex":
		show_notification("Entrada de códice: %s." % entry.get("title", ""))
		return
	if str(entry.get("category", "")) != "personal" or str(entry.get("status", "")) == "completed":
		show_notification("Esta entrada no tiene una escena pendiente.")
		return
	var scenes := {"personal_aren":"aren_memorial", "personal_lyra":"lyra_forbidden_map", "personal_brom":"brom_last_bell", "personal_seris":"seris_root_name", "main_open_council":"council_of_memory"}
	var scene_id := str(scenes.get(str(entry["id"]), ""))
	if not scene_id.is_empty(): start_directed_scene(scene_id, menu_return_state, "personal_quest", current_city if current_city in ["valdoria", "brumaforja", "celestia", "sylvaran"] else "world")

func journal_menu_entries() -> Array:
	var result: Array = []
	for quest in narrative_system.quest_entries(narrative_state):
		var entry: Dictionary = quest.duplicate(true)
		entry["entry_type"] = "quest"
		result.append(entry)
	for codex in narrative_system.codex_entries(narrative_state):
		var entry: Dictionary = codex.duplicate(true)
		entry["entry_type"] = "codex"
		entry["status"] = str(entry.get("category", "Códice"))
		entry["objective"] = str(entry.get("text", ""))
		result.append(entry)
	result.append_array(hero_story_system.journal_entries(hero_story_state))
	result.append_array(FactionSystem.journal_entries(faction_state))
	return result

func open_game_menu(return_state: String) -> void:
	menu_return_state = return_state
	game_state = "game_menu"
	menu_tab = 0
	menu_index = 0
	action_animation = "menu_open"
	action_time = 0.0
	action_duration = 0.25

func close_game_menu() -> void:
	game_state = menu_return_state
	action_animation = "idle"

func start_dialogue(lines: Array, return_state: String, completion: String, backdrop: String) -> void:
	dialogue_system.begin(lines, return_state, completion, backdrop)
	game_state = "dialogue"
	action_animation = "talk"
	action_time = 0.0
	action_duration = 0.25

func start_directed_scene(scene_id: String, return_state: String, completion: String = "", backdrop: String = "world") -> bool:
	var result := narrative_system.start_scene(narrative_state, scene_id)
	if not bool(result.get("success", false)):
		show_notification(str(result.get("message", "No se pudo iniciar la escena.")))
		return false
	active_directed_scene = scene_id
	directed_return_state = return_state
	directed_completion = completion
	directed_backdrop = backdrop
	directed_scene_elapsed = 0.0
	dialogue_choice_index = 0
	load_directed_node()
	return true

func load_directed_node() -> void:
	var line := narrative_system.dialogue_line(narrative_state)
	if line.is_empty():
		complete_directed_scene()
		return
	directed_music_cue = str(line.get("music", directed_music_cue))
	dialogue_system.begin([line], directed_return_state, directed_completion, directed_backdrop)
	game_state = "dialogue"
	action_animation = "talk"
	action_time = 0.0
	action_duration = 0.25

func advance_directed_scene(choice_index: int = -1) -> void:
	if choice_index >= 0:
		var choices := narrative_system.current_choices(narrative_state)
		if choice_index < choices.size():
			var current_speaker := str(narrative_system.current_node(narrative_state).get("speaker", ""))
			var changed_bond := NarrativeDirectionSystem.apply_choice_bond(hero_story_state, party, current_speaker, choices[choice_index] as Dictionary)
			if not changed_bond.is_empty(): show_notification("Vínculo fortalecido: %s." % changed_bond.replace("+", " / "))
	var result := narrative_system.advance(narrative_state, choice_index)
	if bool(result.get("complete", false)):
		complete_directed_scene()
	else:
		dialogue_choice_index = 0
		load_directed_node()

func complete_directed_scene() -> void:
	var completed_scene := active_directed_scene
	active_directed_scene = ""
	game_state = directed_return_state
	dialogue_system.lines = []
	dialogue_system.index = 0
	if directed_completion == "phase6_council":
		if is_vertical_slice_active():
			unlock_location("eira_ruins")
			WorldExplorationSystem.discover(world_exploration_state, "eira_ruins")
			current_location = "eira_ruins"
			current_landmark = "eira_ruins"
			landmark_action_index = 0
			game_state = "landmark"
			show_notification("La decisión del Consejo revela el camino a Eira. Explora las ruinas.")
		else:
			show_notification("El Consejo Abierto recordará tu decisión.")
	elif completed_scene.begins_with("road_") or completed_scene.begins_with("inn_"):
		show_notification("Conversación de viaje registrada en la crónica.")
	else:
		show_notification("Misión narrativa completada.")
	directed_completion = ""
	autosave()

func complete_directed_scene_with_default_choices() -> void:
	var guard := 0
	while not active_directed_scene.is_empty() and guard < 64:
		guard += 1
		var choices := narrative_system.current_choices(narrative_state)
		advance_directed_scene(0 if not choices.is_empty() else -1)

func finish_dialogue() -> void:
	if not active_directed_scene.is_empty():
		complete_directed_scene_with_default_choices()
		return
	var completion := dialogue_system.completion
	game_state = dialogue_system.return_state
	dialogue_system.lines = []
	dialogue_system.index = 0
	dialogue_system.completion = ""
	if completion == "intro":
		chapter = 1
		unlock_location("valdoria")
		current_location = "valdoria"
		map_index = 0
	elif completion == "vertical_slice_intro":
		enter_valdoria_exploration()
	elif completion.begins_with("story_"):
		complete_city_chapter(completion.trim_prefix("story_"))
	elif completion == "finale":
		chapter = 6
		game_state = "victory"
		autosave()
	elif completion == "enter_phase3_dungeon":
		enter_dungeon()
	elif completion == "battle_oathbreaker" or completion == "battle_hollow_lion":
		start_phase3_battle(pending_phase3_enemy_id)
	elif completion == "phase3_reward":
		start_dialogue(Phase3StoryData.CLOSING_LINES, "valdoria_explore", "phase3_closing", "valdoria")
	elif completion == "phase3_closing":
		show_notification("Fase 3 completada: El León Despierto.")
		autosave()
		start_directed_scene("council_of_memory", "valdoria_explore", "phase6_council", "valdoria")
	elif completion == "vertical_slice_complete":
		(narrative_state["variables"] as Dictionary)["vertical_slice_complete"] = true
		game_state = "victory"
		show_notification("Demo vertical completada.")
		autosave()
	elif completion.begins_with("hero_chapter:"):
		var chapter_id := completion.trim_prefix("hero_chapter:")
		var story_outcome := str((narrative_state.get("variables", {}) as Dictionary).get("council_path", "truth"))
		var result := hero_story_system.complete_chapter(hero_story_state, chapter_id, story_outcome)
		var joined_id := str(result.get("hero_id", ""))
		for member in party:
			if member is Dictionary and str(member.get("id", "")) == joined_id:
				member["joined"] = true
				if HeroStorySystem.active_party(party).size() < HeroStorySystem.MAX_ACTIVE_PARTY: member["active"] = true
		HeroStorySystem.normalize_roster(party)
		EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
		show_notification(str(result.get("message", "Capítulo personal completado.")))
		autosave()
	elif completion.begins_with("cross_quest:"):
		show_notification(str(hero_story_system.complete_cross_quest(hero_story_state, completion.trim_prefix("cross_quest:")).get("message", "Conversación completada.")))
		autosave()
	elif completion == "hero_finale":
		var council_path := str((narrative_state.get("variables", {}) as Dictionary).get("council_path", "undecided"))
		var ending_choice := "released" if council_path == "truth" else "guarded" if council_path == "mercy" else "shared"
		hero_story_system.complete_finale(hero_story_state, ending_choice)
		EndgameSystem.unlock(endgame_state)
		chapter = maxi(chapter, 7)
		game_state = "victory"
		autosave()
	elif completion.begins_with("faction_quest:"):
		var quest_id := completion.trim_prefix("faction_quest:")
		var faction_result := FactionSystem.advance(faction_state, quest_id, "concord")
		if bool(faction_result.get("completed", false)): gold += int(faction_result.get("gold", 0))
		show_notification(str(faction_result.get("message", "Misión de facción actualizada.")))
		autosave()

func complete_city_chapter(city_id: String) -> void:
	visited_cities[city_id] = true
	match city_id:
		"valdoria":
			chapter = 2
			party[1]["joined"] = true
			party[1]["active"] = true
			unlock_location("brumaforja")
			add_item("Sello de Valdoria", "Fragmento de la Corona de Ámbar hallado bajo la fuente del león.", 1)
		"brumaforja":
			chapter = 3
			party[2]["joined"] = true
			party[2]["active"] = true
			unlock_location("celestia")
			add_item("Runa de la Fragua", "Metal vivo que conserva el juramento de los primeros thanes.", 1)
		"celestia":
			chapter = 4
			unlock_location("sylvaran")
			add_item("Lente astral", "Cristal de faro capaz de revelar recuerdos borrados.", 1)
		"sylvaran":
			chapter = 5
			party[3]["joined"] = true
			party[3]["active"] = true
			unlock_location("sanctuary")
			add_item("Nombre de Eira", "Una hoja de plata que guarda el nombre verdadero de la guardiana.", 1)
	show_notification("Nuevo destino y entrada del diario desbloqueados.")
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	autosave()
	if city_id == "valdoria":
		enter_valdoria_exploration()

func begin_city_conversation() -> void:
	var urban := city_life_system.conversation(city_life_state, current_city, WorldExplorationSystem.period(world_exploration_state), chapter)
	var lines: Array = urban.get("lines", []) as Array
	if lines.is_empty():
		var all_lines := StoryData.get_city_lines(current_city)
		if all_lines.is_empty(): return
		var start: int = int(city_dialogue_progress.get(current_city, 0))
		var chunk_result := DialogueSystem.city_chunk(all_lines, start)
		city_dialogue_progress[current_city] = int(chunk_result["next"])
		lines = chunk_result["lines"] as Array
	start_dialogue(lines, "city", "city_chat", current_city)

func rest_at_inn() -> void:
	ProgressionSystem.restore_party(party)
	WorldExplorationSystem.advance_time(world_exploration_state, 480.0)
	CommerceSystem.advance_day(commerce_state)
	action_animation = "rest"
	action_time = 0.0
	action_duration = 1.1
	show_notification("El grupo descansa. PV y PM restaurados.")
	autosave()
	if narrative_road_content_unlocked():
		var banter := narrative_system.next_banter(narrative_state, "rest_banter")
		if not banter.is_empty(): start_directed_scene(banter, "city", "rest_banter", current_city)

func buy_supplies() -> void:
	if gold < 15:
		show_notification("No tienes suficiente oro.")
		return
	gold -= 15
	add_item("Poción menor", "Restaura 20 PV a un miembro del grupo.", 2)
	add_item("Éter estelar", "Restaura 8 PM a un miembro del grupo.", 1)
	action_animation = "celebrate"
	action_time = 0.0
	action_duration = 0.8
	show_notification("Compras 2 pociones y 1 éter estelar.")

func add_item(item_name: String, description: String, amount: int) -> void:
	var definition := GameDatabase.item_or_fallback(item_name, description)
	var result := InventorySystem.add_item(inventory, item_name, definition, amount)
	if not bool(result["success"]):
		GameLogger.warning("inventory", str(result["message"]))

func use_selected_item() -> void:
	var keys := inventory.keys()
	if keys.is_empty():
		return
	menu_index = clampi(menu_index, 0, keys.size() - 1)
	var item_name: String = str(keys[menu_index])
	var member: Dictionary = party[0] as Dictionary
	var result := InventorySystem.use_item(inventory, item_name, member)
	show_notification(str(result["message"]))
	if not bool(result["success"]):
		return
	action_animation = "heal"
	action_time = 0.0
	action_duration = 0.7

func joined_party() -> Array:
	return ProgressionSystem.joined_party(party)

func selected_party_member() -> Dictionary:
	var members := joined_party()
	if members.is_empty():
		return party[0] as Dictionary
	var index: int = clampi(menu_index, 0, members.size() - 1)
	return members[index] as Dictionary

func leader_index() -> int:
	var active := HeroStorySystem.active_party(party)
	if active.is_empty(): return 0
	return maxi(0, party.find(active[0]))

func process_world_map_movement(delta: float) -> void:
	WorldExplorationSystem.synchronize_progress(world_exploration_state, unlocked_locations, chapter)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	is_moving = input.length_squared() > 0.001
	is_running = Input.is_action_pressed("run")
	if is_moving:
		walk_time += delta
		var previous := WorldExplorationSystem.position(world_exploration_state)
		var current := WorldExplorationSystem.move(world_exploration_state, input, delta, is_running)
		facing_direction = CharacterAnimationSystem.direction_from_vector(current - previous, facing_direction)
		for i in locations.size():
			if current.distance_to((locations[i] as Dictionary)["position"] as Vector2) < 54.0:
				map_index = i
				break
		var discoveries := WorldExplorationSystem.discover_nearby(world_exploration_state, chapter)
		for location_id in discoveries:
			unlock_location(location_id)
			show_notification("Localización oculta descubierta: %s." % location_name(location_id))
		var danger := WorldExplorationSystem.danger_at_position(world_exploration_state)
		if not danger.is_empty() and game_state == "world_map": start_world_encounter(danger, "world")

func enter_world_location(location_id: String) -> void:
	var location := TravelSystem.location_by_id(locations, location_id)
	if location.is_empty(): return
	WorldExplorationSystem.set_position(world_exploration_state, location["position"] as Vector2)
	world_exploration_state["last_safe_location"] = location_id
	current_location = location_id
	if location_id == "sanctuary":
		sanctuary_controller.configure_world("sanctuary")
		game_state = "explore"
		hero_position = Vector2(315, 400)
		sanctuary_controller.set_player_position(hero_position)
		camera_system.snap(hero_position)
		show_notification("Has llegado al Santuario de Lúmina.")
	elif str(location.get("type", "city")) == "city":
		enter_city(location_id)
	else:
		current_landmark = location_id
		landmark_action_index = 0
		game_state = "landmark"
		show_notification("Has descubierto un nuevo punto de retorno seguro.")
		var fast: Array = world_exploration_state.get("fast_travel", []) as Array
		if location_id not in fast: fast.append(location_id)
		autosave()

func camp_on_world_map() -> void:
	var result := WorldExplorationSystem.camp(world_exploration_state, locations)
	show_notification(str(result["message"]))
	if bool(result["success"]):
		ProgressionSystem.restore_party(party)
		action_animation = "rest"
		action_time = 0.0
		action_duration = 0.8
		autosave()

func fast_travel_to_next_camp() -> void:
	var fast: Array = world_exploration_state.get("fast_travel", []) as Array
	if fast.is_empty():
		show_notification("Todavía no has establecido puntos de viaje rápido.")
		return
	var current_near := WorldExplorationSystem.nearest_location(world_exploration_state, locations, fast, 60.0)
	var current_index := fast.find(str(current_near.get("id", "")))
	var destination_id := str(fast[wrapi(current_index + 1, 0, fast.size())])
	var destination := TravelSystem.location_by_id(locations, destination_id)
	var result := WorldExplorationSystem.fast_travel(world_exploration_state, destination)
	show_notification(str(result["message"]))
	if bool(result["success"]):
		current_location = destination_id
		for i in locations.size():
			if str((locations[i] as Dictionary)["id"]) == destination_id: map_index = i
		autosave()

func city_actions() -> Array:
	var result: Array = []
	var interior_id := city_life_system.current_interior(city_life_state, current_city)
	if not interior_id.is_empty():
		var venue := city_life_system.venue_by_id(current_city, interior_id)
		result.append({"id":"service", "label":service_label(str(venue.get("kind", "house")))})
		result.append({"id":"talk", "label":"CONVERSAR EN " + str(venue.get("name", "EL INTERIOR")).to_upper()})
		result.append({"id":"leave_venue", "label":"SALIR AL BARRIO"})
		return result
	result.append({"id":"talk", "label":"HABLAR CON LOS HABITANTES"})
	var district := city_life_system.district(city_life_state, current_city)
	for venue_value in district.get("venues", []) as Array:
		var venue: Dictionary = venue_value
		result.append({"id":"venue", "venue_id":str(venue["id"]), "label":"ENTRAR · " + str(venue["name"]).to_upper()})
	result.append({"id":"rumor", "label":"ESCUCHAR RUMORES"})
	result.append({"id":"conflict", "label":"CONFLICTO LOCAL"})
	result.append({"id":"activity", "label":str(city_life_system.activity(current_city).get("name", "Actividad")).to_upper()})
	result.append({"id":"depart", "label":"PARTIR AL MAPA MUNDIAL"})
	return result

func service_label(kind: String) -> String:
	return {"inn":"DESCANSAR Y GUARDAR · 12 ORO", "market":"COMPRAR SUMINISTROS · 15 ORO", "smithy":"ENCARGAR MATERIALES · 12 ORO", "tavern":"PEDIR RUMORES · 5 ORO", "house":"EXAMINAR LA CASA", "hall":"ATENDER EL CONFLICTO LOCAL"}.get(kind, "INTERACTUAR") as String

func execute_city_action(action: Dictionary) -> void:
	match str(action.get("id", "")):
		"talk": begin_city_conversation()
		"venue":
			if city_life_system.enter_venue(city_life_state, current_city, str(action["venue_id"])):
				city_action_index = 0
				action_animation = "interact"
				action_time = 0.0
				action_duration = 0.55
		"leave_venue":
			city_life_system.leave_venue(city_life_state, current_city)
			city_action_index = 0
		"service": use_current_city_service()
		"rumor": hear_city_rumor()
		"conflict": resolve_city_conflict()
		"activity":
			city_activity_active = true
			city_activity_choice = 0
		"depart": return_to_world_map()

func use_current_city_service() -> void:
	var venue_id := city_life_system.current_interior(city_life_state, current_city)
	var venue := city_life_system.venue_by_id(current_city, venue_id)
	var kind := str(venue.get("kind", "house"))
	match kind:
		"inn":
			if gold < 12: show_notification("No tienes suficiente oro.")
			else:
				gold -= 12
				rest_at_inn()
		"market": buy_supplies()
		"smithy":
			if gold < 12: show_notification("No tienes suficiente oro.")
			else:
				gold -= 12
				add_item("Hierro resonante", "Material recuperado por un artesano local.", 2)
				action_animation = "use_item"
				action_time = 0.0
				action_duration = 0.7
				show_notification("El herrero prepara dos unidades de Hierro resonante.")
		"tavern":
			if gold < 5: show_notification("No tienes suficiente oro.")
			else:
				gold -= 5
				hear_city_rumor()
		"hall": resolve_city_conflict()
		_:
			begin_city_conversation()
	city_life_system.mark_service(city_life_state, current_city, kind)
	WorldExplorationSystem.advance_time(world_exploration_state, 25.0)

func hear_city_rumor() -> void:
	var rumor := city_life_system.next_rumor(city_life_state, current_city)
	var unlock_id := str(rumor.get("unlocks", ""))
	if not unlock_id.is_empty():
		WorldExplorationSystem.discover(world_exploration_state, unlock_id)
		unlock_location(unlock_id)
	show_notification(str(rumor.get("text", "No quedan rumores nuevos.")) + (" · Nueva localización: %s." % location_name(unlock_id) if not unlock_id.is_empty() else ""))
	action_animation = "talk"
	action_time = 0.0
	action_duration = 0.5

func resolve_city_conflict() -> void:
	var result := city_life_system.advance_conflict(city_life_state, current_city)
	show_notification(str(result["message"]))
	if bool(result.get("success", false)):
		action_animation = "talk"
		action_time = 0.0
		action_duration = 0.65
		WorldExplorationSystem.advance_time(world_exploration_state, 45.0)
		if bool(result.get("completed", false)):
			gold += 30
			show_notification(str(result["message"]) + " Recompensa cívica: 30 oro.")
		autosave()

func resolve_city_activity() -> void:
	var result := city_life_system.resolve_activity(city_life_state, current_city, city_activity_choice)
	city_activity_active = false
	show_notification(str(result["message"]))
	if bool(result.get("reward", false)):
		gold += 20
		add_item("Fragmento prismático", "Premio de una actividad urbana.", 1)
		show_notification(str(result["message"]) + " Premio: 20 oro y un Fragmento prismático.")
	action_animation = "celebrate" if bool(result.get("correct", false)) else "hurt"
	action_time = 0.0
	action_duration = 0.7
	WorldExplorationSystem.advance_time(world_exploration_state, 30.0)
	autosave()

func return_to_world_map() -> void:
	city_life_system.leave_venue(city_life_state, current_city)
	current_location = current_city if current_landmark.is_empty() else current_landmark
	current_landmark = ""
	WorldExplorationSystem.set_position(world_exploration_state, location_position(current_location))
	game_state = "world_map"
	autosave()

func explore_current_landmark() -> void:
	var landmark := WorldExplorationSystem.landmark_by_id(current_landmark)
	if landmark.is_empty(): return
	current_dungeon = current_landmark
	var result := DungeonExplorationSystem.enter(dungeon_exploration_state, current_dungeon)
	if not bool(result.get("success", false)):
		show_notification(str(result.get("message", "No se puede entrar.")))
		return
	WorldExplorationSystem.advance_time(world_exploration_state, 20.0)
	game_state = "dungeon_crawl"
	show_notification(str(result["message"]))
	autosave()

func camp_at_landmark() -> void:
	var result := WorldExplorationSystem.camp(world_exploration_state, locations)
	show_notification(str(result["message"]))
	if bool(result["success"]):
		ProgressionSystem.restore_party(party)
		action_animation = "rest"
		action_time = 0.0
		action_duration = 0.8
		autosave()

func unlock_location(location_id: String) -> void:
	TravelSystem.unlock(unlocked_locations, location_id)

func start_travel(destination: String) -> void:
	pending_destination = destination
	facing_direction = CharacterAnimationSystem.direction_from_vector(location_position(destination) - location_position(current_location), facing_direction)
	action_animation = "travel"
	action_time = 0.0
	action_duration = 0.85

func arrive_at_destination(destination: String) -> void:
	pending_destination = ""
	WorldExplorationSystem.advance_time(world_exploration_state, 90.0)
	enter_world_location(destination)
	if narrative_road_content_unlocked():
		var banter := narrative_system.next_banter(narrative_state, "travel_banter")
		if not banter.is_empty():
			var return_state := game_state
			start_directed_scene(banter, return_state, "travel_banter", destination)

func narrative_road_content_unlocked() -> bool:
	return str((narrative_state.get("quests", {}) as Dictionary).get("main_open_council", {}).get("status", "locked")) == "completed"

func enter_city(city_id: String) -> void:
	current_city = city_id
	current_location = city_id
	current_landmark = ""
	game_state = "city"
	city_action_index = 0
	city_life_system.leave_venue(city_life_state, city_id)
	var expected_chapter := {"valdoria": 1, "brumaforja": 2, "celestia": 3, "sylvaran": 4}
	if int(expected_chapter.get(city_id, -1)) == chapter and not bool(visited_cities.get(city_id, false)):
		if city_id == "valdoria":
			party[1]["joined"] = true
			party[1]["active"] = true
		elif city_id == "brumaforja":
			party[2]["joined"] = true
			party[2]["active"] = true
		elif city_id == "sylvaran":
			party[3]["joined"] = true
			party[3]["active"] = true
		start_dialogue(StoryData.get_story_lines(chapter), "city", "story_" + city_id, city_id)
	else:
		if city_id == "valdoria" and str((phase3_state.get("main", {}) as Dictionary).get("status", "available")) != "completed":
			enter_valdoria_exploration()
		else:
			show_notification("Has llegado a %s." % location_name(city_id))
			autosave()

func enter_valdoria_exploration() -> void:
	current_city = "valdoria"
	current_location = "valdoria"
	sanctuary_controller.configure_world("valdoria")
	sanctuary_controller.set_player_position(valdoria_position)
	sanctuary_controller.facing_direction = facing_direction
	hero_position = valdoria_position
	camera_system.snap(hero_position)
	game_state = "valdoria_explore"
	show_notification(QuestSystem.objective(phase3_state))
	autosave()

func enter_dungeon() -> void:
	current_location = "valdoria_catacombs"
	sanctuary_controller.configure_world("dungeon")
	sanctuary_controller.set_player_position(dungeon_position)
	hero_position = dungeon_position
	camera_system.snap(hero_position)
	game_state = "dungeon"
	if int((phase3_state["main"] as Dictionary).get("stage", 0)) == 1:
		(phase3_state["main"] as Dictionary)["stage"] = 2
		start_dialogue(Phase3StoryData.DUNGEON_INTRO, "dungeon", "dungeon_intro", "dungeon")
	else:
		show_notification(QuestSystem.objective(phase3_state))
	autosave()

func location_name(location_id: String) -> String:
	var location := TravelSystem.location_by_id(locations, location_id)
	return str(location.get("name", location_id))

func location_position(location_id: String) -> Vector2:
	var location := TravelSystem.location_by_id(locations, location_id)
	if not location.is_empty():
		return location["position"] as Vector2
	return Vector2(480, 290)

func city_texture(city_id: String) -> Texture2D:
	match city_id:
		"valdoria":
			return CITY_VALDORIA
		"brumaforja":
			return CITY_BRUMAFORJA
		"celestia":
			return CITY_CELESTIA
		"sylvaran":
			return CITY_SYLVARAN
	return CITY_VALDORIA

func process_world_movement(_delta: float) -> void:
	if sanctuary_controller == null:
		return
	hero_position = sanctuary_controller.player_position()
	if game_state == "valdoria_explore": valdoria_position = hero_position
	elif game_state == "dungeon": dungeon_position = hero_position
	is_moving = sanctuary_controller.movement_state in ["walk", "run"]
	is_running = sanctuary_controller.is_running
	facing_direction = sanctuary_controller.facing_direction
	if is_moving:
		walk_time = sanctuary_controller.animation_elapsed
	if game_state == "explore":
		for i in guardians.size():
			if not defeated[i] and hero_position.distance_to(guardians[i]) < 45.0:
				start_battle(i)
	elif game_state == "dungeon":
		check_dungeon_encounters()

func handle_world_interaction(kind: String) -> void:
	if game_state == "explore":
		handle_sanctuary_interaction(kind)
	elif game_state == "valdoria_explore":
		handle_valdoria_interaction(kind)
	elif game_state == "dungeon":
		handle_dungeon_interaction(kind)

func handle_valdoria_interaction(kind: String) -> void:
	if action_duration > 0.0:
		return
	if kind == "world_gate":
		current_location = "valdoria"
		game_state = "world_map"
		autosave()
		return
	if kind == "dungeon_gate":
		if not bool((phase3_state["flags"] as Dictionary).get("dungeon_unlocked", false)):
			show_notification("La puerta está sellada. Habla con la capitana Elara.")
			return
		start_dialogue([["Aren","La piedra recuerda nuestros pasos. Entremos preparados."]], "valdoria_explore", "enter_phase3_dungeon", "valdoria")
		return
	var npc := Phase3StoryData.npc_by_interaction(kind)
	if npc.is_empty():
		return
	var npc_id := str(npc["id"])
	var quest_id := str(npc["quest"])
	if npc_id == "captain":
		handle_captain_interaction(npc)
	elif not quest_id.is_empty():
		handle_side_quest_interaction(npc, quest_id)
	else:
		start_dialogue(npc["lines"] as Array, "valdoria_explore", "npc_chat", "valdoria")

func handle_captain_interaction(npc: Dictionary) -> void:
	var main: Dictionary = phase3_state["main"]
	if str(main["status"]) == "available":
		QuestSystem.accept_main(phase3_state)
		start_dialogue(npc["lines"] as Array, "valdoria_explore", "main_accepted", "valdoria")
	elif QuestSystem.can_return_main(phase3_state):
		apply_quest_reward(QuestSystem.turn_in_main(phase3_state))
		start_dialogue(Phase3StoryData.RETURN_LINES, "valdoria_explore", "phase3_reward", "valdoria")
	elif str(main["status"]) == "completed":
		start_dialogue([["Elara","Valdoria ya conoce los nombres que sostenían sus cimientos. Gracias, Aren."]], "valdoria_explore", "npc_chat", "valdoria")
	else:
		show_notification(QuestSystem.objective(phase3_state))

func handle_side_quest_interaction(npc: Dictionary, quest_id: String) -> void:
	var quest: Dictionary = (phase3_state["side"] as Dictionary)[quest_id]
	if str(quest["status"]) == "available":
		QuestSystem.accept_side(phase3_state, quest_id)
		start_dialogue(npc["lines"] as Array, "valdoria_explore", "side_accepted", "valdoria")
	elif str(quest["status"]) == "ready":
		apply_quest_reward(QuestSystem.turn_in_side(phase3_state, quest_id))
		start_dialogue([[str(npc["name"]).capitalize(), side_completion_text(quest_id)]], "valdoria_explore", "side_completed", "valdoria")
	elif str(quest["status"]) == "completed":
		show_notification("Misión completada: %s" % side_quest_name(quest_id))
	else:
		show_notification("Progreso de %s: %d/%d" % [side_quest_name(quest_id), int(quest["progress"]), int(quest["target"])])

func side_quest_name(quest_id: String) -> String:
	return {"lost_ledger":"El registro perdido", "moonleaf_remedy":"Remedio de hoja lunar", "sentry_oath":"El juramento del centinela"}.get(quest_id, quest_id)

func side_completion_text(quest_id: String) -> String:
	return {"lost_ledger":"El registro permitirá devolver cada nombre a la historia.", "moonleaf_remedy":"Con esta hoja, los mineros dormirán sin escuchar al león.", "sentry_oath":"La ruta está segura. Mis reclutas podrán sostener la puerta."}.get(quest_id, "Tu ayuda será recordada.")

func apply_quest_reward(reward: Dictionary) -> void:
	if reward.is_empty(): return
	gold += int(reward.get("gold", 0))
	if reward.has("item"):
		add_item(str(reward["item"]), "Recompensa obtenida durante El León Despierto.", int(reward.get("amount", 1)))
	if int(reward.get("xp", 0)) > 0:
		ProgressionSystem.grant_xp(party[0] as Dictionary, int(reward["xp"]))
	show_notification("Recompensa: %d oro." % int(reward.get("gold", 0)))
	autosave()

func handle_dungeon_interaction(kind: String) -> void:
	match kind:
		"dungeon_exit":
			enter_valdoria_exploration()
		"seal_west", "seal_east":
			if QuestSystem.activate_seal(phase3_state, kind):
				action_animation = "mechanism"
				action_duration = 0.72
				show_notification("Sello activado (%d/2)." % QuestSystem.seals_active(phase3_state))
			else:
				show_notification("Este sello ya responde al cristal.")
		"lost_ledger":
			if QuestSystem.collect_objective(phase3_state, "ledger_found"):
				add_item("Registro de los Canteros", "Libro con los nombres borrados de los fundadores de Valdoria.", 1)
				show_notification("Objeto de misión: Registro de los Canteros.")
			else: show_notification("Un atril vacío cubierto de polvo.")
		"moonleaf":
			if QuestSystem.collect_objective(phase3_state, "herb_found"):
				add_item("Hoja lunar", "Hierba medicinal que crece junto a cristales antiguos.", 1)
				show_notification("Objeto de misión: Hoja lunar.")
			else: show_notification("La humedad conserva un tenue aroma medicinal.")
	autosave()

func check_dungeon_encounters() -> void:
	if game_state != "dungeon" or action_duration > 0.0:
		return
	for encounter in DUNGEON_ENCOUNTERS:
		var encounter_id := str(encounter["id"])
		if encounter_id in dungeon_defeated:
			continue
		var enemy_id := str(encounter["enemy"])
		if encounter_id == "miniboss" and not QuestSystem.can_fight_miniboss(phase3_state): continue
		if encounter_id == "boss" and not QuestSystem.can_fight_boss(phase3_state): continue
		if hero_position.distance_to(encounter["position"] as Vector2) < 42.0:
			if encounter_id in ["miniboss", "boss"]:
				pending_phase3_enemy_id = enemy_id
				start_dialogue(Phase3StoryData.MINIBOSS_INTRO if encounter_id == "miniboss" else Phase3StoryData.BOSS_INTRO, "dungeon", "battle_oathbreaker" if encounter_id == "miniboss" else "battle_hollow_lion", "dungeon")
			else:
				start_phase3_battle(enemy_id)
			return

func handle_sanctuary_interaction(kind: String) -> void:
	if action_duration > 0.0:
		return
	match kind:
		"chest":
			if bool(opened_interactions.get("chest", false)):
				show_notification("El cofre ya está vacío.")
				return
			opened_interactions["chest"] = true
			add_item("Poción menor", "Restaura 20 PV a un miembro del grupo.", 2)
			gold += 20
			action_animation = "open_chest"
			show_notification("Abres el cofre: 2 pociones y 20 monedas.")
		"mechanism":
			opened_interactions["mechanism"] = not bool(opened_interactions.get("mechanism", false))
			action_animation = "mechanism"
			show_notification("El mecanismo desplaza los anillos de piedra.")
		"altar":
			opened_interactions["altar"] = true
			ProgressionSystem.restore_party(party)
			action_animation = "use_item"
			show_notification("La luz del altar restaura al grupo.")
		_:
			return
	action_time = 0.0
	action_duration = 0.72
	autosave()

func start_battle(index: int) -> void:
	game_state = "battle"
	battle_context = "guardian"
	current_encounter_id = ""
	encounter_index = index
	enemy_data = GameDatabase.enemy(index)
	enemy_name = str(enemy_data["name"])
	enemy_max_hp = int(enemy_data["max_hp"])
	enemy_hp = enemy_max_hp
	enemy_intent = str(enemy_data["intent"])
	notification = "¡%s se prepara para usar %s!" % [enemy_name, enemy_intent]
	enemy_animation = "idle"
	queued_enemy_turn = false
	queued_defeat = false
	pending_enemy_damage = 0
	initialize_party_battle()

func start_phase3_battle(enemy_id: String) -> void:
	var runtime := GameDatabase.enemy_by_id(enemy_id)
	if runtime.is_empty():
		GameLogger.error("battle", "Unknown phase 3 enemy", {"enemy_id": enemy_id})
		return
	battle_context = "dungeon"
	enemy_data = runtime
	current_encounter_id = ""
	for encounter in DUNGEON_ENCOUNTERS:
		if str(encounter["enemy"]) == enemy_id and str(encounter["id"]) not in dungeon_defeated:
			current_encounter_id = str(encounter["id"])
			break
	encounter_index = int(enemy_data["sprite_index"])
	enemy_name = str(enemy_data["name"])
	enemy_max_hp = int(enemy_data["max_hp"])
	enemy_hp = enemy_max_hp
	enemy_intent = str(enemy_data["intent"])
	notification = "¡%s bloquea el camino! Intención: %s." % [enemy_name, enemy_intent]
	enemy_animation = "idle"
	queued_enemy_turn = false
	queued_defeat = false
	pending_enemy_damage = 0
	game_state = "battle"
	initialize_party_battle()

func start_world_encounter(encounter: Dictionary, context: String = "world") -> void:
	var enemy_id := str(encounter.get("enemy", "lunar_wolf"))
	var runtime := GameDatabase.enemy_by_id(enemy_id)
	if runtime.is_empty():
		GameLogger.error("battle", "Unknown world enemy", {"enemy_id":enemy_id})
		return
	if context in ["world", "landmark"] and enemy_id in BestiarySystem.VARIANT_BASES and int(bestiary_state.get("total_defeated", 0)) > 0 and int(bestiary_state.get("total_defeated", 0)) % 5 == 0:
		runtime = BestiarySystem.create_variant(enemy_id, int(bestiary_state.get("total_defeated", 0)) / 5)
	if context == "phase9_dungeon":
		runtime["rank"] = str(encounter.get("rank_override", "miniboss"))
		runtime["max_hp"] = int(round(float(runtime.get("max_hp", 1)) * (1.85 if runtime["rank"] == "boss" else 1.35)))
		runtime["hp"] = runtime["max_hp"]
		if not str(encounter.get("display_name", "")).is_empty(): runtime["name"] = str(encounter["display_name"])
	elif context == "endgame":
		runtime["rank"] = str(encounter.get("rank_override", "normal"))
		EndgameSystem.apply_scaling(runtime, float(encounter.get("scale", 1.0)), endgame_state)
		if not str(encounter.get("display_name", "")).is_empty(): runtime["name"] = str(encounter["display_name"])
	battle_context = context
	current_encounter_id = str(encounter.get("id", "world_" + enemy_id))
	enemy_data = runtime
	encounter_index = int(runtime.get("sprite_index", 0))
	enemy_name = str(runtime["name"])
	enemy_max_hp = int(runtime["max_hp"])
	enemy_hp = enemy_max_hp
	enemy_intent = str(runtime["intent"])
	notification = "¡Peligro visible! %s corta la ruta." % enemy_name
	enemy_animation = "idle"
	queued_enemy_turn = false
	queued_defeat = false
	pending_enemy_damage = 0
	game_state = "battle"
	initialize_party_battle()

func battle_return_state() -> String:
	if battle_context == "dungeon": return "dungeon"
	if battle_context == "phase9_dungeon": return "dungeon_crawl"
	if battle_context == "landmark": return "landmark"
	if battle_context == "world": return "world_map"
	if battle_context == "endgame": return "world_map"
	return "explore"

func initialize_party_battle() -> void:
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	BestiarySystem.observe(bestiary_state, enemy_data)
	party_battle = PartyBattleSystem.create_battle(party, enemy_data)
	battle_command_index = 0
	battle_target_index = 0
	var opening_messages := PartyBattleSystem.resolve_until_player(party_battle, rng)
	sync_party_battle()
	if str(party_battle.get("outcome", "ongoing")) == "defeat":
		handle_party_defeat()
	elif not opening_messages.is_empty():
		notification += " " + " ".join(opening_messages)
	if not resonance_tutorial_seen:
		resonance_tutorial_seen = true
		notification += " Explota debilidades para generar Resonancia y romper la defensa."

func sync_party_battle() -> void:
	if party_battle.is_empty(): return
	var runtime_enemy: Dictionary = party_battle["enemy"]
	enemy_hp = int(runtime_enemy["hp"])
	enemy_max_hp = int(runtime_enemy["max_hp"])
	PartyBattleSystem.update_enemy_phase(party_battle)
	enemy_intent = PartyBattleSystem.predicted_enemy_action(party_battle).capitalize()

func current_battle_member() -> Dictionary:
	return PartyBattleSystem.current_ally(party_battle) if not party_battle.is_empty() else party[0] as Dictionary

func attack() -> void:
	perform_party_battle_action("attack")

func crystal_art() -> void:
	perform_party_battle_action("art")

func heal_in_battle() -> void:
	perform_party_battle_action("heal", {"target_index": battle_target_index})

func perform_party_battle_action(action_id: String, args: Dictionary = {}) -> void:
	if party_battle.is_empty(): return
	# Mantiene compatibilidad con pruebas y herramientas que ajustan los PV visibles.
	(party_battle["enemy"] as Dictionary)["hp"] = clampi(enemy_hp, 0, enemy_max_hp)
	var result := PartyBattleSystem.perform_player_action(party_battle, action_id, args, inventory, rng)
	if not bool(result.get("success", false)):
		show_notification(str(result.get("message", "Acción no disponible.")))
		return
	sync_party_battle()
	notification = str(result["message"])
	var animation := str(result.get("animation", "attack"))
	action_animation = animation if CharacterAnimationSystem.validate_state(animation) else "attack"
	enemy_animation = "hurt" if int(result.get("damage", 0)) > 0 else "attack_left"
	action_time = 0.0
	action_duration = 0.9 if action_animation == "special" else 0.7
	start_battle_impact(int(result.get("damage", 0)), str(result.get("element", "light" if action_animation == "heal" else "physical")), bool(result.get("weak", false)))
	match str(party_battle.get("outcome", "ongoing")):
		"victory": queued_defeat = true
		"defeat": handle_party_defeat()
		"fled": handle_battle_flee()
	battle_target_index = clampi(battle_target_index, 0, maxi(0, PartyBattleSystem.living_allies(party_battle).size() - 1)) if not party_battle.is_empty() else 0

func start_battle_impact(damage: int, element: String, weak: bool) -> void:
	battle_impact_time = 0.0
	battle_impact_damage = damage
	battle_impact_element = CombatPresentationSystem.normalized_element(element)
	battle_impact_weak = weak
	var reduced_motion := bool((completion_state.get("accessibility", {}) as Dictionary).get("reduced_motion", false))
	battle_hit_stop = 0.0 if reduced_motion else CombatPresentationSystem.hit_stop_seconds(damage, weak)

func handle_battle_flee() -> void:
	party_battle = {}
	action_animation = "run"
	game_state = battle_return_state()
	show_notification("El grupo ha escapado del combate.")

func handle_party_defeat() -> void:
	ProgressionSystem.restore_party(party)
	party_battle = {}
	if battle_context in ["world", "landmark"]:
		var safe_id := str(world_exploration_state.get("last_safe_location", "valdoria"))
		WorldExplorationSystem.set_position(world_exploration_state, location_position(safe_id))
		current_location = safe_id
		current_landmark = ""
		game_state = "world_map"
	else:
		hero_position = dungeon_position if battle_context == "dungeon" else Vector2(315, 400)
		sanctuary_controller.set_player_position(hero_position)
		camera_system.snap(hero_position)
		game_state = battle_return_state()
	action_animation = "hurt"
	show_notification("El cristal devuelve al grupo a salvo. No se pierde progreso.")

func queue_battle_resolution() -> void:
	if enemy_hp <= 0:
		queued_defeat = true
	else:
		queued_enemy_turn = true

func begin_enemy_attack() -> void:
	var hero: Dictionary = party[0] as Dictionary
	pending_enemy_damage = BattleSystem.enemy_damage(enemy_data, hero, rng)
	action_animation = "hurt"
	enemy_animation = "attack_left"
	action_time = 0.0
	action_duration = 0.62
	notification += " %s responde con %s (%d PV)." % [enemy_name, enemy_intent, pending_enemy_damage]

func resolve_enemy_attack() -> void:
	var hero: Dictionary = party[0] as Dictionary
	hero["hp"] = int(hero["hp"]) - pending_enemy_damage
	hero["mp"] = mini(int(hero["max_mp"]), int(hero["mp"]) + 1)
	pending_enemy_damage = 0
	if int(hero["hp"]) <= 0:
		hero["hp"] = hero["max_hp"]
		hero["mp"] = hero["max_mp"]
		if battle_context in ["world", "landmark"]:
			var safe_id := str(world_exploration_state.get("last_safe_location", "valdoria"))
			WorldExplorationSystem.set_position(world_exploration_state, location_position(safe_id))
			current_location = safe_id
			current_landmark = ""
			game_state = "world_map"
		else:
			hero_position = dungeon_position if battle_context == "dungeon" else Vector2(315, 400)
			sanctuary_controller.set_player_position(hero_position)
			camera_system.snap(hero_position)
			game_state = battle_return_state()
		action_animation = "hurt"
		notification = "El cristal devuelve al grupo al último refugio seguro."

func defeat_enemy() -> void:
	if battle_context == "endgame":
		defeat_endgame_enemy()
		return
	if battle_context == "phase9_dungeon":
		defeat_phase9_enemy()
		return
	if battle_context == "dungeon":
		defeat_phase3_enemy()
		return
	if battle_context in ["world", "landmark"]:
		defeat_world_enemy()
		return
	defeated[encounter_index] = true
	crystals += 1
	var reward := grant_complete_battle_rewards()
	if not (reward["level_names"] as Array).is_empty():
		notification = "¡Victoria! Suben de nivel: %s." % ", ".join(reward["level_names"] as Array)
	else:
		notification = "¡Victoria! %d EXP, %d oro%s." % [int(enemy_data.get("xp_reward", 0)), int(enemy_data.get("gold_reward", 0)), str(reward["loot_text"])]
	party_battle = {}
	action_animation = "celebrate"
	action_time = 0.0
	action_duration = 0.9
	if crystals == guardians.size():
		start_dialogue(StoryData.get_story_lines(5), "victory", "finale", "sanctuary")
	else:
		game_state = "explore"
		autosave()

func defeat_endgame_enemy() -> void:
	var reward := grant_complete_battle_rewards()
	var endgame_reward: Dictionary
	if pending_superboss_id.is_empty(): endgame_reward = EndgameSystem.record_arena_victory(endgame_state)
	else: endgame_reward = EndgameSystem.record_superboss_victory(endgame_state, pending_superboss_id)
	gold += int(endgame_reward.get("gold", 0))
	notification = "%s %s%s" % [str(endgame_reward.get("message", "Prueba superada.")), "Botín recuperado.", str(reward["loot_text"])]
	party_battle = {}
	current_encounter_id = ""
	pending_superboss_id = ""
	action_animation = "celebrate"
	action_time = 0.0
	action_duration = 0.85
	game_state = "world_map"
	autosave()

func defeat_world_enemy() -> void:
	var reward := grant_complete_battle_rewards()
	WorldExplorationSystem.resolve_danger(world_exploration_state, current_encounter_id)
	notification = "Ruta despejada: %d oro y %d EXP%s." % [int(enemy_data.get("gold_reward", 0)), int(enemy_data.get("xp_reward", 0)), str(reward["loot_text"])]
	party_battle = {}
	action_animation = "celebrate"
	action_time = 0.0
	action_duration = 0.75
	game_state = battle_return_state()
	current_encounter_id = ""
	autosave()

func defeat_phase9_enemy() -> void:
	var defeated_id := current_encounter_id
	var was_secret := phase9_secret_encounter
	var reward := grant_complete_battle_rewards()
	DungeonExplorationSystem.resolve_encounter(dungeon_exploration_state, defeated_id, was_secret)
	notification = "%s vencido: %d oro y %d EXP%s." % ["Jefe secreto" if was_secret else "Minijefe", int(enemy_data.get("gold_reward", 0)), int(enemy_data.get("xp_reward", 0)), str(reward["loot_text"])]
	party_battle = {}
	current_encounter_id = ""
	phase9_secret_encounter = false
	action_animation = "celebrate"
	action_time = 0.0
	action_duration = 0.85
	game_state = "dungeon_crawl"
	autosave()

func defeat_phase3_enemy() -> void:
	if not current_encounter_id.is_empty() and current_encounter_id not in dungeon_defeated:
		dungeon_defeated.append(current_encounter_id)
	var reward := grant_complete_battle_rewards()
	QuestSystem.record_enemy_defeat(phase3_state, str(enemy_data["id"]), str(enemy_data.get("rank", "normal")))
	action_animation = "celebrate"
	action_time = 0.0
	action_duration = 0.9
	if str(enemy_data.get("rank", "normal")) == "boss":
		notification = "El León Hueco inclina la cabeza. Regresa con la capitana Elara."
	elif not (reward["level_names"] as Array).is_empty():
		notification = "¡Victoria! Suben de nivel: %s." % ", ".join(reward["level_names"] as Array)
	else:
		notification = "¡Victoria! %d oro y %d EXP%s." % [int(enemy_data.get("gold_reward", 0)), int(enemy_data.get("xp_reward", 0)), str(reward["loot_text"])]
	party_battle = {}
	game_state = "dungeon"
	autosave()

func grant_complete_battle_rewards() -> Dictionary:
	BestiarySystem.record_defeat(bestiary_state, enemy_data)
	var level_names: Array[String] = []
	for member in joined_party():
		var levels_gained := ProgressionSystem.grant_xp(member as Dictionary, int(enemy_data.get("xp_reward", 0)))
		AdvancementSystem.grant_points(advancement_state, str(member["id"]), maxi(1, int(enemy_data.get("xp_reward", 0)) / 20), levels_gained)
		if levels_gained > 0:
			level_names.append(str(member["name"]))
	gold += int(enemy_data.get("gold_reward", 0))
	var loot_names: Array[String] = []
	if not party_battle.is_empty():
		for drop in party_battle.get("loot", []) as Array:
			var item_name := str(drop.get("item", ""))
			var amount := int(drop.get("amount", 1))
			if not item_name.is_empty():
				add_item(item_name, "Botín recuperado tras un combate.", amount)
				loot_names.append("%s ×%d" % [item_name, amount])
	var rank := str(enemy_data.get("rank", "normal"))
	var material_name := "Fragmento prismático" if rank == "boss" else "Hilo lunar" if rank == "miniboss" else "Hierro resonante"
	add_item(material_name, "Material recuperado tras un combate.", 2 if rank == "boss" else 1)
	loot_names.append("%s ×%d" % [material_name, 2 if rank == "boss" else 1])
	var special_equipment := "oath_brooch" if str(enemy_data.get("id", "")) == "hollow_lion" else "lion_mail" if str(enemy_data.get("id", "")) == "oathbreaker_knight" else ""
	if not special_equipment.is_empty() and EquipmentSystem.add_owned(equipment_state, special_equipment):
		loot_names.append(GameDatabase.equipment_by_id(special_equipment).display_name)
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	return {"level_names": level_names, "loot_text": " · Botín: " + ", ".join(loot_names) if not loot_names.is_empty() else ""}

func show_notification(text: String) -> void:
	notification = text
	notification_time = 3.5

func save_payload() -> Dictionary:
	refresh_completion_progress()
	var persisted_state := game_state
	if persisted_state == "game_menu": persisted_state = menu_return_state
	if persisted_state == "battle": persisted_state = battle_return_state()
	if persisted_state in ["save_menu", "load_menu", "settings"]: persisted_state = "world_map"
	return {
		"save_version": SaveSystem.CURRENT_VERSION,
		"chapter": chapter,
		"gold": gold,
		"play_seconds": play_seconds,
		"current_location": current_location,
		"current_city": current_city,
		"current_landmark": current_landmark,
		"scene_state": persisted_state,
		"unlocked_locations": unlocked_locations,
		"visited_cities": visited_cities,
		"city_dialogue_progress": city_dialogue_progress,
		"party": party,
		"inventory": inventory,
		"equipment_state": equipment_state,
		"advancement_state": advancement_state,
		"narrative_state": narrative_state,
		"world_exploration_state": world_exploration_state,
		"city_life_state": city_life_state,
		"dungeon_exploration_state": dungeon_exploration_state,
		"hero_story_state": hero_story_state,
		"bestiary_state": bestiary_state,
		"commerce_state": commerce_state,
		"faction_state": faction_state,
		"endgame_state": endgame_state,
		"completion_state": completion_state,
		"current_dungeon": current_dungeon,
		"hero_position": [hero_position.x, hero_position.y],
		"facing_direction": facing_direction,
		"opened_interactions": opened_interactions,
		"defeated": defeated,
		"crystals": crystals,
		"phase3_state": phase3_state,
		"valdoria_position": [valdoria_position.x, valdoria_position.y],
		"dungeon_position": [dungeon_position.x, dungeon_position.y],
		"dungeon_defeated": dungeon_defeated,
		"resonance_tutorial_seen": resonance_tutorial_seen
	}

func refresh_completion_progress() -> void:
	var discovered_entries := 0
	for record in (bestiary_state.get("records", {}) as Dictionary).values():
		if record is Dictionary and bool(record.get("scanned", false)): discovered_entries += 1
	var max_level := 1
	for member in party:
		if member is Dictionary: max_level = maxi(max_level, int(member.get("level", 1)))
	CompletionSystem.synchronize(completion_state, {
		"defeated":int(bestiary_state.get("total_defeated", 0)), "elite":int(bestiary_state.get("elite_defeated", 0)), "bestiary":discovered_entries,
		"gold":gold, "cities":visited_cities.size(), "heroes":joined_party().size(), "hero_chapters":(hero_story_state.get("completed_chapters", []) as Array).size(),
		"finale":1 if str(hero_story_state.get("finale_status", "")) == "completed" else 0, "dungeons":(dungeon_exploration_state.get("completed_dungeons", []) as Array).size(),
		"factions":(faction_state.get("completed", []) as Array).size(), "arena":(endgame_state.get("arena_cleared", []) as Array).size(),
		"superbosses":(endgame_state.get("superbosses_defeated", []) as Array).size(), "ng_plus":int(endgame_state.get("ng_plus_cycle", 0)), "legacy":int(endgame_state.get("legacy_points", 0)), "max_level":max_level
	})

func manual_save() -> void:
	open_save_menu("game_menu")

func autosave() -> void:
	if not SaveSystem.save_autosave(save_payload(), save_base_dir):
		GameLogger.warning("save", "Autosave failed")

func load_saved_game() -> void:
	var data := SaveSystem.load_slot(1, save_base_dir)
	if data.is_empty():
		show_notification("La partida guardada no pudo cargarse.")
		return
	apply_loaded_data(data)

func apply_loaded_data(data: Dictionary) -> void:
	chapter = int(data.get("chapter", 1))
	gold = int(data.get("gold", 0))
	play_seconds = float(data.get("play_seconds", 0.0))
	current_location = str(data.get("current_location", "valdoria"))
	current_city = str(data.get("current_city", "valdoria"))
	current_landmark = str(data.get("current_landmark", ""))
	var loaded_unlocked: Variant = data.get("unlocked_locations", ["valdoria"])
	if loaded_unlocked is Array:
		unlocked_locations = loaded_unlocked as Array
	var loaded_visited: Variant = data.get("visited_cities", {})
	if loaded_visited is Dictionary:
		visited_cities = loaded_visited as Dictionary
	var loaded_progress: Variant = data.get("city_dialogue_progress", {})
	if loaded_progress is Dictionary:
		city_dialogue_progress = loaded_progress as Dictionary
	var loaded_party: Variant = data.get("party", party)
	if loaded_party is Array:
		party = GameDatabase.reconcile_party(loaded_party as Array)
	var loaded_inventory: Variant = data.get("inventory", inventory)
	if loaded_inventory is Dictionary:
		inventory = loaded_inventory as Dictionary
	var loaded_equipment: Variant = data.get("equipment_state", EquipmentSystem.create_state())
	if loaded_equipment is Dictionary and EquipmentSystem.validate(loaded_equipment as Dictionary).is_empty(): equipment_state = loaded_equipment as Dictionary
	var loaded_advancement: Variant = data.get("advancement_state", AdvancementSystem.create_state())
	if loaded_advancement is Dictionary and AdvancementSystem.validate(loaded_advancement as Dictionary).is_empty(): advancement_state = loaded_advancement as Dictionary
	var loaded_narrative: Variant = data.get("narrative_state", narrative_system.create_state())
	if loaded_narrative is Dictionary and narrative_system.validate_state(loaded_narrative as Dictionary).is_empty(): narrative_state = loaded_narrative as Dictionary
	var loaded_world: Variant = data.get("world_exploration_state", WorldExplorationSystem.create_state())
	if loaded_world is Dictionary and WorldExplorationSystem.validate(loaded_world as Dictionary).is_empty(): world_exploration_state = loaded_world as Dictionary
	var loaded_city_life: Variant = data.get("city_life_state", city_life_system.create_state())
	if loaded_city_life is Dictionary and city_life_system.validate_state(loaded_city_life as Dictionary).is_empty(): city_life_state = loaded_city_life as Dictionary
	var loaded_dungeon_exploration: Variant = data.get("dungeon_exploration_state", DungeonExplorationSystem.create_state())
	if loaded_dungeon_exploration is Dictionary and DungeonExplorationSystem.validate_state(loaded_dungeon_exploration as Dictionary).is_empty(): dungeon_exploration_state = loaded_dungeon_exploration as Dictionary
	var loaded_hero_story: Variant = data.get("hero_story_state", hero_story_system.create_state())
	if loaded_hero_story is Dictionary and hero_story_system.validate_state(loaded_hero_story as Dictionary).is_empty(): hero_story_state = loaded_hero_story as Dictionary
	var loaded_bestiary: Variant = data.get("bestiary_state", BestiarySystem.create_state())
	if loaded_bestiary is Dictionary and BestiarySystem.validate_state(loaded_bestiary as Dictionary).is_empty(): bestiary_state = loaded_bestiary as Dictionary
	var loaded_commerce: Variant = data.get("commerce_state", CommerceSystem.create_state())
	if loaded_commerce is Dictionary and CommerceSystem.validate_state(loaded_commerce as Dictionary).is_empty(): commerce_state = loaded_commerce as Dictionary
	var loaded_factions: Variant = data.get("faction_state", FactionSystem.create_state())
	if loaded_factions is Dictionary and FactionSystem.validate_state(loaded_factions as Dictionary).is_empty(): faction_state = loaded_factions as Dictionary
	var loaded_endgame: Variant = data.get("endgame_state", EndgameSystem.create_state())
	if loaded_endgame is Dictionary and EndgameSystem.validate_state(loaded_endgame as Dictionary).is_empty(): endgame_state = loaded_endgame as Dictionary
	var loaded_completion: Variant = data.get("completion_state", CompletionSystem.create_state())
	if loaded_completion is Dictionary and CompletionSystem.validate_state(loaded_completion as Dictionary).is_empty(): completion_state = loaded_completion as Dictionary
	if str(hero_story_state.get("finale_status", "")) == "completed": EndgameSystem.unlock(endgame_state)
	current_dungeon = str(data.get("current_dungeon", dungeon_exploration_state.get("active_dungeon", "")))
	# Una escena guardada a mitad de decisión se reanuda en el mismo nodo.
	active_directed_scene = str(narrative_state.get("active_scene", ""))
	var loaded_position: Variant = data.get("hero_position", [315.0, 400.0])
	if loaded_position is Array and (loaded_position as Array).size() >= 2:
		hero_position = Vector2(float(loaded_position[0]), float(loaded_position[1]))
	facing_direction = str(data.get("facing_direction", "south"))
	if facing_direction not in CharacterAnimationSystem.DIRECTIONS:
		facing_direction = "south"
	var loaded_interactions: Variant = data.get("opened_interactions", {"chest": false, "mechanism": false, "altar": false})
	if loaded_interactions is Dictionary:
		opened_interactions = loaded_interactions as Dictionary
	var loaded_defeated: Variant = data.get("defeated", [false, false, false])
	if loaded_defeated is Array:
		defeated = loaded_defeated as Array
	crystals = int(data.get("crystals", 0))
	var loaded_phase3: Variant = data.get("phase3_state", QuestSystem.create_phase3_state())
	if loaded_phase3 is Dictionary and QuestSystem.validate(loaded_phase3 as Dictionary).is_empty():
		phase3_state = loaded_phase3 as Dictionary
	var loaded_valdoria_position: Variant = data.get("valdoria_position", [477.0, 438.0])
	if loaded_valdoria_position is Array and (loaded_valdoria_position as Array).size() >= 2:
		valdoria_position = Vector2(float(loaded_valdoria_position[0]), float(loaded_valdoria_position[1]))
	var loaded_dungeon_position: Variant = data.get("dungeon_position", [112.0, 438.0])
	if loaded_dungeon_position is Array and (loaded_dungeon_position as Array).size() >= 2:
		dungeon_position = Vector2(float(loaded_dungeon_position[0]), float(loaded_dungeon_position[1]))
	var loaded_dungeon_defeated: Variant = data.get("dungeon_defeated", [])
	if loaded_dungeon_defeated is Array:
		dungeon_defeated = loaded_dungeon_defeated as Array
	resonance_tutorial_seen = bool(data.get("resonance_tutorial_seen", false))
	var loaded_scene_state := str(data.get("scene_state", "world_map"))
	if current_location == "sanctuary" and loaded_scene_state == "explore":
		sanctuary_controller.configure_world("sanctuary")
		game_state = "explore"
	elif current_location == "valdoria_catacombs" or loaded_scene_state == "dungeon":
		sanctuary_controller.configure_world("dungeon")
		hero_position = dungeon_position
		game_state = "dungeon"
	elif current_location == "valdoria" and loaded_scene_state == "valdoria_explore":
		sanctuary_controller.configure_world("valdoria")
		hero_position = valdoria_position
		game_state = "valdoria_explore"
	elif loaded_scene_state == "city" and not city_life_system.city(current_city).is_empty():
		game_state = "city"
	elif loaded_scene_state == "dungeon_crawl" and DungeonExplorationSystem.DUNGEONS.has(current_dungeon):
		game_state = "dungeon_crawl"
	elif loaded_scene_state == "landmark" and not WorldExplorationSystem.landmark_by_id(current_landmark).is_empty():
		game_state = "landmark"
	else:
		game_state = "world_map"
	if sanctuary_controller != null:
		sanctuary_controller.set_player_position(hero_position)
		sanctuary_controller.facing_direction = facing_direction
	camera_system.snap(hero_position)
	EquipmentSystem.refresh_party_stats(party, equipment_state, advancement_state)
	for i in locations.size():
		if str(locations[i]["id"]) == current_location:
			map_index = i
	var validation_errors := ProgressionSystem.validate_party(party)
	validation_errors.append_array(InventorySystem.validate(inventory))
	validation_errors.append_array(TravelSystem.validate_route(locations, unlocked_locations))
	validation_errors.append_array(QuestSystem.validate(phase3_state))
	validation_errors.append_array(EquipmentSystem.validate(equipment_state))
	validation_errors.append_array(AdvancementSystem.validate(advancement_state))
	validation_errors.append_array(narrative_system.validate_state(narrative_state))
	validation_errors.append_array(WorldExplorationSystem.validate(world_exploration_state))
	validation_errors.append_array(city_life_system.validate_state(city_life_state))
	validation_errors.append_array(hero_story_system.validate_state(hero_story_state))
	validation_errors.append_array(DungeonExplorationSystem.validate_definitions())
	validation_errors.append_array(DungeonExplorationSystem.validate_state(dungeon_exploration_state))
	validation_errors.append_array(BestiarySystem.validate_state(bestiary_state))
	validation_errors.append_array(CommerceSystem.validate_state(commerce_state))
	validation_errors.append_array(FactionSystem.validate_state(faction_state))
	validation_errors.append_array(EndgameSystem.validate_state(endgame_state))
	validation_errors.append_array(CompletionSystem.validate_state(completion_state))
	if not validation_errors.is_empty():
		GameLogger.error("save", "Loaded state contains validation errors", {"errors": validation_errors})
	else:
		GameLogger.info("save", "Game state loaded", {"chapter": chapter, "location": current_location})
	show_notification("Partida cargada.")
	if not active_directed_scene.is_empty():
		directed_return_state = game_state
		directed_backdrop = current_city if current_city in ["valdoria", "brumaforja", "celestia", "sylvaran"] else "world"
		load_directed_node()

func wrap_text(text: String, max_characters: int) -> Array[String]:
	return GameUI.wrap_text(text, max_characters)

func draw_wrapped_text(text: String, position: Vector2, max_characters: int, line_height: float, font_size: int, color: Color) -> void:
	GameUI.wrapped_text(self, text, position, max_characters, line_height, font_size, color)

func character_source(sheet: Texture2D, character_index: int) -> Rect2:
	return GameUI.character_source(sheet, character_index)

func draw_character(sheet: Texture2D, character_index: int, feet_position: Vector2, display_size: Vector2, animation: String, tint: Color = Color.WHITE) -> void:
	if sheet == PARTY_SHEET:
		if character_index >= 4:
			GameUI.character(self, PHASE10_PARTY, character_index - 4, feet_position, display_size, animation, world_time, walk_time, action_time, tint)
			return
		var direction := "east" if game_state == "battle" else (facing_direction if game_state in ["explore", "valdoria_explore", "dungeon", "dungeon_crawl", "world_map"] else "south")
		var elapsed := action_time if action_duration > 0.0 and CharacterAnimationSystem.validate_state(animation) else world_time
		if animation in ["walk", "run", "travel"]:
			elapsed = walk_time if is_moving else action_time
		GameUI.animated_party_character(self, PARTY_ANIMATION_ATLAS, character_index, feet_position, display_size, animation, direction, elapsed, tint)
	else:
		GameUI.character(self, sheet, character_index, feet_position, display_size, animation, world_time, walk_time, action_time, tint)

func draw_story_portrait(character_index: int, feet_position: Vector2, display_size: Vector2, animation: String = "idle", tint: Color = Color.WHITE) -> void:
	if character_index >= 4:
		GameUI.character(self, PHASE10_PARTY, character_index - 4, feet_position, display_size, animation, world_time, walk_time, action_time, tint)
	else:
		draw_character(PARTY_SHEET, character_index, feet_position, display_size, animation, tint)

func draw_shadow(position: Vector2, radius: float, opacity: float = 0.42) -> void:
	GameUI.shadow(self, position, radius, opacity)

func draw_dynamic_shadow(position: Vector2, radius: float, opacity: float = 0.42) -> void:
	GameUI.dynamic_shadow(self, position, radius, world_time, inverse_lerp(84.0, 486.0, position.y), opacity)

func draw_bar(position: Vector2, size: Vector2, current: int, maximum: int, tint: Color) -> void:
	GameUI.bar(self, position, size, current, maximum, tint)

func draw_background_for(location_id: String) -> void:
	if location_id == "world":
		draw_texture_rect(WORLD_MAP, WORLD, false)
	elif location_id == "sanctuary":
		draw_texture_rect(SANCTUARY, WORLD, false)
	elif location_id == "dungeon":
		draw_texture_rect(VALDORIA_CATACOMBS, WORLD, false)
	else:
		draw_texture_rect(city_texture(location_id), WORLD, false)

func draw_title() -> void:
	draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.025, 0.07, 0.66), true)
	for radius in [90.0, 145.0, 210.0]:
		draw_circle(Vector2(480, 170), radius + sin(world_time * 1.6) * 4.0, Color(0.16, 0.65, 1.0, 0.035))
	draw_string(ThemeDB.fallback_font, Vector2(267, 122), "CRÓNICAS DEL CRISTAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("bff5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 158), "LA CORONA HUECA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f5d88f"))
	draw_character(PARTY_SHEET, 0, Vector2(220, 450), Vector2(190, 286), "idle")
	draw_character(PARTY_SHEET, 1, Vector2(740, 450), Vector2(190, 286), "idle")
	draw_rect(Rect2(325, 194, 310, 250), Color("06101ade"), true)
	draw_rect(Rect2(325, 194, 310, 250), Color("cdbb78"), false, 2)
	for i in TITLE_OPTIONS.size():
		var selected := i == title_index
		var color := Color("ffe5a3") if selected else Color("c4d1dc")
		if i == 2 and not has_any_save():
			color = Color("66717d")
		var prefix := "◆ " if selected else "  "
		draw_string(ThemeDB.fallback_font, Vector2(360, 230 + i * 40), prefix + TITLE_OPTIONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	draw_string(ThemeDB.fallback_font, Vector2(330, 468), "%d diálogos · 8 héroes · 3 ranuras · autoguardado" % (StoryData.dialogue_count() + Phase3StoryData.dialogue_count() + hero_story_system.dialogue_count()), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 490), "VERTICAL SLICE · VALDORIA / CATACUMBAS / EIRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9ee8d1"))

func has_any_save() -> bool:
	return SaveSystem.has_autosave(save_base_dir) or SaveSystem.has_slot(1, save_base_dir) or SaveSystem.has_slot(2, save_base_dir) or SaveSystem.has_slot(3, save_base_dir)

func format_play_time(seconds: float) -> String:
	var hours: int = int(seconds) / 3600
	var minutes: int = (int(seconds) / 60) % 60
	return "%02d:%02d" % [hours, minutes]

func draw_settings() -> void:
	draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.025, 0.07, 0.82), true)
	GameUI.panel(self, Rect2(160, 35, 640, 470))
	draw_string(ThemeDB.fallback_font, Vector2(205, 83), "AJUSTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("bff5ff"))
	for i in SETTINGS_ROWS.size():
		var selected := i == settings_index
		var y: float = 125.0 + i * 39.0
		draw_rect(Rect2(195, y - 24, 570, 33), Color("17354d") if selected else Color(0, 0, 0, 0), true)
		draw_string(ThemeDB.fallback_font, Vector2(215, y), ("◆ " if selected else "  ") + SETTINGS_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a3") if selected else Color.WHITE)
		if i < 7:
			draw_string(ThemeDB.fallback_font, Vector2(570, y), "‹  %s  ›" % settings_manager.display_value(SETTINGS_ROWS[i]), HORIZONTAL_ALIGNMENT_CENTER, 170, 15, Color("8fe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(205, 485), "Flechas: seleccionar/ajustar · Enter: aceptar · Esc: volver", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

func draw_slot_menu(saving: bool) -> void:
	draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.025, 0.07, 0.84), true)
	GameUI.panel(self, Rect2(145, 45, 670, 440))
	draw_string(ThemeDB.fallback_font, Vector2(190, 92), "GUARDAR PARTIDA" if saving else "CARGAR PARTIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("bff5ff"))
	var rows := 4 if saving else 5
	for i in rows:
		var is_back := i == rows - 1
		var y: float = 135.0 + i * 67.0
		var selected := i == slot_index
		draw_rect(Rect2(185, y - 26, 590, 55), Color("17354d") if selected else Color("0b1c2bd9"), true)
		if is_back:
			draw_string(ThemeDB.fallback_font, Vector2(210, y + 7), ("◆ " if selected else "  ") + "VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe5a3") if selected else Color.WHITE)
			continue
		var metadata: Dictionary
		var row_name: String
		if not saving and i == 0:
			metadata = SaveSystem.autosave_metadata(save_base_dir)
			row_name = "AUTOGUARDADO"
		else:
			var slot: int = i + 1 if saving else i
			metadata = SaveSystem.slot_metadata(slot, save_base_dir)
			row_name = "RANURA %d" % slot
		draw_string(ThemeDB.fallback_font, Vector2(210, y), ("◆ " if selected else "  ") + row_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe5a3") if selected else Color.WHITE)
		if metadata.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(435, y), "— Vacía —", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("71818e"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(390, y - 8), "Cap. %d · %s" % [int(metadata.get("chapter", 0)), location_name(str(metadata.get("location", "")))], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d7e5ed"))
			draw_string(ThemeDB.fallback_font, Vector2(390, y + 14), "%s · %s" % [format_play_time(float(metadata.get("play_seconds", 0.0))), str(metadata.get("saved_at", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("8fa8b8"))
	if pending_overwrite_slot > 0:
		draw_string(ThemeDB.fallback_font, Vector2(190, 460), "Confirma con Enter para sobrescribir la ranura %d." % pending_overwrite_slot, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffc479"))

func draw_world_atmosphere(region: String = "") -> void:
	var period := WorldExplorationSystem.period(world_exploration_state)
	match period:
		"amanecer": draw_rect(WORLD, Color(0.35, 0.16, 0.22, 0.16), true)
		"atardecer": draw_rect(WORLD, Color(0.45, 0.16, 0.04, 0.22), true)
		"noche": draw_rect(WORLD, Color(0.01, 0.035, 0.16, 0.52), true)
	var weather := WorldExplorationSystem.weather(world_exploration_state, region)
	if weather in ["lluvia", "lluvia suave", "temporal", "tormenta"]:
		var drops := WorldPresentationSystem.weather_density(weather)
		for i in drops:
			var x := fmod(float(i * 83) + world_time * (170.0 if weather in ["temporal", "tormenta"] else 92.0), 980.0) - 10.0
			var y := fmod(float(i * 47) + world_time * 128.0, 570.0) - 20.0
			draw_line(Vector2(x, y), Vector2(x - 7, y + 17), Color(0.62, 0.84, 1.0, 0.52), 1.0)
	elif weather in ["bruma", "bruma prismática"]:
		for i in 5:
			var fog_x := fmod(world_time * (8.0 + i) + float(i * 220), 1200.0) - 160.0
			draw_circle(Vector2(fog_x, 260 + i * 38), 145.0, Color(0.72, 0.86, 0.9, 0.055))
	elif weather in ["ceniza", "luceros", "aurora"]:
		for i in 30:
			var mote := Vector2(fmod(float(i * 71) + world_time * 13.0, 960.0), fmod(float(i * 97) + world_time * 19.0, 540.0))
			draw_circle(mote, 1.5 + float(i % 3), Color("f5c98a80") if weather == "ceniza" else Color("9ef6ff9a"))
	elif weather == "viento":
		for i in WorldPresentationSystem.weather_density(weather):
			var leaf := WorldPresentationSystem.atmospheric_point(i, world_time, Vector2(105, 24))
			draw_line(leaf, leaf + Vector2(12, 3), Color("d7c8838f"), 2.0)

func draw_world_map() -> void:
	draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.03, 0.08, 0.12), true)
	var discovered: Array = world_exploration_state.get("discovered", []) as Array
	for i in locations.size():
		var location: Dictionary = locations[i] as Dictionary
		var location_id := str(location["id"])
		if bool(location.get("hidden", false)) and location_id not in discovered: continue
		var position: Vector2 = location["position"] as Vector2
		var unlocked := location_id in unlocked_locations or location_id in discovered
		var selected := i == map_index
		var pulse: float = 4.0 + sin(world_time * 4.0) * 2.0 if selected else 0.0
		var landmark := str(location.get("type", "city")) == "landmark"
		draw_circle(position, (13.0 if landmark else 18.0) + pulse, Color(0.35, 0.9, 1.0, 0.2) if unlocked else Color(0.08, 0.09, 0.12, 0.72))
		draw_circle(position, 7.0 if landmark else 9.0, Color("9df6d2") if landmark and unlocked else Color("ffe096") if unlocked else Color("4c5360"))
		if selected: draw_arc(position, 25.0 + pulse, 0, TAU, 32, Color("bff5ff"), 2.0)
		draw_string(ThemeDB.fallback_font, position + Vector2(-58, 35), str(location["name"]), HORIZONTAL_ALIGNMENT_CENTER, 116, 11 if landmark else 13, Color.WHITE if unlocked else Color("7b8490"))
	for zone in WorldExplorationSystem.DANGER_ZONES:
		var danger_position: Vector2 = zone["position"]
		var cooldowns: Dictionary = world_exploration_state.get("danger_cooldowns", {}) as Dictionary
		var now := int(world_exploration_state.get("day", 1)) * 1440 + int(float(world_exploration_state.get("clock_minutes", 0.0)))
		if now < int(cooldowns.get(str(zone["id"]), 0)): continue
		draw_circle(danger_position, float(zone["radius"]) + sin(world_time * 3.0) * 2.0, Color(0.65, 0.08, 0.05, 0.18))
		draw_arc(danger_position, float(zone["radius"]), 0, TAU, 20, Color("ff765e"), 2.0)
		draw_string(ThemeDB.fallback_font, danger_position + Vector2(-10, 6), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 18, Color("fff1c9"))
	var marker_position := WorldExplorationSystem.position(world_exploration_state)
	marker_position.y -= 23.0 + abs(sin(world_time * 5.0)) * 4.0
	draw_shadow(marker_position + Vector2(0, 17), 10.0, 0.5)
	draw_character(PARTY_SHEET, leader_index(), marker_position + Vector2(0, 18), Vector2(50, 75), "run" if is_running and is_moving else "walk" if is_moving else "idle")
	draw_world_atmosphere()
	var region := WorldExplorationSystem.region_for_position(WorldExplorationSystem.position(world_exploration_state))
	draw_rect(Rect2(18, 14, 430, 90), Color("06101ae8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(34, 41), "MAPA EXPLORABLE · ERYNDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(34, 65), "%s · %s" % [WorldExplorationSystem.time_label(world_exploration_state), WorldExplorationSystem.weather(world_exploration_state, region).capitalize()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(34, 87), "Mover: WASD/flechas · Enter: entrar · C: acampar · F: viaje rápido", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a8c4d2"))
	draw_rect(Rect2(760, 18, 180, 54), Color("06101ad8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(775, 42), str(WorldExplorationSystem.REGIONS[region]["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d9f5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(775, 61), "Barco: %s" % ("disponible" if bool(world_exploration_state.get("ship_unlocked", false)) else "bloqueado"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a8c4d2"))

func draw_city() -> void:
	draw_texture_rect(city_texture(current_city), WORLD, false)
	draw_world_atmosphere(str(city_life_system.city(current_city).get("region", "")))
	var city_data := city_life_system.city(current_city)
	var district := city_life_system.district(city_life_state, current_city)
	var interior_id := city_life_system.current_interior(city_life_state, current_city)
	var interior := city_life_system.venue_by_id(current_city, interior_id)
	var members := HeroStorySystem.active_party(party)
	var spacing := 86.0
	var start_x := 645.0 - float(members.size() - 1) * spacing * 0.5
	var city_actors: Array[Dictionary] = []
	for i in members.size():
		city_actors.append({"kind":"hero", "index":party.find(members[i]), "position":Vector2(start_x + i * spacing, 438)})
	var visible_npcs := city_life_system.visible_npcs(city_life_state, current_city, WorldExplorationSystem.period(world_exploration_state))
	for i in mini(visible_npcs.size(), 4):
		var npc_anchor := Vector2(580 + i * 92, 285 + (i % 2) * 24)
		city_actors.append({"kind":"npc", "index":(i + 1) % 4, "position":WorldPresentationSystem.npc_patrol_position(npc_anchor, i, world_time, WorldExplorationSystem.period(world_exploration_state))})
	city_actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["position"] as Vector2).y < (b["position"] as Vector2).y)
	for actor in city_actors:
		var actor_position: Vector2 = actor["position"]
		var actor_scale := WorldPresentationSystem.depth_scale(actor_position.y)
		draw_dynamic_shadow(actor_position + Vector2(0, 18) * actor_scale, 15.0 * actor_scale, 0.4)
		var animation := action_animation if str(actor["kind"]) == "hero" and CharacterAnimationSystem.validate_state(action_animation) else "walk" if str(actor["kind"]) == "npc" else "idle"
		draw_character(PARTY_SHEET, int(actor["index"]), actor_position + Vector2(0, 18) * actor_scale, Vector2(76, 114) * actor_scale, animation)
	draw_rect(Rect2(0, 455, 960, 85), Color(0.02, 0.08, 0.11, 0.12), true)
	draw_rect(Rect2(18, 14, 540, 100), Color("06101ae8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(34, 41), str(city_data.get("name", current_city)).to_upper() + " · " + str(district.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(34, 65), WorldExplorationSystem.time_label(world_exploration_state) + " · " + str(city_data.get("ambience", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(34, 87), ("Interior: " + str(interior.get("name", "")) if not interior.is_empty() else str(district.get("description", ""))), HORIZONTAL_ALIGNMENT_LEFT, 510, 11, Color("a8c4d2"))
	if interior.is_empty(): draw_string(ThemeDB.fallback_font, Vector2(34, 105), "←/→ cambiar barrio · %d habitantes presentes" % visible_npcs.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9ee8d1"))
	draw_rect(Rect2(26, 160, 500, 360), Color("06101aeb"), true)
	draw_rect(Rect2(26, 160, 500, 360), Color("d5c47f"), false, 2)
	var actions := city_actions()
	var first := maxi(0, city_action_index - 5)
	for visual_index in mini(7, actions.size() - first):
		var action_index := first + visual_index
		var action: Dictionary = actions[action_index]
		var selected := action_index == city_action_index
		draw_string(ThemeDB.fallback_font, Vector2(48, 196 + visual_index * 40), ("◆ " if selected else "  ") + str(action["label"]), HORIZONTAL_ALIGNMENT_LEFT, 455, 14, Color("ffe5a3") if selected else Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(48, 500), "Oro %d · Música: %s" % [gold, str(city_data.get("music", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("aeeaff"))
	if city_activity_active: draw_city_activity()

func draw_city_activity() -> void:
	var activity := city_life_system.activity(current_city)
	var challenge := city_life_system.activity_challenge(city_life_state, current_city)
	draw_rect(Rect2(150, 90, 660, 370), Color("06101af5"), true)
	draw_rect(Rect2(150, 90, 660, 370), Color("78e5ff"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(185, 135), str(activity.get("name", "ACTIVIDAD")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("ffe5a3"))
	draw_wrapped_text(str(challenge.get("prompt", "")), Vector2(185, 175), 62, 22.0, 17, Color.WHITE)
	var options: Array = challenge.get("options", []) as Array
	for i in options.size():
		var selected := i == city_activity_choice
		draw_rect(Rect2(190, 245 + i * 54, 560, 42), Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, Vector2(215, 272 + i * 54), ("◆ " if selected else "  ") + str(options[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a3") if selected else Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(190, 432), "↑/↓ elegir · Enter confirmar · Esc cancelar", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

func draw_landmark() -> void:
	draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.025, 0.07, 0.72), true)
	draw_world_atmosphere(str(WorldExplorationSystem.landmark_by_id(current_landmark).get("region", "")))
	var landmark := WorldExplorationSystem.landmark_by_id(current_landmark)
	draw_rect(Rect2(135, 62, 690, 420), Color("06101af0"), true)
	draw_rect(Rect2(135, 62, 690, 420), Color("83e7c5"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(178, 112), str(landmark.get("name", current_landmark)).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(180, 143), "%s · %s · %s" % [str(landmark.get("kind", "lugar")).capitalize(), WorldExplorationSystem.time_label(world_exploration_state), WorldExplorationSystem.weather(world_exploration_state, str(landmark.get("region", ""))).capitalize()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aeeaff"))
	draw_wrapped_text(str(landmark.get("description", "")), Vector2(180, 180), 62, 22.0, 17, Color.WHITE)
	for i in LANDMARK_ACTIONS.size():
		var selected := i == landmark_action_index
		draw_rect(Rect2(180, 270 + i * 51, 590, 40), Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, Vector2(205, 296 + i * 51), ("◆ " if selected else "  ") + LANDMARK_ACTIONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe5a3") if selected else Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(180, 456), "Cartografiado: %s · Punto de viaje rápido activo" % ("sí" if current_landmark in (world_exploration_state.get("explored", []) as Array) else "no"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9ee8d1"))

func draw_sanctuary() -> void:
	var camera_origin := camera_system.canvas_origin()
	var camera_scale := Vector2.ONE * camera_system.zoom
	draw_set_transform(camera_origin, 0.0, camera_scale)
	draw_texture_rect(SANCTUARY, WORLD, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for kind in SanctuaryController.INTERACTIONS:
		var prop_position := camera_system.world_to_screen(SanctuaryController.INTERACTIONS[kind])
		match str(kind):
			"chest":
				var chest_color := Color("5e4430") if bool(opened_interactions.get("chest", false)) else Color("b77c38")
				draw_rect(Rect2(prop_position - Vector2(17, 12), Vector2(34, 23)), chest_color, true)
				draw_rect(Rect2(prop_position - Vector2(17, 12), Vector2(34, 23)), Color("f1cf75"), false, 2)
			"mechanism":
				draw_circle(prop_position, 15.0, Color("54c7d9") if bool(opened_interactions.get("mechanism", false)) else Color("435563"))
				draw_arc(prop_position, 20.0, 0.0, TAU, 12, Color("e2cb82"), 3.0)
			"altar":
				draw_circle(prop_position, 13.0, Color(0.38, 0.92, 1.0, 0.58))
				draw_arc(prop_position, 22.0, world_time, world_time + PI * 1.6, 18, Color("c2f7ff"), 2.0)
	var render_entries: Array[Dictionary] = []
	for i in guardians.size():
		if not defeated[i]:
			render_entries.append({"kind": "enemy", "index": i, "position": guardians[i]})
	render_entries.append({"kind": "hero", "index": 0, "position": hero_position})
	render_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["position"] as Vector2).y < (b["position"] as Vector2).y)
	for entry in render_entries:
		var world_position: Vector2 = entry["position"] as Vector2
		var screen_position := camera_system.world_to_screen(world_position)
		var depth_scale := lerpf(0.88, 1.08, clampf(inverse_lerp(84.0, 486.0, world_position.y), 0.0, 1.0)) * camera_system.zoom
		draw_dynamic_shadow(screen_position + Vector2(0, 14) * depth_scale, 19.0 * depth_scale, 0.48)
		if str(entry["kind"]) == "hero":
			var hero_anim := sanctuary_controller.movement_state if is_moving else action_animation
			draw_character(PARTY_SHEET, leader_index(), screen_position + Vector2(0, 18) * depth_scale, Vector2(105, 158) * depth_scale, hero_anim)
		else:
			var enemy_index := int(entry["index"])
			draw_character(ENEMY_SHEET, enemy_index + 1, screen_position + Vector2(0, 18) * depth_scale, Vector2(112, 150) * depth_scale, "idle")
	for occlusion_rect in SanctuaryController.OCCLUSION_RECTS:
		var destination := Rect2(camera_system.world_to_screen(occlusion_rect.position), occlusion_rect.size * camera_system.zoom)
		draw_texture_rect_region(SANCTUARY, destination, occlusion_rect)
	draw_rect(Rect2(18, 16, 370, 78), Color("06101ae8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(35, 46), "SANTUARIO DE LÚMINA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("bff5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(35, 73), "Guardianes: %d/3 · Shift: correr · E/Espacio: interactuar · M/Esc: menú" % crystals, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var nearby_interaction := sanctuary_controller.nearest_interaction()
	if not nearby_interaction.is_empty() and action_duration <= 0.0:
		draw_rect(Rect2(326, 432, 308, 34), Color("10283cf2"), true)
		draw_string(ThemeDB.fallback_font, Vector2(346, 455), "E / ESPACIO  ·  %s" % interaction_label(nearby_interaction), HORIZONTAL_ALIGNMENT_CENTER, 268, 14, Color("ffe5a3"))
	if not notification.is_empty():
		draw_rect(Rect2(145, 475, 670, 47), Color("06101ae8"), true)
		draw_wrapped_text(notification, Vector2(165, 497), 85, 17.0, 14, Color.WHITE)

func interaction_label(kind: String) -> String:
	match kind:
		"chest": return "ABRIR COFRE"
		"mechanism": return "ACTIVAR MECANISMO"
		"altar": return "USAR ALTAR"
		"dungeon_gate": return "ENTRAR EN LAS CATACUMBAS"
		"world_gate": return "SALIR AL MAPA MUNDIAL"
		"dungeon_exit": return "VOLVER A VALDORIA"
		"seal_west", "seal_east": return "ACTIVAR SELLO"
		"lost_ledger": return "RECOGER REGISTRO"
		"moonleaf": return "RECOGER HOJA LUNAR"
	if kind.begins_with("npc_"):
		var npc := Phase3StoryData.npc_by_interaction(kind)
		return "HABLAR CON %s" % str(npc.get("name", "HABITANTE"))
	return "INTERACTUAR"

func draw_valdoria_exploration() -> void:
	draw_exploration_background(CITY_VALDORIA)
	var render_entries: Array[Dictionary] = []
	for i in Phase3StoryData.NPCS.size():
		var npc: Dictionary = Phase3StoryData.NPCS[i]
		render_entries.append({"kind":"npc", "index":i, "position":npc["position"]})
	render_entries.append({"kind":"hero", "index":0, "position":hero_position})
	render_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["position"] as Vector2).y < (b["position"] as Vector2).y)
	for entry in render_entries:
		var world_position: Vector2 = entry["position"]
		var screen_position := camera_system.world_to_screen(world_position)
		var depth_scale := lerpf(0.78, 1.02, clampf(inverse_lerp(86.0, 496.0, world_position.y), 0.0, 1.0)) * camera_system.zoom
		draw_dynamic_shadow(screen_position + Vector2(0, 8) * depth_scale, 12.0 * depth_scale, 0.42)
		if str(entry["kind"]) == "hero":
			var hero_anim := sanctuary_controller.movement_state if is_moving else action_animation
			draw_character(PARTY_SHEET, leader_index(), screen_position + Vector2(0, 10) * depth_scale, Vector2(72, 108) * depth_scale, hero_anim)
		else:
			var npc_index := int(entry["index"])
			var nearby := hero_position.distance_to(world_position) < 55.0
			var tint: Color = [Color("e6c88d"), Color("9ccbe8"), Color("d8a5c8"), Color("9ec7a3")][npc_index % 4]
			GameUI.animated_party_character(self, PARTY_ANIMATION_ATLAS, npc_index % 4, screen_position + Vector2(0, 10) * depth_scale, Vector2(61, 92) * depth_scale, "talk" if nearby else "idle", "south", npc_animation_elapsed, tint)
	draw_exploration_hud("VALDORIA · PLAZA DEL LEÓN", QuestSystem.objective(phase3_state))

func draw_dungeon() -> void:
	draw_exploration_background(VALDORIA_CATACOMBS)
	for kind in sanctuary_controller.interaction_points:
		if kind == "dungeon_exit": continue
		var prop_position := camera_system.world_to_screen(sanctuary_controller.interaction_points[kind])
		if kind in ["seal_west", "seal_east"]:
			var active_seal := bool((phase3_state["flags"] as Dictionary).get(kind, false))
			draw_circle(prop_position, 16.0 + sin(world_time * 4.0) * 2.0, Color("60dbff") if active_seal else Color("4a5368"))
			draw_arc(prop_position, 23.0, world_time, world_time + PI * 1.7, 20, Color("ffe09a"), 2.0)
		elif kind == "lost_ledger" and not bool((phase3_state["flags"] as Dictionary).get("ledger_found", false)):
			draw_rect(Rect2(prop_position - Vector2(13, 9), Vector2(26, 18)), Color("b08b58"), true)
		elif kind == "moonleaf" and not bool((phase3_state["flags"] as Dictionary).get("herb_found", false)):
			draw_circle(prop_position, 12.0, Color("87e8c2"))
	var render_entries: Array[Dictionary] = []
	for encounter in DUNGEON_ENCOUNTERS:
		var encounter_id := str(encounter["id"])
		if encounter_id in dungeon_defeated: continue
		if encounter_id == "miniboss" and not QuestSystem.can_fight_miniboss(phase3_state): continue
		if encounter_id == "boss" and not QuestSystem.can_fight_boss(phase3_state): continue
		var runtime := GameDatabase.enemy_by_id(str(encounter["enemy"]))
		render_entries.append({"kind":"enemy", "position":encounter["position"], "data":runtime})
	render_entries.append({"kind":"hero", "position":hero_position})
	render_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["position"] as Vector2).y < (b["position"] as Vector2).y)
	for entry in render_entries:
		var world_position: Vector2 = entry["position"]
		var screen_position := camera_system.world_to_screen(world_position)
		var depth_scale := lerpf(0.72, 1.0, clampf(inverse_lerp(70.0, 498.0, world_position.y), 0.0, 1.0)) * camera_system.zoom
		draw_dynamic_shadow(screen_position + Vector2(0, 9) * depth_scale, 15.0 * depth_scale, 0.5)
		if str(entry["kind"]) == "hero":
			var hero_anim := sanctuary_controller.movement_state if is_moving else action_animation
			draw_character(PARTY_SHEET, leader_index(), screen_position + Vector2(0, 10) * depth_scale, Vector2(72, 108) * depth_scale, hero_anim)
		else:
			var runtime: Dictionary = entry["data"]
			var size := Vector2(102, 102) if str(runtime["rank"]) == "normal" else Vector2(145, 145) if str(runtime["rank"]) == "miniboss" else Vector2(178, 160)
			GameUI.grid_sprite(self, PHASE3_ENEMY_SHEET, int(runtime["sprite_index"]), screen_position + Vector2(0, 10) * depth_scale, size * depth_scale, "idle", world_time, action_time)
	draw_exploration_hud("CATACUMBAS DEL LEÓN DORMIDO", QuestSystem.objective(phase3_state))

func dungeon_iso_position(cell: Vector2i) -> Vector2:
	return Vector2(420.0 + float(cell.x - cell.y) * 34.0, 180.0 + float(cell.x + cell.y) * 14.0)

func draw_dungeon_crawl() -> void:
	draw_texture_rect(VALDORIA_CATACOMBS, WORLD, false)
	draw_rect(WORLD, Color(0.015, 0.025, 0.055, 0.78), true)
	var definition := DungeonExplorationSystem.dungeon(current_dungeon)
	var floor_index := DungeonExplorationSystem.current_floor(dungeon_exploration_state)
	var layout := DungeonExplorationSystem.floor_layout(floor_index, current_dungeon)
	var visited: Dictionary = dungeon_exploration_state.get("visited", {}) as Dictionary
	var revealed := current_dungeon in (dungeon_exploration_state.get("revealed_secrets", []) as Array)
	var dungeon_theme := DungeonExplorationSystem.theme(current_dungeon)
	for y in layout.size():
		for x in str(layout[y]).length():
			var cell := Vector2i(x, y)
			var tile := DungeonExplorationSystem.tile_at(floor_index, cell, current_dungeon)
			var center := dungeon_iso_position(cell)
			var diamond := PackedVector2Array([center + Vector2(0, -16), center + Vector2(34, 0), center + Vector2(0, 16), center + Vector2(-34, 0)])
			if tile == DungeonExplorationSystem.TILE_WALL:
				draw_colored_polygon(diamond, Color("101827"))
				continue
			var seen_key := DungeonExplorationSystem.visit_key(current_dungeon, floor_index, cell)
			var seen := visited.has(seen_key)
			var color: Color = dungeon_theme["floor"] if seen else dungeon_theme["hidden"]
			if tile in ["E", "S"]: color = Color("486a72") if seen else color
			draw_colored_polygon(diamond, color)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), dungeon_theme["line"] as Color if seen else Color("253446"), 1.0)
			if seen and tile in DungeonExplorationSystem.INTERACTIVE_TILES and (tile not in ["R", "X"] or revealed):
				var icon_color := {"K":Color("ffe18a"), "M":Color("70dbe8"), "P":Color("b899ff"), "N":Color("d2a66c"), "R":Color("ff9bdd"), "T":Color("ef726f"), "C":Color("81e5ad"), "B":Color("ff9b63"), "X":Color("e058ff")}.get(tile, Color.WHITE) as Color
				draw_circle(center - Vector2(0, 5), 7.0 + sin(world_time * 3.0 + x + y) * 1.2, icon_color)
	for patrol in DungeonExplorationSystem.visible_patrols(dungeon_exploration_state):
		var patrol_cell: Vector2i = patrol["position"]
		var patrol_position := dungeon_iso_position(patrol_cell) + Vector2(0, 7)
		draw_shadow(patrol_position + Vector2(0, 4), 11.0, 0.45)
		GameUI.grid_sprite(self, PHASE3_ENEMY_SHEET, int(GameDatabase.enemy_by_id(str(patrol["enemy"])).get("sprite_index", 0)), patrol_position, Vector2(54, 62), "idle", world_time, action_time)
		draw_arc(patrol_position - Vector2(0, 22), 13.0 + sin(world_time * 4.0), 0, TAU, 16, dungeon_theme["accent"] as Color, 2.0)
	var player_cell := DungeonExplorationSystem.position(dungeon_exploration_state)
	var player_screen := dungeon_iso_position(player_cell) + Vector2(0, 9)
	draw_shadow(player_screen + Vector2(0, 5), 13.0, 0.5)
	var hero_anim := action_animation if CharacterAnimationSystem.validate_state(action_animation) else "idle"
	draw_character(PARTY_SHEET, leader_index(), player_screen, Vector2(68, 102), hero_anim)
	draw_rect(Rect2(18, 15, 610, 91), Color("06101af0"), true)
	draw_rect(Rect2(18, 15, 610, 91), Color("9bd7d1"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(36, 43), "%s · PLANTA %d/%d" % [str(definition.get("name", current_dungeon)).to_upper(), floor_index + 1, DungeonExplorationSystem.FLOOR_LAYOUTS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(36, 67), "Automapa %.1f%% · Pasos %d · Habilidad secreta: %s" % [DungeonExplorationSystem.map_percentage(dungeon_exploration_state), int(dungeon_exploration_state.get("steps", 0)), DungeonExplorationSystem.ability_name(DungeonExplorationSystem.puzzle_ability(current_dungeon, floor_index))], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(36, 89), "Mover: flechas/WASD · Enter/E: interactuar · M/Esc: menú", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a8c4d2"))
	draw_rect(Rect2(748, 120, 190, 182), Color("06101aeb"), true)
	draw_string(ThemeDB.fallback_font, Vector2(766, 145), "AUTOMAPA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("bff5ff"))
	for map_cell in DungeonExplorationSystem.automap_cells(dungeon_exploration_state):
		var cell: Vector2i = map_cell["position"]
		var mini_rect := Rect2(770 + cell.x * 13, 158 + cell.y * 13, 11, 11)
		draw_rect(mini_rect, Color("ffe58f") if cell == player_cell else Color("5f8194"), true)
	var abilities := DungeonExplorationSystem.available_abilities(party)
	draw_rect(Rect2(18, 425, 630, 96), Color("06101aeb"), true)
	draw_string(ThemeDB.fallback_font, Vector2(36, 450), "CAPACIDADES DEL GRUPO · %s" % (", ".join(abilities) if not abilities.is_empty() else "ninguna"), HORIZONTAL_ALIGNMENT_LEFT, 590, 12, Color("9ee8d1"))
	draw_wrapped_text(notification if not notification.is_empty() else DungeonExplorationSystem.tile_hint(DungeonExplorationSystem.tile_at(floor_index, player_cell, current_dungeon)), Vector2(36, 477), 75, 17.0, 13, Color.WHITE)

func draw_exploration_background(texture: Texture2D) -> void:
	var camera_origin := camera_system.canvas_origin()
	var camera_scale := Vector2.ONE * camera_system.zoom
	draw_set_transform(camera_origin, 0.0, camera_scale)
	draw_texture_rect(texture, WORLD, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_exploration_hud(title: String, objective: String) -> void:
	draw_rect(Rect2(18, 16, 530, 86), Color("06101aee"), true)
	draw_string(ThemeDB.fallback_font, Vector2(35, 44), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("bff5ff"))
	draw_wrapped_text(objective, Vector2(35, 69), 70, 16.0, 12, Color.WHITE)
	var nearby := sanctuary_controller.nearest_interaction()
	if not nearby.is_empty() and action_duration <= 0.0:
		draw_rect(Rect2(285, 438, 390, 34), Color("10283cf2"), true)
		draw_string(ThemeDB.fallback_font, Vector2(303, 461), "E / ESPACIO · %s" % interaction_label(nearby), HORIZONTAL_ALIGNMENT_CENTER, 354, 13, Color("ffe5a3"))
	if not notification.is_empty():
		draw_rect(Rect2(145, 480, 670, 42), Color("06101ae8"), true)
		draw_wrapped_text(notification, Vector2(165, 502), 85, 16.0, 13, Color.WHITE)
	draw_vertical_slice_tracker()

func draw_vertical_slice_tracker() -> void:
	var next := VerticalSliceSystem.next_milestone(phase3_state, dungeon_defeated, dungeon_exploration_state, narrative_state)
	var completion := VerticalSliceSystem.completion_percent(phase3_state, dungeon_defeated, dungeon_exploration_state, narrative_state)
	draw_rect(Rect2(650, 104, 290, 48), Color("06101ad9"), true)
	draw_string(ThemeDB.fallback_font, Vector2(664, 122), "RUTA VERTICAL %.0f%%" % completion, HORIZONTAL_ALIGNMENT_LEFT, 260, 11, Color("9ee8d1"))
	draw_string(ThemeDB.fallback_font, Vector2(664, 142), str(next.get("label", "Vertical slice completada")), HORIZONTAL_ALIGNMENT_LEFT, 260, 11, Color.WHITE)

func draw_dialogue() -> void:
	var metadata := dialogue_system.current_metadata()
	var camera_cue := str(metadata.get("camera", ""))
	var camera_offset := Vector2.ZERO
	var camera_zoom := 1.0
	if not active_directed_scene.is_empty():
		if camera_cue == "close_up": camera_zoom = 1.08
		elif camera_cue == "pan_left": camera_offset.x = -18.0 + sin(directed_scene_elapsed * 0.8) * 8.0
		elif camera_cue == "pan_right": camera_offset.x = 18.0 - sin(directed_scene_elapsed * 0.8) * 8.0
		elif camera_cue == "pan_up": camera_offset.y = -14.0
		draw_set_transform(Vector2(480, 270) - Vector2(480, 270) * camera_zoom + camera_offset, 0.0, Vector2.ONE * camera_zoom)
	draw_background_for(dialogue_system.backdrop)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(WORLD, Color(0.01, 0.025, 0.07, 0.34), true)
	if dialogue_system.lines.is_empty():
		return
	var safe_index: int = clampi(dialogue_system.index, 0, dialogue_system.lines.size() - 1)
	var line: Array = dialogue_system.current_pair()
	var speaker: String = str(line[0])
	var text: String = dialogue_system.visible_text()
	var expression := str(metadata.get("expression", "neutral"))
	var expression_animation := "celebrate" if expression in ["happy", "hopeful"] else "special" if expression == "determined" else "hurt" if expression in ["sad", "annoyed"] else "talk"
	var members := HeroStorySystem.active_party(party)
	var spacing: float = 120.0
	var start_x: float = 480.0 - float(members.size() - 1) * spacing * 0.5
	for i in members.size():
		var party_index: int = party.find(members[i])
		var speaking: bool = speaker == str((members[i] as Dictionary).get("name", ""))
		var tint := Color.WHITE if speaking else Color(0.55, 0.62, 0.68, 0.88)
		var movement_offset := Vector2.ZERO
		if not active_directed_scene.is_empty() and not str(metadata.get("movement", "")).is_empty():
			movement_offset.y = -abs(sin(directed_scene_elapsed * 2.2)) * (5.0 if speaking else 1.5)
		draw_shadow(Vector2(start_x + i * spacing, 377), 22.0, 0.5)
		draw_character(PARTY_SHEET, party_index, Vector2(start_x + i * spacing, 377) + movement_offset, Vector2(125, 188), expression_animation if speaking else "idle", tint)
	draw_rect(Rect2(48, 350, 864, 168), Color("050c16f5"), true)
	draw_rect(Rect2(48, 350, 864, 168), Color("d5c47f"), false, 2)
	draw_rect(Rect2(72, 329, 250, 39), Color("13283af8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(88, 355), speaker.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, NarrativeDirectionSystem.expression_color(expression))
	if not metadata.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(325, 355), "%s · %s" % [expression.to_upper(), directed_music_cue.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, 420, 11, Color("8fe8ff"))
		var portrait_ids := {"aren":0, "lyra":1, "brom":2, "seris":3, "naia":4, "kael":5, "mira":6, "orin":7}
		var portrait_id := str(metadata.get("portrait", "")).to_lower()
		var portrait_index := int(portrait_ids.get(portrait_id, -1))
		if portrait_index < 0:
			for member_index in party.size():
				if str((party[member_index] as Dictionary).get("name", "")).to_lower() == speaker.to_lower(): portrait_index = member_index; break
		portrait_index = maxi(0, portrait_index)
		draw_rect(Rect2(66, 378, 91, 111), Color("10283c"), true)
		draw_rect(Rect2(66, 378, 91, 111), Color("ffe5a3"), false, 1.5)
		draw_story_portrait(portrait_index, Vector2(111, 486), Vector2(78, 117), expression_animation, Color("e6c98c") if str(metadata.get("portrait", "")) == "elara" else Color.WHITE)
	var dialogue_text_x := 174.0 if not metadata.is_empty() else 78.0
	draw_wrapped_text(text, Vector2(dialogue_text_x, 399), 78 if not metadata.is_empty() else 92, 21.0, 16, Color.WHITE)
	var choices := narrative_system.current_choices(narrative_state) if not active_directed_scene.is_empty() else []
	if dialogue_system.is_line_revealed() and not choices.is_empty():
		for i in choices.size():
			var selected := i == dialogue_choice_index
			var choice_rect := Rect2(174, 447 + i * 28, 628, 24)
			draw_rect(choice_rect, Color("17354d") if selected else Color("0b1c2b"), true)
			var choice: Dictionary = choices[i] as Dictionary
			var directed_label := str(choice.get("text", "")) + "  " + NarrativeDirectionSystem.choice_hint(choice)
			draw_string(ThemeDB.fallback_font, choice_rect.position + Vector2(8, 17), ("◆ " if selected else "  ") + directed_label, HORIZONTAL_ALIGNMENT_LEFT, 610, 12, Color("ffe5a3") if selected else Color.WHITE)
	var prompt := "Enter: mostrar texto" if not dialogue_system.is_line_revealed() else "Enter: continuar"
	if not choices.is_empty(): prompt = "↑/↓ elegir · Enter confirmar"
	var prompt_y := 511.0 if not choices.is_empty() else 500.0
	draw_string(ThemeDB.fallback_font, Vector2(660, prompt_y), "%s  ◆  %d/%d" % [prompt, safe_index + 1, dialogue_system.lines.size()], HORIZONTAL_ALIGNMENT_LEFT, 230, 11, Color("a8c4d2"))

func draw_battle() -> void:
	draw_texture_rect(VALDORIA_CATACOMBS if battle_context in ["dungeon", "phase9_dungeon"] else WORLD_MAP if battle_context in ["world", "landmark"] else SANCTUARY, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.025, 0.06, 0.66), true)
	if party_battle.is_empty(): return
	var active_member := current_battle_member()
	var active_actor := PartyBattleSystem.current_actor_id(party_battle)
	var allies: Array = party_battle["allies"]
	var living := PartyBattleSystem.living_allies(party_battle)
	var turn_order := PartyBattleSystem.visible_turn_order(party_battle, 7)
	var impact_progress := clampf(battle_impact_time / battle_impact_duration, 0.0, 1.0)
	var reduced_motion := bool((completion_state.get("accessibility", {}) as Dictionary).get("reduced_motion", false))
	var shake_amount := CombatPresentationSystem.shake_amplitude(battle_impact_damage, battle_impact_weak, reduced_motion)
	var impact_shake := CombatPresentationSystem.shake_offset(battle_impact_time, shake_amount) if battle_impact_time < battle_impact_duration else Vector2.ZERO
	# Orden de turnos siempre visible.
	draw_rect(Rect2(18, 10, 924, 36), Color("06101af2"), true)
	draw_string(ThemeDB.fallback_font, Vector2(32, 34), "TURNOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7edcff"))
	for i in turn_order.size():
		var actor_id := str(turn_order[i])
		var label := enemy_name if actor_id == "enemy" else str(PartyBattleSystem.ally_by_actor_id(party_battle, actor_id).get("name", "—"))
		var rect := Rect2(105 + i * 116, 15, 106, 25)
		draw_rect(rect, Color("743846") if actor_id == "enemy" else Color("173f59"), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5, 18), ("◆ " if i == 0 else "") + label, HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color("ffe5a3") if i == 0 else Color.WHITE)
	# Grupo activo y estado de cada miembro.
	for i in allies.size():
		var member: Dictionary = allies[i]
		var x := 94.0 + i * 116.0 + impact_shake.x * 0.25
		var is_active := ally_actor_id_for_ui(member) == active_actor
		var is_target := living.find(member) == battle_target_index
		draw_shadow(Vector2(x, 292), 21.0, 0.52)
		if is_active: draw_arc(Vector2(x, 275), 48.0 + sin(world_time * 5.0) * 2.0, 0, TAU, 32, Color("ffe195"), 3.0)
		if is_target: draw_arc(Vector2(x, 283), 38.0, 0, TAU, 24, Color("79e9ff"), 2.0)
		var member_anim := action_animation if is_active else "idle"
		draw_character(PARTY_SHEET, party.find(member), Vector2(x, 294), Vector2(88, 132), member_anim, Color(0.45, 0.48, 0.52) if int(member["hp"]) <= 0 else Color.WHITE)
		var card := Rect2(x - 52, 303, 104, 76)
		draw_rect(card, Color("07101aef"), true)
		draw_rect(card, Color("ffe195") if is_active else Color("405669"), false, 1.5)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(7, 18), str(member["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 90, 12, Color("ffe5a3"))
		draw_bar(card.position + Vector2(7, 25), Vector2(90, 11), int(member["hp"]), int(member["max_hp"]), Color("4fc279"))
		draw_bar(card.position + Vector2(7, 41), Vector2(90, 10), int(member["mp"]), int(member["max_mp"]), Color("4f91dc"))
		var statuses: Dictionary = (party_battle["ally_statuses"] as Dictionary).get(str(member["id"]), {})
		draw_string(ThemeDB.fallback_font, card.position + Vector2(7, 68), battle_status_text(statuses), HORIZONTAL_ALIGNMENT_LEFT, 92, 10, Color("ff9fa8") if not statuses.is_empty() else Color("8295a3"))
	# Rival, fase de IA, afinidades y ruptura.
	var enemy_anchor := Vector2(730, 350) + impact_shake
	draw_shadow(enemy_anchor - Vector2(0, 20), 58.0, 0.58)
	if battle_context == "dungeon":
		var enemy_size := Vector2(300, 300) if str(enemy_data.get("rank", "normal")) == "boss" else Vector2(255, 285)
		GameUI.grid_sprite(self, PHASE3_ENEMY_SHEET, int(enemy_data.get("sprite_index", 0)), enemy_anchor, enemy_size, enemy_animation, world_time, action_time, Color(1.0, 0.58, 0.58) if enemy_animation == "hurt" else Color.WHITE)
	else:
		draw_character(ENEMY_SHEET, encounter_index + 1, enemy_anchor - Vector2(0, 5), Vector2(235, 315), enemy_animation, Color(1.0, 0.58, 0.58) if enemy_animation == "hurt" else Color.WHITE)
	if battle_impact_time < battle_impact_duration and (battle_impact_damage > 0 or battle_impact_element == "light"):
		var effect_size := Vector2.ONE * lerpf(76.0, 184.0, sin(impact_progress * PI))
		var effect_region := GameUI.grid_source(ELEMENTAL_VFX, CombatPresentationSystem.effect_frame(battle_impact_element, impact_progress), 4, 4)
		var effect_rect := Rect2(enemy_anchor - effect_size * Vector2(0.5, 0.72), effect_size)
		draw_texture_rect_region(ELEMENTAL_VFX, effect_rect, effect_region, Color(1, 1, 1, 1.0 - impact_progress * 0.55))
		if battle_impact_damage > 0:
			var damage_position := enemy_anchor + Vector2(-65, -118 - impact_progress * 34.0)
			draw_string(ThemeDB.fallback_font, damage_position, ("¡RUPTURA! " if battle_impact_weak else "") + str(battle_impact_damage), HORIZONTAL_ALIGNMENT_CENTER, 130, 24 if battle_impact_weak else 20, CombatPresentationSystem.color(battle_impact_element))
	draw_rect(Rect2(548, 55, 394, 102), Color("07101aef"), true)
	draw_string(ThemeDB.fallback_font, Vector2(564, 78), "%s · FASE %d" % [enemy_name.to_upper(), int(party_battle["enemy_phase"])], HORIZONTAL_ALIGNMENT_LEFT, 360, 15, Color("ffb3b3"))
	draw_bar(Vector2(564, 88), Vector2(356, 14), enemy_hp, enemy_max_hp, Color("d85163"))
	draw_string(ThemeDB.fallback_font, Vector2(564, 121), "RUPTURA %d/%d · INTENCIÓN %s" % [int(party_battle["shield"]), int(party_battle["shield_max"]), enemy_intent.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, 356, 11, Color("ffe09a"))
	draw_string(ThemeDB.fallback_font, Vector2(564, 143), "Débil: %s  ·  Resiste: %s" % [", ".join(enemy_data.get("weaknesses", [])), ", ".join(enemy_data.get("resistances", []))], HORIZONTAL_ALIGNMENT_LEFT, 356, 11, Color("9edff4"))
	var enemy_statuses: Dictionary = party_battle["enemy_statuses"]
	if not enemy_statuses.is_empty(): draw_string(ThemeDB.fallback_font, Vector2(580, 172), battle_status_text(enemy_statuses), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ff9fa8"))
	if str(enemy_data.get("rank", "normal")) == "boss":
		draw_rect(Rect2(548, 162, 394, 30), Color("2b1021e8"), true)
		draw_string(ThemeDB.fallback_font, Vector2(560, 182), VerticalSliceSystem.boss_directive(int(party_battle["enemy_phase"]), int(party_battle["shield"])), HORIZONTAL_ALIGNMENT_LEFT, 372, 11, Color("ffd3a1"))
	# Registro, Resonancia y ocho comandos.
	draw_rect(Rect2(18, 389, 924, 143), Color("06101af5"), true)
	draw_rect(Rect2(18, 389, 924, 143), Color("d5c47f"), false, 2)
	draw_wrapped_text(notification, Vector2(34, 410), 112, 16.0, 12, Color.WHITE)
	var resonance := int(party_battle["resonance"])
	draw_string(ThemeDB.fallback_font, Vector2(708, 412), "RESONANCIA  %s" % ("◆".repeat(resonance) + "◇".repeat(PartyBattleSystem.MAX_RESONANCE - resonance)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7eeaff"))
	for i in BATTLE_COMMANDS.size():
		var column := i % 4
		var row := i / 4
		var command_rect := Rect2(34 + column * 226, 454 + row * 34, 214, 28)
		var selected := i == battle_command_index
		var enabled := not (i == 6 and resonance < PartyBattleSystem.COMBO_COST)
		draw_rect(command_rect, Color("17435b") if selected else Color("0b1d2b"), true)
		draw_string(ThemeDB.fallback_font, command_rect.position + Vector2(9, 20), "%d · %s" % [i + 1, BATTLE_COMMANDS[i]], HORIZONTAL_ALIGNMENT_LEFT, 190, 13, Color("ffe5a3") if selected and enabled else Color.WHITE if enabled else Color("596873"))
	var target_name := str(living[battle_target_index]["name"]) if not living.is_empty() and battle_target_index < living.size() else "—"
	draw_string(ThemeDB.fallback_font, Vector2(34, 526), "↑/↓ comando · ←/→ objetivo: %s · Actúa: %s" % [target_name, str(active_member.get("name", "—"))], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9ab5c4"))

func ally_actor_id_for_ui(member: Dictionary) -> String:
	return PartyBattleSystem.ally_actor_id(member)

func battle_status_text(statuses: Dictionary) -> String:
	if statuses.is_empty(): return "SIN ESTADOS"
	var labels: Array[String] = []
	var names := {"poison":"VEN", "silence":"SIL", "sleep":"SUE", "fear":"MIE", "blind":"CIE", "regeneration":"REG"}
	for status_id in statuses:
		labels.append("%s:%d" % [str(names.get(status_id, status_id)).to_upper(), int((statuses[status_id] as Dictionary).get("turns", 0))])
	return " ".join(labels)

func draw_game_menu() -> void:
	if menu_return_state == "city":
		draw_texture_rect(city_texture(current_city), WORLD, false)
	elif menu_return_state == "explore":
		draw_texture_rect(SANCTUARY, WORLD, false)
	elif menu_return_state == "valdoria_explore":
		draw_texture_rect(CITY_VALDORIA, WORLD, false)
	elif menu_return_state == "dungeon":
		draw_texture_rect(VALDORIA_CATACOMBS, WORLD, false)
	elif menu_return_state == "dungeon_crawl":
		draw_texture_rect(VALDORIA_CATACOMBS, WORLD, false)
	else:
		draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.015, 0.03, 0.07, 0.88), true)
	draw_rect(Rect2(30, 24, 900, 492), Color("07101af2"), true)
	draw_rect(Rect2(30, 24, 900, 492), Color("d5c47f"), false, 2)
	for i in MENU_TABS.size():
		var tab_rect := Rect2(48 + i * 122, 43, 114, 40)
		draw_rect(tab_rect, Color("17354d") if i == menu_tab else Color("0c1d2c"), true)
		draw_string(ThemeDB.fallback_font, tab_rect.position + Vector2(5, 26), MENU_TABS[i], HORIZONTAL_ALIGNMENT_CENTER, 104, 11, Color("ffe5a3") if i == menu_tab else Color("91a7b6"))
	match menu_tab:
		0:
			draw_inventory_menu()
		1:
			draw_equipment_menu()
		2:
			draw_advancement_menu()
		3:
			draw_party_menu()
		4:
			draw_journal_menu()
		5:
			draw_extras_menu()
		6:
			draw_system_menu()
	draw_string(ThemeDB.fallback_font, Vector2(60, 494), "←/→ pestaña · ↑/↓ seleccionar · Enter aceptar · M/Esc cerrar", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))
	if notification_time > 0.0:
		draw_rect(Rect2(590, 455, 315, 34), Color("16364cf2"), true)
		draw_string(ThemeDB.fallback_font, Vector2(607, 478), notification, HORIZONTAL_ALIGNMENT_LEFT, 280, 13, Color("bff5ff"))

func draw_inventory_menu() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(58, 119), "OBJETOS Y RELIQUIAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(730, 119), "ORO  %d" % gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffd46b"))
	var keys := inventory.keys()
	if keys.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(70, 170), "El inventario está vacío.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		return
	menu_index = clampi(menu_index, 0, keys.size() - 1)
	for i in keys.size():
		var item: Dictionary = inventory[keys[i]] as Dictionary
		var selected := i == menu_index
		draw_rect(Rect2(58, 145 + i * 35, 385, 29), Color("17354d") if selected else Color(0, 0, 0, 0), true)
		draw_string(ThemeDB.fallback_font, Vector2(70, 166 + i * 35), ("◆ " if selected else "  ") + str(keys[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(388, 166 + i * 35), "×%d" % int(item["quantity"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("8fe8ff"))
	var selected_item: Dictionary = inventory[keys[menu_index]] as Dictionary
	draw_rect(Rect2(485, 145, 405, 235), Color("0b1c2bd9"), true)
	draw_string(ThemeDB.fallback_font, Vector2(510, 182), str(keys[menu_index]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe5a3"))
	draw_wrapped_text(str(selected_item["description"]), Vector2(510, 220), 48, 23.0, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(510, 345), "Enter: usar sobre el miembro seleccionado", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

func draw_party_menu() -> void:
	var members := joined_party()
	if members.is_empty(): return
	menu_index = clampi(menu_index, 0, members.size() - 1)
	for i in members.size():
		var member: Dictionary = members[i] as Dictionary
		var selected := i == menu_index
		var y := 114.0 + i * 42.0
		draw_rect(Rect2(58, y, 420, 35), Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, Vector2(72, y + 23), ("◆ " if selected else "  ") + str(member["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 150, 14, Color("ffe5a3") if selected else Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(235, y + 23), "ACTIVO" if bool(member.get("active", false)) else "RESERVA", HORIZONTAL_ALIGNMENT_LEFT, 82, 12, Color("86efb2") if bool(member.get("active", false)) else Color("8797a5"))
		draw_string(ThemeDB.fallback_font, Vector2(325, y + 23), "Nv %d · PV %d/%d" % [int(member["level"]), int(member["hp"]), int(member["max_hp"])], HORIZONTAL_ALIGNMENT_LEFT, 140, 12, Color("bfe9ff"))
	var selected_member: Dictionary = members[menu_index]
	var selected_index := party.find(selected_member)
	draw_rect(Rect2(510, 113, 380, 330), Color("0b1c2bd9"), true)
	draw_rect(Rect2(510, 113, 380, 330), Color("d5c47f"), false, 2)
	draw_shadow(Vector2(700, 323), 30.0, 0.5)
	draw_story_portrait(selected_index, Vector2(700, 330), Vector2(190, 250), "talk")
	draw_string(ThemeDB.fallback_font, Vector2(535, 355), "%s · %s" % [str(selected_member["name"]).to_upper(), selected_member["role"]], HORIZONTAL_ALIGNMENT_LEFT, 330, 16, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(535, 382), "PV %d/%d · PM %d/%d" % [int(selected_member["hp"]), int(selected_member["max_hp"]), int(selected_member["mp"]), int(selected_member["max_mp"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(535, 405), "ATQ %d · DEF %d · MAG %d · VEL %d" % [int(selected_member["attack"]), int(selected_member["defense"]), int(selected_member["magic"]), int(selected_member["speed"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(535, 428), "Exploración: %s" % DungeonExplorationSystem.ability_name(str(selected_member.get("exploration_ability", ""))), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9ee8d1"))
	draw_string(ThemeDB.fallback_font, Vector2(58, 477), "Enter: alternar grupo activo · máximo 4 · las reservas también ganan EXP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

func draw_equipment_menu() -> void:
	var member := phase5_selected_member()
	var character_id := str(member.get("id", ""))
	var rows := ["PERSONAJE", "ARMA", "ARMADURA", "ACCESORIO", "FABRICAR", "MEJORAR ARMA"]
	draw_string(ThemeDB.fallback_font, Vector2(58, 115), "EQUIPO Y TALLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(745, 115), "ORO %d" % gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffd46b"))
	for i in rows.size():
		var selected := i == menu_index
		var value := ""
		if i == 0: value = str(member.get("name", "—"))
		elif i >= 1 and i <= 3:
			var equipment_id := EquipmentSystem.equipped_id(equipment_state, character_id, EquipmentSystem.SLOTS[i - 1])
			var item := GameDatabase.equipment_by_id(equipment_id)
			value = item.display_name if item != null else "—"
		elif i == 4:
			var recipes: Array = equipment_state.get("recipes_unlocked", [])
			if not recipes.is_empty():
				var recipe_item := GameDatabase.equipment_by_id(str(recipes[workshop_recipe_index % recipes.size()]))
				value = recipe_item.display_name if recipe_item != null else "—"
		else:
			var weapon_id := EquipmentSystem.equipped_id(equipment_state, character_id, "weapon")
			var upgrade := int((equipment_state.get("owned", {}) as Dictionary).get(weapon_id, {}).get("upgrade", 0))
			value = "+%d" % upgrade
		var rect := Rect2(58, 137 + i * 48, 420, 39)
		draw_rect(rect, Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 25), ("◆ " if selected else "  ") + rows[i], HORIZONTAL_ALIGNMENT_LEFT, 165, 14, Color("ffe5a3") if selected else Color.WHITE)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(180, 25), value, HORIZONTAL_ALIGNMENT_LEFT, 225, 14, Color("8fe8ff"))
	draw_rect(Rect2(505, 137, 385, 300), Color("0b1c2bd9"), true)
	draw_string(ThemeDB.fallback_font, Vector2(528, 169), "ESTADÍSTICAS EFECTIVAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(528, 202), "PV %d  PM %d" % [int(member["max_hp"]), int(member["max_mp"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(528, 229), "ATQ %d  DEF %d  MAG %d  VEL %d" % [int(member["attack"]), int(member["defense"]), int(member["magic"]), int(member["speed"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	if menu_index >= 1 and menu_index <= 3:
		var slot_id: String = EquipmentSystem.SLOTS[menu_index - 1]
		var options := EquipmentSystem.compatible_available(equipment_state, character_id, slot_id)
		if not options.is_empty():
			var current := EquipmentSystem.equipped_id(equipment_state, character_id, slot_id)
			var candidate_id := str(options[wrapi(options.find(current) + 1, 0, options.size())])
			var candidate := GameDatabase.equipment_by_id(candidate_id)
			var comparison := EquipmentSystem.preview(equipment_state, member, candidate_id)
			draw_string(ThemeDB.fallback_font, Vector2(528, 277), "SIGUIENTE: %s · %s" % [candidate.display_name, candidate.rarity_name()], HORIZONTAL_ALIGNMENT_LEFT, 335, 14, Color("9fe7c0"))
			var delta_text: Array[String] = []
			for stat in EquipmentSystem.STAT_KEYS:
				var delta := int((comparison.get("delta", {}) as Dictionary).get(stat, 0))
				if delta != 0: delta_text.append("%s %+d" % [stat.to_upper(), delta])
			draw_wrapped_text(" · ".join(delta_text), Vector2(528, 309), 44, 19.0, 13, Color("8fe8ff"))
	if menu_index == 4:
		var recipes: Array = equipment_state.get("recipes_unlocked", [])
		if not recipes.is_empty():
			var recipe := GameDatabase.equipment_by_id(str(recipes[workshop_recipe_index % recipes.size()]))
			draw_string(ThemeDB.fallback_font, Vector2(528, 277), "RECETA · %d ORO" % recipe.craft_gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9fe7c0"))
			draw_wrapped_text(str(recipe.recipe), Vector2(528, 309), 44, 19.0, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(528, 408), "Enter cambia, fabrica o mejora.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

func draw_advancement_menu() -> void:
	var member := phase5_selected_member(true)
	var character_id := str(member.get("id", ""))
	var progress := AdvancementSystem.member_state(advancement_state, character_id)
	var job_id := str(progress.get("secondary_job", "none"))
	var skill_id := AdvancementSystem.selected_skill(advancement_state, character_id)
	var formation_id := str(advancement_state.get("formation", "balanced"))
	var rows := [
		["PERSONAJE", member.get("name", "—")],
		["TRABAJO SECUNDARIO", AdvancementSystem.JOBS[job_id]["name"]],
		["APRENDER TALENTO", "%d puntos" % int(progress.get("talent_points", 0))],
		["ARTE ACTIVA", AdvancementSystem.SKILLS[skill_id]["name"]],
		["FORMACIÓN", AdvancementSystem.FORMATIONS[formation_id]["name"]]
	]
	draw_string(ThemeDB.fallback_font, Vector2(58, 115), "PROGRESIÓN DEL GRUPO", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(700, 115), "PT %d" % int(progress.get("job_points", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("8fe8ff"))
	for i in rows.size():
		var selected := i == menu_index
		var rect := Rect2(58, 145 + i * 52, 440, 42)
		draw_rect(rect, Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 27), ("◆ " if selected else "  ") + str(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, 210, 14, Color("ffe5a3") if selected else Color.WHITE)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(225, 27), str(rows[i][1]), HORIZONTAL_ALIGNMENT_LEFT, 205, 14, Color("8fe8ff"))
	draw_rect(Rect2(525, 145, 360, 287), Color("0b1c2bd9"), true)
	draw_string(ThemeDB.fallback_font, Vector2(548, 177), "ÁRBOL DE TALENTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a3"))
	var y := 213.0
	for talent in AdvancementSystem.TALENT_TREES.get(character_id, []):
		var learned := str(talent["id"]) in (progress.get("talents", []) as Array)
		draw_string(ThemeDB.fallback_font, Vector2(550, y), ("◆ " if learned else "◇ ") + str(talent["name"]) + " · %d PT" % int(talent["cost"]), HORIZONTAL_ALIGNMENT_LEFT, 315, 14, Color("9fe7c0") if learned else Color.WHITE)
		y += 34.0
	draw_string(ThemeDB.fallback_font, Vector2(548, 336), "Bonificaciones de formación", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("7edcff"))
	draw_wrapped_text(str(AdvancementSystem.FORMATIONS[formation_id]["bonuses"]), Vector2(548, 367), 39, 18.0, 13, Color.WHITE)

func draw_journal_menu() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(62, 119), "DIARIO Y CÓDICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe5a3"))
	var entries := journal_menu_entries()
	menu_index = clampi(menu_index, 0, maxi(0, entries.size() - 1))
	var first_visible := maxi(0, menu_index - 5)
	var last_visible := mini(entries.size(), first_visible + 6)
	var y := 150.0
	for i in range(first_visible, last_visible):
		var entry: Dictionary = entries[i]
		var selected := i == menu_index
		draw_rect(Rect2(58, y - 22, 430, 40), Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, Vector2(72, y + 3), ("◆ " if selected else "  ") + str(entry["title"]), HORIZONTAL_ALIGNMENT_LEFT, 280, 14, Color("ffe5a3") if selected else Color.WHITE)
		var status := str(entry["status"])
		draw_string(ThemeDB.fallback_font, Vector2(368, y + 3), status.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 105, 12, Color("9fe7c0") if status == "completed" else Color("8fe8ff"))
		y += 48.0
	draw_rect(Rect2(515, 128, 375, 310), Color("0b1c2bd9"), true)
	if not entries.is_empty():
		var selected_entry: Dictionary = entries[menu_index]
		draw_string(ThemeDB.fallback_font, Vector2(538, 163), str(selected_entry["title"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 325, 16, Color("ffe5a3"))
		draw_wrapped_text(str(selected_entry["objective"]), Vector2(538, 198), 41, 19.0, 14, Color.WHITE)
		if str(selected_entry.get("entry_type", "quest")) == "quest":
			draw_string(ThemeDB.fallback_font, Vector2(538, 350), "Enter: iniciar misión personal disponible", HORIZONTAL_ALIGNMENT_LEFT, 325, 12, Color("a8c4d2"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(538, 350), "Entrada del códice · %s" % selected_entry.get("category", ""), HORIZONTAL_ALIGNMENT_LEFT, 325, 12, Color("7edcff"))
	draw_string(ThemeDB.fallback_font, Vector2(538, 402), "CÓDICE DESBLOQUEADO · %d/%d" % [narrative_system.codex_entries(narrative_state).size(), (narrative_system.data.get("codex", {}) as Dictionary).size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7edcff"))
	draw_string(ThemeDB.fallback_font, Vector2(62, 465), "Objetivo de Valdoria: %s" % QuestSystem.objective(phase3_state), HORIZONTAL_ALIGNMENT_LEFT, 820, 12, Color("a8c4d2"))

func draw_system_menu() -> void:
	var hours: int = int(play_seconds) / 3600
	var minutes: int = (int(play_seconds) / 60) % 60
	draw_string(ThemeDB.fallback_font, Vector2(62, 125), "SISTEMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(650, 125), "Tiempo %02d:%02d" % [hours, minutes], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("a8c4d2"))
	var options := ["GUARDAR PARTIDA", "CARGAR PARTIDA", "AJUSTES", "VOLVER AL JUEGO", "SALIR AL MENÚ PRINCIPAL"]
	for i in options.size():
		var selected := i == menu_index
		draw_rect(Rect2(82, 155 + i * 54, 520, 42), Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, Vector2(105, 182 + i * 54), ("◆ " if selected else "  ") + options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe5a3") if selected else Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(82, 445), "3 ranuras manuales · autoguardado · recuperación desde copia de seguridad", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

func draw_extras_menu() -> void:
	var rows := ["BESTIARIO", "MERCADO", "FACCIONES", "ARENA DE LOS ECOS", "DIFICULTAD", "ACCESIBILIDAD", "IDIOMA Y CRÉDITOS"]
	draw_string(ThemeDB.fallback_font, Vector2(58, 116), "CRÓNICAS ADICIONALES", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("ffe5a3"))
	for i in rows.size():
		var selected := i == menu_index
		var rect := Rect2(58, 136 + i * 43, 390, 35)
		draw_rect(rect, Color("17354d") if selected else Color("0b1c2b"), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 23), ("◆ " if selected else "  ") + rows[i], HORIZONTAL_ALIGNMENT_LEFT, 360, 14, Color("ffe5a3") if selected else Color.WHITE)
	draw_rect(Rect2(480, 128, 410, 320), Color("0b1c2bd9"), true)
	draw_rect(Rect2(480, 128, 410, 320), Color("d5c47f"), false, 2)
	var scanned := 0
	for record in (bestiary_state.get("records", {}) as Dictionary).values():
		if record is Dictionary and bool(record.get("scanned", false)): scanned += 1
	var market_city := current_city if current_city in CommerceSystem.CITIES else "valdoria"
	var market_products := CommerceSystem.stock(commerce_state, market_city)
	var market_text := "Sin existencias"
	if not market_products.is_empty():
		var product: Dictionary = market_products[extras_market_index % market_products.size()]
		market_text = "%s · %d oro · quedan %d" % [product["id"], CommerceSystem.price(commerce_state, market_city, product), product["quantity"]]
	var lines := [
		"BESTIARIO  %d/32 · %.1f%%" % [scanned, BestiarySystem.completion_percent(bestiary_state)],
		"MERCADO DE %s" % market_city.to_upper(), market_text,
		"FACCIONES  %d/24 encargos" % (faction_state.get("completed", []) as Array).size(),
		"ARENA  prueba %d/25 · %d superjefes" % [int(endgame_state.get("arena_floor", 1)), (endgame_state.get("superbosses_defeated", []) as Array).size()],
		"DIFICULTAD  %s" % EndgameSystem.DIFFICULTIES[str(endgame_state.get("difficulty", "standard"))]["name"],
		"LOGROS  %d/40 · IDIOMA %s" % [(completion_state.get("unlocked", []) as Array).size(), str(completion_state.get("language", "es")).to_upper()]
	]
	var y := 166.0
	for line in lines:
		draw_string(ThemeDB.fallback_font, Vector2(505, y), str(line), HORIZONTAL_ALIGNMENT_LEFT, 360, 14, Color("8fe8ff") if y < 220 else Color.WHITE)
		y += 34.0
	draw_wrapped_text("Enter ejecuta la opción. El mercado rota tras cada compra; la arena se abre al completar el final común.", Vector2(505, 398), 45, 16.0, 12, Color("a8c4d2"))

func draw_victory() -> void:
	draw_texture_rect(SANCTUARY, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.03, 0.08, 0.68), true)
	for radius in [75.0, 125.0, 180.0]:
		draw_circle(Vector2(480, 235), radius + sin(world_time * 2.0) * 5.0, Color(0.2, 0.75, 1.0, 0.05))
	for i in party.size():
		var row := i / 4
		var column := i % 4
		draw_character(PARTY_SHEET, i, Vector2(300 + column * 120, 350 + row * 115), Vector2(78, 117), "celebrate")
	draw_rect(Rect2(170, 92, 620, 190), Color("07101af2"), true)
	draw_rect(Rect2(170, 92, 620, 190), Color("74e9ff"), false, 3)
	var vertical_complete := bool((narrative_state.get("variables", {}) as Dictionary).get("vertical_slice_complete", false))
	draw_string(ThemeDB.fallback_font, Vector2(250 if vertical_complete else 295, 150), "DEMO VERTICAL COMPLETADA" if vertical_complete else "EL JURAMENTO RESTAURADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("baf6ff"))
	var victory_text := "Valdoria recuerda sus nombres y Eira vuelve a escuchar. El camino hacia la Corona Hueca queda abierto." if vertical_complete else "Eryndor conserva sus recuerdos. La corona deja de pertenecer a un rey y vuelve a ser la promesa de todos sus pueblos."
	draw_wrapped_text(victory_text, Vector2(228, 194), 66, 23.0, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(343, 264), "Pulsa ENTER para volver al título", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe5a3"))

func draw_notification() -> void:
	if notification_time <= 0.0 or game_state in ["city", "explore", "valdoria_explore", "dungeon", "dungeon_crawl", "game_menu", "battle"]:
		return
	draw_rect(Rect2(610, 482, 325, 38), Color("10283cf2"), true)
	draw_string(ThemeDB.fallback_font, Vector2(627, 507), notification, HORIZONTAL_ALIGNMENT_LEFT, 290, 13, Color("bff5ff"))

func _draw() -> void:
	match game_state:
		"title":
			draw_title()
		"settings":
			draw_settings()
		"save_menu":
			draw_slot_menu(true)
		"load_menu":
			draw_slot_menu(false)
		"world_map":
			draw_world_map()
		"city":
			draw_city()
		"landmark":
			draw_landmark()
		"dialogue":
			draw_dialogue()
		"explore":
			draw_sanctuary()
		"valdoria_explore":
			draw_valdoria_exploration()
		"dungeon":
			draw_dungeon()
		"dungeon_crawl":
			draw_dungeon_crawl()
		"battle":
			draw_battle()
		"game_menu":
			draw_game_menu()
		"victory":
			draw_victory()
	draw_notification()
	if scene_router.transition_alpha > 0.0:
		draw_rect(WORLD, Color(0.0, 0.0, 0.0, scene_router.transition_alpha), true)
