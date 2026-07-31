extends Node2D

const WORLD := Rect2(0, 0, 960, 540)
const HERO_SPEED := 215.0
const PARTY_SHEET: Texture2D = preload("res://assets/party_characters.png")
const PARTY_ANIMATION_ATLAS: Texture2D = preload("res://assets/party_animation_atlas.png")
const ENEMY_SHEET: Texture2D = preload("res://assets/characters.png")
const PHASE3_ENEMY_SHEET: Texture2D = preload("res://assets/phase3_enemies.png")
const SANCTUARY: Texture2D = preload("res://assets/forest_sanctuary_hd2d.png")
const VALDORIA_CATACOMBS: Texture2D = preload("res://assets/valdoria_catacombs_hd2d.png")
const WORLD_MAP: Texture2D = preload("res://assets/world_map_eryndor.png")
const CITY_VALDORIA: Texture2D = preload("res://assets/city_valdoria.png")
const CITY_BRUMAFORJA: Texture2D = preload("res://assets/city_brumaforja.png")
const CITY_CELESTIA: Texture2D = preload("res://assets/city_celestia.png")
const CITY_SYLVARAN: Texture2D = preload("res://assets/city_sylvaran.png")

const TITLE_OPTIONS := ["NUEVA PARTIDA", "CARGAR PARTIDA", "AJUSTES", "SALIR"]
const CITY_ACTIONS := ["HABLAR CON LOS HABITANTES", "DESCANSAR EN LA POSADA", "COMPRAR SUMINISTROS · 15 ORO", "PARTIR AL MAPA MUNDIAL"]
const MENU_TABS := ["INVENTARIO", "GRUPO", "DIARIO", "SISTEMA"]
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
var camera_system := CameraSystem.new()
var sanctuary_controller: SanctuaryController
var locations: Array = []
var save_base_dir := SaveSystem.SAVE_DIR
var menu_return_state := "world_map"
var title_index := 0
var city_action_index := 0
var map_index := 0
var menu_tab := 0
var menu_index := 0
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
var party_battle: Dictionary = {}
var battle_command_index := 0
var battle_target_index := 0
var resonance_tutorial_seen := false

var current_location := "valdoria"
var current_city := "valdoria"
var unlocked_locations: Array = []
var visited_cities: Dictionary = {}
var city_dialogue_progress: Dictionary = {}
var chapter := 0
var gold := 85

var party: Array = []
var inventory: Dictionary = {}

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
	locations = GameDatabase.locations()
	settings_manager.load_settings()
	initialize_empty_game()
	var database_errors := GameDatabase.validate()
	if not database_errors.is_empty():
		GameLogger.error("database", "Game database validation failed", {"errors": database_errors})
	GameLogger.info("startup", "Game initialized", {"dialogues": StoryData.dialogue_count(), "locations": locations.size()})
	queue_redraw()

func configure_viewport_scaling() -> void:
	var root_window := get_window()
	root_window.content_scale_size = Vector2i(int(WORLD.size.x), int(WORLD.size.y))
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

func initialize_empty_game() -> void:
	party = GameDatabase.create_party()
	inventory = GameDatabase.create_initial_inventory()

func new_game() -> void:
	initialize_empty_game()
	current_location = "valdoria"
	current_city = "valdoria"
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
	if sanctuary_controller != null:
		sanctuary_controller.set_player_position(hero_position)
		sanctuary_controller.facing_direction = facing_direction
	camera_system.snap(hero_position)
	start_dialogue(StoryData.get_story_lines(0), "world_map", "intro", "sanctuary")

