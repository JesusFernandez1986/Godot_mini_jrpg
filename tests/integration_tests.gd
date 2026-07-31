class_name IntegrationTests
extends RefCounted

static func frame(tree: SceneTree, scene: Node) -> void:
	scene.queue_redraw()
	await tree.process_frame

static func win_current_battle(tree: SceneTree, scene: Node, maximum_attempts: int = 24) -> bool:
	var attempts := 0
	while scene.game_state == "battle" and attempts < maximum_attempts:
		scene.enemy_hp = 1
		scene.action_duration = 0.0
		scene.attack()
		scene.action_time = scene.action_duration
		await frame(tree, scene)
		attempts += 1
	return scene.game_state != "battle"

static func run(suite: TestSuite, tree: SceneTree) -> void:
	suite.section("Integración de campaña")
	var packed_scene: PackedScene = load("res://Main.tscn") as PackedScene
	var scene: Node = packed_scene.instantiate()
	var integration_save_dir := "user://tests/integration_%d" % Time.get_ticks_usec()
	scene.save_base_dir = integration_save_dir
	tree.root.add_child(scene)
	await frame(tree, scene)
	suite.equal(scene.game_state, "title", "La escena principal arranca en el título")
	suite.equal(scene.get_window().content_scale_size, Vector2i(960, 540), "El viewport conserva una base 16:9 incluso dentro del editor")
	suite.equal(scene.get_window().content_scale_aspect, Window.CONTENT_SCALE_ASPECT_KEEP, "El escalado llena la ventana sin deformar ni empequeñecer el juego")
	scene.open_settings("title")
	await frame(tree, scene)
	suite.equal(scene.game_state, "settings", "La pantalla de ajustes se integra con el router")
	scene.game_state = "title"
	scene.open_save_menu("title")
	await frame(tree, scene)
	suite.equal(scene.game_state, "save_menu", "La pantalla de ranuras se dibuja")
	scene.game_state = "title"
	scene.open_load_menu("title")
	await frame(tree, scene)
	suite.equal(scene.game_state, "load_menu", "La pantalla de carga se dibuja")
	scene.game_state = "title"
	scene.new_game()
	await frame(tree, scene)
	suite.equal(scene.game_state, "dialogue", "Nueva partida abre el prólogo")
	scene.dialogue_system.reveal_line()
	suite.check(scene.dialogue_system.is_line_revealed(), "El prólogo utiliza el sistema de revelado")
	scene.finish_dialogue()
	suite.equal(scene.game_state, "world_map", "El prólogo conduce al mapa")
	suite.check("valdoria" in scene.unlocked_locations, "El prólogo desbloquea Valdoria")
	for city_id in ["valdoria", "brumaforja", "celestia", "sylvaran"]:
		scene.enter_city(city_id)
		await frame(tree, scene)
		suite.equal(scene.game_state, "dialogue", "Entrar en %s inicia su capítulo" % city_id)
		scene.finish_dialogue()
		await frame(tree, scene)
		var expected_city_state := "valdoria_explore" if city_id == "valdoria" else "city"
		suite.equal(scene.game_state, expected_city_state, "Completar %s devuelve a su centro urbano" % city_id)
		scene.begin_city_conversation()
		suite.equal(scene.dialogue_system.lines.size(), 4, "%s entrega conversaciones en bloques" % city_id)
		scene.finish_dialogue()
		scene.rest_at_inn()
		await frame(tree, scene)
	suite.equal(scene.chapter, 5, "Los cuatro capítulos desbloquean el acto final")
	suite.check("sanctuary" in scene.unlocked_locations, "El santuario queda disponible")

	suite.section("Integración de Fase 3 · Vertical slice")
	scene.enter_valdoria_exploration()
	await frame(tree, scene)
	suite.equal(scene.game_state, "valdoria_explore", "Valdoria se puede recorrer físicamente")
	var controller: SanctuaryController = scene.sanctuary_controller as SanctuaryController
	suite.equal(controller.active_profile, "valdoria", "La ciudad activa su perfil de colisión y navegación")
	var reachable_npcs := 0
	for npc in Phase3StoryData.NPCS:
		var npc_id := "npc_" + str(npc["id"])
		if controller.navigation_path_to(npc["position"] as Vector2).size() > 0:
			reachable_npcs += 1
		scene.action_duration = 0.0
		scene.handle_valdoria_interaction(npc_id)
		if scene.game_state == "dialogue":
			scene.finish_dialogue()
	suite.equal(reachable_npcs, 10, "Los diez NPC son alcanzables sin atravesar obstáculos")
	suite.equal(str((scene.phase3_state["main"] as Dictionary)["status"]), "active", "La misión principal queda aceptada")
	for quest_id in QuestSystem.SIDE_IDS:
		suite.equal(str((scene.phase3_state["side"] as Dictionary)[quest_id]["status"]), "active", "La secundaria %s queda aceptada" % quest_id)
	scene.enter_dungeon()
	await frame(tree, scene)
	suite.equal(scene.game_state, "dialogue", "Entrar por primera vez inicia la escena narrativa de mazmorra")
	scene.finish_dialogue()
	await frame(tree, scene)
	suite.equal(scene.game_state, "dungeon", "La introducción devuelve el control en las catacumbas")
	suite.equal(controller.active_profile, "dungeon", "La mazmorra activa su propio perfil físico")
	for interaction_id in ["seal_west", "seal_east", "lost_ledger", "moonleaf"]:
		suite.check(controller.navigation_path_to(controller.interaction_points[interaction_id]).size() > 0, "%s es alcanzable mediante A*" % interaction_id)
		scene.action_duration = 0.0
		scene.handle_dungeon_interaction(interaction_id)
	suite.equal(QuestSystem.seals_active(scene.phase3_state), 2, "Los dos sellos quedan activados")
	var normal_enemy_ids := ["crypt_rat", "hollow_sentinel", "amber_wisp", "ossuary_spider", "veil_cultist", "stone_gargoyle"]
	for enemy_id in normal_enemy_ids:
		var reward_gold_before := int(scene.gold)
		var reward_progress_before: Array = []
		for member in scene.joined_party():
			reward_progress_before.append([int(member["level"]), int(member["xp"])])
		scene.action_duration = 0.0
		scene.start_phase3_battle(enemy_id)
		suite.equal(scene.game_state, "battle", "%s inicia un combate" % enemy_id)
		if enemy_id == "crypt_rat":
			suite.equal((scene.party_battle["allies"] as Array).size(), 4, "La pantalla de batalla presenta a los cuatro héroes")
			suite.equal(PartyBattleSystem.visible_turn_order(scene.party_battle, 7).size(), 7, "La pantalla mantiene un orden de turnos visible")
			suite.equal(scene.BATTLE_COMMANDS.size(), 8, "La interfaz ofrece ataque, arte, cura, defensa, objeto, cambio, combo y huida")
			suite.check(int(scene.party_battle["shield_max"]) > 0 and int(scene.party_battle["resonance"]) == 0, "Ruptura y Resonancia se inicializan en la batalla real")
			suite.check(PartyBattleSystem.validate_state(scene.party_battle).is_empty(), "El estado mostrado por main.gd supera la validación")
		suite.check(await win_current_battle(tree, scene), "%s puede resolverse mediante órdenes reales" % enemy_id)
		suite.equal(scene.game_state, "dungeon", "%s termina sin bloquear la exploración" % enemy_id)
		suite.check(int(scene.gold) > reward_gold_before, "%s concede oro al grupo" % enemy_id)
		var rewarded_members := 0
		for member_index in scene.joined_party().size():
			var member: Dictionary = scene.joined_party()[member_index]
			var previous: Array = reward_progress_before[member_index]
			if int(member["level"]) > int(previous[0]) or int(member["xp"]) > int(previous[1]):
				rewarded_members += 1
		suite.equal(rewarded_members, scene.joined_party().size(), "%s concede EXP a todos los combatientes" % enemy_id)
	suite.equal(int((scene.phase3_state["side"] as Dictionary)["sentry_oath"]["progress"]), 3, "Las victorias actualizan el encargo del centinela")
	suite.check(QuestSystem.can_fight_miniboss(scene.phase3_state), "Los sellos habilitan al Caballero Perjuro")
	for elite_id in ["oathbreaker_knight", "hollow_lion"]:
		var boss_potions_before := int((scene.inventory["Poción menor"] as Dictionary)["quantity"])
		scene.action_duration = 0.0
		scene.start_phase3_battle(elite_id)
		var blocked_flee := PartyBattleSystem.player_flee(scene.party_battle, scene.rng)
		suite.check(not bool(blocked_flee["success"]), "%s bloquea la huida por ser un combate de élite" % elite_id)
		suite.check(await win_current_battle(tree, scene), "%s puede resolverse mediante órdenes reales" % elite_id)
		suite.equal(scene.game_state, "dungeon", "Derrotar a %s conserva un retorno jugable" % elite_id)
		if elite_id == "hollow_lion":
			suite.equal(int((scene.inventory["Poción menor"] as Dictionary)["quantity"]), boss_potions_before + 5, "El jefe entrega su botín garantizado al inventario")
	suite.check(QuestSystem.can_return_main(scene.phase3_state), "Derrotar al jefe activa el regreso a la ciudad")
	scene.enter_valdoria_exploration()
	for npc_id in ["archivist", "healer", "guard"]:
		scene.action_duration = 0.0
		scene.handle_valdoria_interaction("npc_" + npc_id)
		if scene.game_state == "dialogue": scene.finish_dialogue()
	for quest_id in QuestSystem.SIDE_IDS:
		suite.equal(str((scene.phase3_state["side"] as Dictionary)[quest_id]["status"]), "completed", "La secundaria %s entrega recompensa" % quest_id)
	scene.action_duration = 0.0
	scene.handle_valdoria_interaction("npc_captain")
	suite.equal(scene.game_state, "dialogue", "Volver con Elara inicia el desenlace")
	scene.finish_dialogue()
	suite.equal(scene.game_state, "dialogue", "El desenlace enlaza con la escena de cierre")
	scene.finish_dialogue()
	await frame(tree, scene)
	suite.equal(str((scene.phase3_state["main"] as Dictionary)["status"]), "completed", "La misión principal concluye")
	suite.check(bool((scene.phase3_state["flags"] as Dictionary)["closing_seen"]), "La escena final queda registrada")
	var phase_three_payload: Dictionary = scene.save_payload()
	suite.check(phase_three_payload.has("phase3_state") and phase_three_payload.has("dungeon_defeated"), "El guardado conserva toda la Fase 3")
	suite.check(bool(phase_three_payload.get("resonance_tutorial_seen", false)), "El guardado conserva el tutorial de Resonancia de la Fase 4")

	var payload: Dictionary = scene.save_payload() as Dictionary
	scene.gold = 0
	scene.apply_loaded_data(payload)
	suite.check(scene.gold > 0, "Aplicar un guardado restaura la economía")
	for tab in 4:
		scene.open_game_menu("world_map")
		scene.menu_tab = tab
		await frame(tree, scene)
		suite.equal(scene.game_state, "game_menu", "La pestaña %d del menú se renderiza" % tab)
		scene.close_game_menu()
	scene.arrive_at_destination("sanctuary")
	await frame(tree, scene)
	suite.equal(scene.game_state, "explore", "Viajar al santuario abre la exploración")
	suite.check(controller.player is CharacterBody2D, "La exploración utiliza CharacterBody2D")
	suite.check(controller.collision_tilemap is TileMapLayer, "El terreno expone una capa TileMap física")
	suite.check(controller.collision_tilemap.get_used_cells().size() > 0 and controller.collision_tilemap.tile_set.get_physics_layers_count() > 0, "El TileMap contiene celdas con polígonos de colisión")
	suite.check(controller.navigation_agent is NavigationAgent2D, "El jugador dispone de agente de navegación")
	var path_to_chest := controller.navigation_path_to(SanctuaryController.INTERACTIONS["chest"])
	suite.check(path_to_chest.size() > 1, "La navegación calcula una ruta válida hasta el cofre")
	scene.action_duration = 0.0
	controller.set_active(true)
	controller.set_player_position(Vector2(180, 390))
	var movement_start := controller.player_position()
	Input.action_press("move_right")
	for movement_frame in 5:
		await tree.physics_frame
	Input.action_release("move_right")
	await frame(tree, scene)
	suite.check(controller.player_position().distance_to(movement_start) > 1.0, "La entrada mueve físicamente al CharacterBody2D")
	controller.set_active(true)
	controller.apply_input(Vector2.RIGHT, true)
	suite.check(controller.is_running and controller.movement_state == "run" and controller.player.velocity.length() > SanctuaryController.WALK_SPEED, "Shift activa la velocidad de carrera")
	controller.set_player_position(SanctuaryController.INTERACTIONS["chest"])
	scene.hero_position = controller.player_position()
	scene.action_duration = 0.0
	controller.request_interaction()
	await frame(tree, scene)
	suite.check(bool(scene.opened_interactions["chest"]), "Abrir un cofre queda registrado")
	suite.equal(scene.action_animation, "open_chest", "El cofre activa su secuencia frame a frame")
	var phase_two_payload: Dictionary = scene.save_payload() as Dictionary
	suite.equal(str(phase_two_payload["facing_direction"]), scene.facing_direction, "El guardado conserva la orientación")
	suite.check(phase_two_payload.has("opened_interactions"), "El guardado conserva las interacciones del mundo")
	scene.action_duration = 0.0
	controller.set_player_position(Vector2(315, 400))
	scene.hero_position = controller.player_position()
	ProgressionSystem.restore_party(scene.party)
	for enemy_index in 3:
		scene.start_battle(enemy_index)
		await frame(tree, scene)
		suite.equal(scene.game_state, "battle", "El guardián %d inicia combate" % enemy_index)
		suite.check(await win_current_battle(tree, scene), "El guardián %d se derrota sin depender del azar de un único golpe" % enemy_index)
	suite.equal(scene.game_state, "dialogue", "Derrotar tres guardianes abre el final narrativo")
	scene.finish_dialogue()
	await frame(tree, scene)
	suite.equal(scene.game_state, "victory", "La campaña alcanza el epílogo")
	suite.equal(scene.chapter, 6, "El progreso final queda registrado")
	suite.check(ProgressionSystem.validate_party(scene.party).is_empty(), "El grupo final mantiene estadísticas válidas")
	suite.check(InventorySystem.validate(scene.inventory).is_empty(), "El inventario final mantiene datos válidos")
	scene.queue_free()
	await tree.process_frame
	UnitTests.cleanup_test_directory(integration_save_dir)