func _process(delta: float) -> void:
	world_time += delta
	scene_router.update(delta)
	if sanctuary_controller != null:
		sanctuary_controller.set_active(game_state in ["explore", "valdoria_explore", "dungeon"] and action_duration <= 0.0)
		sanctuary_controller.update_animation(delta)
	npc_animation_elapsed += delta
	if game_state == "dialogue":
		dialogue_system.update(delta, settings_manager.text_characters_per_second())
	if game_state != "title":
		play_seconds += delta
	if notification_time > 0.0:
		notification_time = maxf(0.0, notification_time - delta)
	if action_duration > 0.0:
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
	if event.is_action_pressed("ui_up"):
		title_index = wrapi(title_index - 1, 0, TITLE_OPTIONS.size())
	elif event.is_action_pressed("ui_down"):
		title_index = wrapi(title_index + 1, 0, TITLE_OPTIONS.size())
	elif event.is_action_pressed("ui_accept"):
		match title_index:
			0:
				new_game()
			1:
				open_load_menu("title")
			2:
				open_settings("title")
			3:
				get_tree().quit()

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
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		map_index = wrapi(map_index - 1, 0, locations.size())
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		map_index = wrapi(map_index + 1, 0, locations.size())
	elif event.is_action_pressed("ui_accept") and action_animation != "travel":
		var destination: String = str(locations[map_index]["id"])
		if TravelSystem.can_travel(unlocked_locations, destination):
			start_travel(destination)
		else:
			show_notification("Este destino permanece oculto por la bruma.")

func handle_city_input(event: InputEvent) -> void:
	if is_menu_event(event):
		open_game_menu("city")
	elif event.is_action_pressed("ui_up"):
		city_action_index = wrapi(city_action_index - 1, 0, CITY_ACTIONS.size())
	elif event.is_action_pressed("ui_down"):
		city_action_index = wrapi(city_action_index + 1, 0, CITY_ACTIONS.size())
	elif event.is_action_pressed("ui_accept"):
		match city_action_index:
			0:
				begin_city_conversation()
			1:
				rest_at_inn()
			2:
				buy_supplies()
			3:
				current_location = current_city
				game_state = "world_map"
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
			return maxi(1, joined_party().size())
		2:
			return 1
		3:
			return 5
	return 1

func activate_menu_item() -> void:
	if menu_tab == 0:
		use_selected_item()
	elif menu_tab == 3:
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

func finish_dialogue() -> void:
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

func complete_city_chapter(city_id: String) -> void:
	visited_cities[city_id] = true
	match city_id:
		"valdoria":
			chapter = 2
			party[1]["joined"] = true
			unlock_location("brumaforja")
			add_item("Sello de Valdoria", "Fragmento de la Corona de Ámbar hallado bajo la fuente del león.", 1)
		"brumaforja":
			chapter = 3
			party[2]["joined"] = true
			unlock_location("celestia")
			add_item("Runa de la Fragua", "Metal vivo que conserva el juramento de los primeros thanes.", 1)
		"celestia":
			chapter = 4
			unlock_location("sylvaran")
			add_item("Lente astral", "Cristal de faro capaz de revelar recuerdos borrados.", 1)
		"sylvaran":
			chapter = 5
			party[3]["joined"] = true
			unlock_location("sanctuary")
			add_item("Nombre de Eira", "Una hoja de plata que guarda el nombre verdadero de la guardiana.", 1)
	show_notification("Nuevo destino y entrada del diario desbloqueados.")
	autosave()
	if city_id == "valdoria":
		enter_valdoria_exploration()

func begin_city_conversation() -> void:
	var all_lines := StoryData.get_city_lines(current_city)
	if all_lines.is_empty():
		return
	var start: int = int(city_dialogue_progress.get(current_city, 0))
	var chunk_result := DialogueSystem.city_chunk(all_lines, start)
	city_dialogue_progress[current_city] = int(chunk_result["next"])
	start_dialogue(chunk_result["lines"] as Array, "city", "city_chat", current_city)

func rest_at_inn() -> void:
	ProgressionSystem.restore_party(party)
	action_animation = "rest"
	action_time = 0.0
	action_duration = 1.1
	show_notification("El grupo descansa. PV y PM restaurados.")
	autosave()

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
	current_location = destination
	if destination == "sanctuary":
		sanctuary_controller.configure_world("sanctuary")
		game_state = "explore"
		hero_position = Vector2(315, 400)
		sanctuary_controller.set_player_position(hero_position)
		camera_system.snap(hero_position)
		show_notification("Has llegado al Santuario de Lúmina.")
	else:
		enter_city(destination)

func enter_city(city_id: String) -> void:
	current_city = city_id
	current_location = city_id
	game_state = "city"
	city_action_index = 0
	var expected_chapter := {"valdoria": 1, "brumaforja": 2, "celestia": 3, "sylvaran": 4}
	if int(expected_chapter.get(city_id, -1)) == chapter and not bool(visited_cities.get(city_id, false)):
		if city_id == "valdoria":
			party[1]["joined"] = true
		elif city_id == "brumaforja":
			party[2]["joined"] = true
		elif city_id == "sylvaran":
			party[3]["joined"] = true
		start_dialogue(StoryData.get_story_lines(chapter), "city", "story_" + city_id, city_id)
	else:
		if city_id == "valdoria":
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

func initialize_party_battle() -> void:
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
	match str(party_battle.get("outcome", "ongoing")):
		"victory": queued_defeat = true
		"defeat": handle_party_defeat()
		"fled": handle_battle_flee()
	battle_target_index = clampi(battle_target_index, 0, maxi(0, PartyBattleSystem.living_allies(party_battle).size() - 1)) if not party_battle.is_empty() else 0

func handle_battle_flee() -> void:
	party_battle = {}
	action_animation = "run"
	game_state = "dungeon" if battle_context == "dungeon" else "explore"
	show_notification("El grupo ha escapado del combate.")

func handle_party_defeat() -> void:
	ProgressionSystem.restore_party(party)
	party_battle = {}
	hero_position = dungeon_position if battle_context == "dungeon" else Vector2(315, 400)
	sanctuary_controller.set_player_position(hero_position)
	camera_system.snap(hero_position)
	game_state = "dungeon" if battle_context == "dungeon" else "explore"
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
		hero_position = dungeon_position if battle_context == "dungeon" else Vector2(315, 400)
		sanctuary_controller.set_player_position(hero_position)
		camera_system.snap(hero_position)
		game_state = "dungeon" if battle_context == "dungeon" else "explore"
		action_animation = "hurt"
		notification = "El cristal devuelve al grupo a salvo." if battle_context == "dungeon" else "La luz del santuario devuelve al grupo a la entrada."

func defeat_enemy() -> void:
	if battle_context == "dungeon":
		defeat_phase3_enemy()
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
	var level_names: Array[String] = []
	for member in joined_party():
		if ProgressionSystem.grant_xp(member as Dictionary, int(enemy_data.get("xp_reward", 0))) > 0:
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
	return {"level_names": level_names, "loot_text": " · Botín: " + ", ".join(loot_names) if not loot_names.is_empty() else ""}

func show_notification(text: String) -> void:
	notification = text
	notification_time = 3.5

func save_payload() -> Dictionary:
	return {
		"save_version": SaveSystem.CURRENT_VERSION,
		"chapter": chapter,
		"gold": gold,
		"play_seconds": play_seconds,
		"current_location": current_location,
		"current_city": current_city,
		"unlocked_locations": unlocked_locations,
		"visited_cities": visited_cities,
		"city_dialogue_progress": city_dialogue_progress,
		"party": party,
		"inventory": inventory,
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
		party = loaded_party as Array
	var loaded_inventory: Variant = data.get("inventory", inventory)
	if loaded_inventory is Dictionary:
		inventory = loaded_inventory as Dictionary
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
	if current_location == "sanctuary":
		sanctuary_controller.configure_world("sanctuary")
		game_state = "explore"
	elif current_location == "valdoria_catacombs":
		sanctuary_controller.configure_world("dungeon")
		hero_position = dungeon_position
		game_state = "dungeon"
	elif current_location == "valdoria":
		sanctuary_controller.configure_world("valdoria")
		hero_position = valdoria_position
		game_state = "valdoria_explore"
	else:
		game_state = "world_map"
	if sanctuary_controller != null:
		sanctuary_controller.set_player_position(hero_position)
		sanctuary_controller.facing_direction = facing_direction
	camera_system.snap(hero_position)
	for i in locations.size():
		if str(locations[i]["id"]) == current_location:
			map_index = i
	var validation_errors := ProgressionSystem.validate_party(party)
	validation_errors.append_array(InventorySystem.validate(inventory))
	validation_errors.append_array(TravelSystem.validate_route(locations, unlocked_locations))
	validation_errors.append_array(QuestSystem.validate(phase3_state))
	if not validation_errors.is_empty():
		GameLogger.error("save", "Loaded state contains validation errors", {"errors": validation_errors})
	else:
		GameLogger.info("save", "Game state loaded", {"chapter": chapter, "location": current_location})
	show_notification("Partida cargada.")

func wrap_text(text: String, max_characters: int) -> Array[String]:
	return GameUI.wrap_text(text, max_characters)

func draw_wrapped_text(text: String, position: Vector2, max_characters: int, line_height: float, font_size: int, color: Color) -> void:
	GameUI.wrapped_text(self, text, position, max_characters, line_height, font_size, color)

func character_source(sheet: Texture2D, character_index: int) -> Rect2:
	return GameUI.character_source(sheet, character_index)

func draw_character(sheet: Texture2D, character_index: int, feet_position: Vector2, display_size: Vector2, animation: String, tint: Color = Color.WHITE) -> void:
	if sheet == PARTY_SHEET:
		var direction := "east" if game_state == "battle" else (facing_direction if game_state in ["explore", "valdoria_explore", "dungeon", "world_map"] else "south")
		var elapsed := action_time if action_duration > 0.0 and CharacterAnimationSystem.validate_state(animation) else world_time
		if animation in ["walk", "run", "travel"]:
			elapsed = walk_time
		GameUI.animated_party_character(self, PARTY_ANIMATION_ATLAS, character_index, feet_position, display_size, animation, direction, elapsed, tint)
	else:
		GameUI.character(self, sheet, character_index, feet_position, display_size, animation, world_time, walk_time, action_time, tint)

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
	draw_rect(Rect2(325, 210, 310, 220), Color("06101ade"), true)
	draw_rect(Rect2(325, 210, 310, 220), Color("cdbb78"), false, 2)
	for i in TITLE_OPTIONS.size():
		var selected := i == title_index
		var color := Color("ffe5a3") if selected else Color("c4d1dc")
		if i == 1 and not has_any_save():
			color = Color("66717d")
		var prefix := "◆ " if selected else "  "
		draw_string(ThemeDB.fallback_font, Vector2(372, 253 + i * 46), prefix + TITLE_OPTIONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, color)
	draw_string(ThemeDB.fallback_font, Vector2(348, 458), "%d diálogos · 3 ranuras · autoguardado" % (StoryData.dialogue_count() + Phase3StoryData.dialogue_count()), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

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

func draw_world_map() -> void:
	draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.03, 0.08, 0.16), true)
	for i in locations.size():
		var location: Dictionary = locations[i] as Dictionary
		var position: Vector2 = location["position"] as Vector2
		var location_id: String = str(location["id"])
		var unlocked := location_id in unlocked_locations
		var selected := i == map_index
		var pulse: float = 5.0 + sin(world_time * 4.0) * 2.0 if selected else 0.0
		draw_circle(position, 18.0 + pulse, Color(0.35, 0.9, 1.0, 0.18) if unlocked else Color(0.08, 0.09, 0.12, 0.72))
		draw_circle(position, 9.0, Color("ffe096") if unlocked else Color("4c5360"))
		if selected:
			draw_arc(position, 29.0 + pulse, 0, TAU, 32, Color("bff5ff"), 3.0)
		var label_color := Color.WHITE if unlocked else Color("7b8490")
		draw_string(ThemeDB.fallback_font, position + Vector2(-58, 43), str(location["name"]), HORIZONTAL_ALIGNMENT_CENTER, 116, 14, label_color)
	var marker_start := location_position(current_location)
	var marker_position := marker_start
	if action_animation == "travel" and not pending_destination.is_empty():
		var travel_ratio: float = ease(clampf(action_time / action_duration, 0.0, 1.0), -1.5)
		marker_position = marker_start.lerp(location_position(pending_destination), travel_ratio)
	marker_position.y -= 25.0 + abs(sin(world_time * 5.0)) * 6.0
	draw_shadow(marker_position + Vector2(0, 18), 10.0, 0.5)
	draw_character(PARTY_SHEET, 0, marker_position + Vector2(0, 18), Vector2(58, 87), "walk" if action_animation == "travel" else "idle")
	draw_rect(Rect2(18, 16, 350, 83), Color("06101ae8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(34, 45), "MAPA MUNDIAL · ERYNDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(34, 72), CHAPTER_TITLES[clampi(chapter, 0, CHAPTER_TITLES.size() - 1)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(34, 91), "Flechas: destino · Enter: viajar · M/Esc: menú", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a8c4d2"))

func draw_city() -> void:
	draw_texture_rect(city_texture(current_city), WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.03, 0.05, 0.08), true)
	var members := joined_party()
	var spacing: float = 115.0
	var start_x: float = 560.0 - float(members.size() - 1) * spacing * 0.5
	for i in members.size():
		var anim := action_animation if action_animation in ["rest", "celebrate", "heal"] else "idle"
		draw_shadow(Vector2(start_x + i * spacing, 426), 20.0, 0.45)
		draw_character(PARTY_SHEET, party.find(members[i]), Vector2(start_x + i * spacing, 426), Vector2(106, 159), anim)
	draw_rect(Rect2(20, 18, 350, 72), Color("06101ae8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(38, 48), location_name(current_city).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe5a3"))
	draw_string(ThemeDB.fallback_font, Vector2(38, 75), "Oro: %d · Capítulo %d · M/Esc: menú" % [gold, chapter], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_rect(Rect2(32, 265, 395, 240), Color("06101aeb"), true)
	draw_rect(Rect2(32, 265, 395, 240), Color("d5c47f"), false, 2)
	for i in CITY_ACTIONS.size():
		var selected := i == city_action_index
		var prefix := "◆ " if selected else "  "
		draw_string(ThemeDB.fallback_font, Vector2(58, 312 + i * 43), prefix + CITY_ACTIONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a3") if selected else Color.WHITE)
	if not notification.is_empty():
		draw_wrapped_text(notification, Vector2(58, 488), 54, 17.0, 13, Color("aeeaff"))

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
			draw_character(PARTY_SHEET, 0, screen_position + Vector2(0, 18) * depth_scale, Vector2(105, 158) * depth_scale, hero_anim)
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
			draw_character(PARTY_SHEET, 0, screen_position + Vector2(0, 10) * depth_scale, Vector2(72, 108) * depth_scale, hero_anim)
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
			draw_character(PARTY_SHEET, 0, screen_position + Vector2(0, 10) * depth_scale, Vector2(72, 108) * depth_scale, hero_anim)
		else:
			var runtime: Dictionary = entry["data"]
			var size := Vector2(102, 102) if str(runtime["rank"]) == "normal" else Vector2(145, 145) if str(runtime["rank"]) == "miniboss" else Vector2(178, 160)
			GameUI.grid_sprite(self, PHASE3_ENEMY_SHEET, int(runtime["sprite_index"]), screen_position + Vector2(0, 10) * depth_scale, size * depth_scale, "idle", world_time, action_time)
	draw_exploration_hud("CATACUMBAS DEL LEÓN DORMIDO", QuestSystem.objective(phase3_state))

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

func draw_dialogue() -> void:
	draw_background_for(dialogue_system.backdrop)
	draw_rect(WORLD, Color(0.01, 0.025, 0.07, 0.34), true)
	if dialogue_system.lines.is_empty():
		return
	var safe_index: int = clampi(dialogue_system.index, 0, dialogue_system.lines.size() - 1)
	var line: Array = dialogue_system.current_pair()
	var speaker: String = str(line[0])
	var text: String = dialogue_system.visible_text()
	var members := joined_party()
	var party_speakers := ["Aren", "Lyra", "Brom", "Seris"]
	var spacing: float = 120.0
	var start_x: float = 480.0 - float(members.size() - 1) * spacing * 0.5
	for i in members.size():
		var party_index: int = party.find(members[i])
		var speaking: bool = speaker == party_speakers[party_index]
		var tint := Color.WHITE if speaking else Color(0.55, 0.62, 0.68, 0.88)
		draw_shadow(Vector2(start_x + i * spacing, 377), 22.0, 0.5)
		draw_character(PARTY_SHEET, party_index, Vector2(start_x + i * spacing, 377), Vector2(125, 188), "talk" if speaking else "idle", tint)
	draw_rect(Rect2(48, 350, 864, 168), Color("050c16f5"), true)
	draw_rect(Rect2(48, 350, 864, 168), Color("d5c47f"), false, 2)
	draw_rect(Rect2(72, 329, 250, 39), Color("13283af8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(88, 355), speaker.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe5a3"))
	draw_wrapped_text(text, Vector2(78, 399), 92, 23.0, 17, Color.WHITE)
	var prompt := "Enter: mostrar texto" if not dialogue_system.is_line_revealed() else "Enter: continuar"
	draw_string(ThemeDB.fallback_font, Vector2(704, 500), "%s  ◆  %d/%d" % [prompt, safe_index + 1, dialogue_system.lines.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a8c4d2"))

func draw_battle() -> void:
	draw_texture_rect(VALDORIA_CATACOMBS if battle_context == "dungeon" else SANCTUARY, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.025, 0.06, 0.66), true)
	if party_battle.is_empty(): return
	var active_member := current_battle_member()
	var active_actor := PartyBattleSystem.current_actor_id(party_battle)
	var allies: Array = party_battle["allies"]
	var living := PartyBattleSystem.living_allies(party_battle)
	var turn_order := PartyBattleSystem.visible_turn_order(party_battle, 7)
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
		var x := 94.0 + i * 116.0
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
	draw_shadow(Vector2(730, 330), 58.0, 0.58)
	if battle_context == "dungeon":
		var enemy_size := Vector2(300, 300) if str(enemy_data.get("rank", "normal")) == "boss" else Vector2(255, 285)
		GameUI.grid_sprite(self, PHASE3_ENEMY_SHEET, int(enemy_data.get("sprite_index", 0)), Vector2(730, 350), enemy_size, enemy_animation, world_time, action_time, Color(1.0, 0.58, 0.58) if enemy_animation == "hurt" else Color.WHITE)
	else:
		draw_character(ENEMY_SHEET, encounter_index + 1, Vector2(730, 345), Vector2(235, 315), enemy_animation, Color(1.0, 0.58, 0.58) if enemy_animation == "hurt" else Color.WHITE)
	draw_rect(Rect2(548, 55, 394, 102), Color("07101aef"), true)
	draw_string(ThemeDB.fallback_font, Vector2(564, 78), "%s · FASE %d" % [enemy_name.to_upper(), int(party_battle["enemy_phase"])], HORIZONTAL_ALIGNMENT_LEFT, 360, 15, Color("ffb3b3"))
	draw_bar(Vector2(564, 88), Vector2(356, 14), enemy_hp, enemy_max_hp, Color("d85163"))
	draw_string(ThemeDB.fallback_font, Vector2(564, 121), "RUPTURA %d/%d · INTENCIÓN %s" % [int(party_battle["shield"]), int(party_battle["shield_max"]), enemy_intent.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, 356, 11, Color("ffe09a"))
	draw_string(ThemeDB.fallback_font, Vector2(564, 143), "Débil: %s  ·  Resiste: %s" % [", ".join(enemy_data.get("weaknesses", [])), ", ".join(enemy_data.get("resistances", []))], HORIZONTAL_ALIGNMENT_LEFT, 356, 11, Color("9edff4"))
	var enemy_statuses: Dictionary = party_battle["enemy_statuses"]
	if not enemy_statuses.is_empty(): draw_string(ThemeDB.fallback_font, Vector2(580, 172), battle_status_text(enemy_statuses), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ff9fa8"))
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
	else:
		draw_texture_rect(WORLD_MAP, WORLD, false)
	draw_rect(WORLD, Color(0.015, 0.03, 0.07, 0.88), true)
	draw_rect(Rect2(30, 24, 900, 492), Color("07101af2"), true)
	draw_rect(Rect2(30, 24, 900, 492), Color("d5c47f"), false, 2)
	for i in MENU_TABS.size():
		var tab_rect := Rect2(48 + i * 216, 43, 200, 40)
		draw_rect(tab_rect, Color("17354d") if i == menu_tab else Color("0c1d2c"), true)
		draw_string(ThemeDB.fallback_font, tab_rect.position + Vector2(19, 27), MENU_TABS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe5a3") if i == menu_tab else Color("91a7b6"))
	match menu_tab:
		0:
			draw_inventory_menu()
		1:
			draw_party_menu()
		2:
			draw_journal_menu()
		3:
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
	menu_index = clampi(menu_index, 0, members.size() - 1)
	for i in members.size():
		var member: Dictionary = members[i] as Dictionary
		var party_index: int = party.find(member)
		var selected := i == menu_index
		var x: float = 82.0 + i * 200.0
		draw_rect(Rect2(x, 115, 175, 320), Color("17354d") if selected else Color("0b1c2b"), true)
		draw_rect(Rect2(x, 115, 175, 320), Color("d5c47f") if selected else Color("405669"), false, 2)
		draw_shadow(Vector2(x + 87, 292), 24.0, 0.5)
		draw_character(PARTY_SHEET, party_index, Vector2(x + 87, 292), Vector2(125, 188), "talk" if selected else "idle")
		draw_string(ThemeDB.fallback_font, Vector2(x + 16, 329), str(member["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe5a3"))
		draw_string(ThemeDB.fallback_font, Vector2(x + 16, 351), str(member["role"]), HORIZONTAL_ALIGNMENT_LEFT, 145, 12, Color("a8c4d2"))
		draw_string(ThemeDB.fallback_font, Vector2(x + 16, 377), "Nv %d  PV %d/%d" % [int(member["level"]), int(member["hp"]), int(member["max_hp"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(x + 16, 398), "PM %d/%d  ATQ %d" % [int(member["mp"]), int(member["max_mp"]), int(member["attack"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(x + 16, 419), "DEF %d  MAG %d  VEL %d" % [int(member["defense"]), int(member["magic"]), int(member["speed"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func draw_journal_menu() -> void:
	var quest := GameDatabase.quest(chapter)
	draw_string(ThemeDB.fallback_font, Vector2(62, 125), "EL LEÓN DESPIERTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("ffe5a3"))
	var objective: String = QuestSystem.objective(phase3_state)
	draw_string(ThemeDB.fallback_font, Vector2(62, 170), "OBJETIVO ACTUAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("7edcff"))
	draw_wrapped_text(objective, Vector2(62, 203), 76, 22.0, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(62, 275), "MISIONES SECUNDARIAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("7edcff"))
	var y := 308.0
	for quest_id in QuestSystem.SIDE_IDS:
		var side: Dictionary = (phase3_state["side"] as Dictionary)[quest_id]
		var status := str(side["status"])
		draw_string(ThemeDB.fallback_font, Vector2(72, y), "◆ %s · %s · %d/%d" % [side_quest_name(quest_id), status.to_upper(), int(side["progress"]), int(side["target"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9fe7c0") if status == "completed" else Color.WHITE)
		y += 30.0
	draw_string(ThemeDB.fallback_font, Vector2(62, 430), "Campaña: %s · Archivo narrativo: %d diálogos · Encargos: %d/3" % [quest.title, StoryData.dialogue_count() + Phase3StoryData.dialogue_count(), (phase3_state["rewarded_quests"] as Array).filter(func(id): return id in QuestSystem.SIDE_IDS).size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8c4d2"))

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

func draw_victory() -> void:
	draw_texture_rect(SANCTUARY, WORLD, false)
	draw_rect(WORLD, Color(0.01, 0.03, 0.08, 0.68), true)
	for radius in [75.0, 125.0, 180.0]:
		draw_circle(Vector2(480, 235), radius + sin(world_time * 2.0) * 5.0, Color(0.2, 0.75, 1.0, 0.05))
	for i in 4:
		draw_character(PARTY_SHEET, i, Vector2(300 + i * 120, 365), Vector2(120, 180), "celebrate")
	draw_rect(Rect2(170, 92, 620, 190), Color("07101af2"), true)
	draw_rect(Rect2(170, 92, 620, 190), Color("74e9ff"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(295, 150), "EL JURAMENTO RESTAURADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("baf6ff"))
	draw_wrapped_text("Eryndor conserva sus recuerdos. La corona deja de pertenecer a un rey y vuelve a ser la promesa de todos sus pueblos.", Vector2(228, 194), 66, 23.0, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(343, 264), "Pulsa ENTER para volver al título", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe5a3"))

func draw_notification() -> void:
	if notification_time <= 0.0 or game_state in ["city", "explore", "valdoria_explore", "dungeon", "game_menu", "battle"]:
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
		"dialogue":
			draw_dialogue()
		"explore":
			draw_sanctuary()
		"valdoria_explore":
			draw_valdoria_exploration()
		"dungeon":
			draw_dungeon()
		"battle":
			draw_battle()
		"game_menu":
			draw_game_menu()
		"victory":
			draw_victory()
	draw_notification()
	if scene_router.transition_alpha > 0.0:
		draw_rect(WORLD, Color(0.0, 0.0, 0.0, scene_router.transition_alpha), true)
