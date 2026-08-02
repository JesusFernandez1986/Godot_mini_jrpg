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
	suite.check(scene.audio_director != null, "La escena principal instala el director de audio")
	suite.equal(scene.audio_director.target_cue, "title", "El contexto inicial activa el cue de título")
	suite.check(scene.performance_budget != null, "La escena registra telemetría contra presupuestos explícitos")
	suite.check(PerformanceBudgetSystem.count_nodes(scene) < PerformanceBudgetSystem.MAX_SCENE_NODES, "El árbol inicial permanece dentro del presupuesto de nodos")
	var title_screen := scene.get_node("TitleScreen")
	var victory_screen := scene.get_node("VictoryScreen")
	var slice_hud := scene.get_node("VerticalSliceHUD")
	suite.check(title_screen.visible, "El título se presenta desde una escena UI independiente")
	suite.equal(title_screen.option_count(), 5, "La escena de título expone las cinco acciones jugables")
	suite.check(not victory_screen.visible and not slice_hud.visible, "Las capas de HUD respetan el estado inicial")
	suite.equal(scene.get_window().content_scale_size, Vector2i(960, 540), "El viewport conserva una base 16:9 incluso dentro del editor")
	suite.equal(scene.get_window().content_scale_aspect, Window.CONTENT_SCALE_ASPECT_KEEP, "El escalado llena la ventana sin deformar ni empequeñecer el juego")
	scene.game_state = "victory"
	await frame(tree, scene)
	suite.check(victory_screen.visible and not title_screen.visible, "La victoria se presenta desde su propia escena UI")
	scene.game_state = "title"
	await frame(tree, scene)
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
	scene.start_vertical_slice_demo()
	await frame(tree, scene)
	suite.equal(scene.game_state, "dialogue", "La demo vertical comienza con un prólogo propio")
	suite.check(scene.dialogue_hud.visible, "El diálogo se presenta desde una escena UI independiente")
	suite.check(not (scene.dialogue_hud.get_node("Root/Panel/Layout/Header/Speaker") as Label).text.is_empty(), "El HUD recibe el hablante del sistema narrativo desde el primer frame")
	suite.check(scene.is_vertical_slice_active(), "La demo conserva su alcance dentro del estado narrativo guardable")
	suite.equal(str((scene.phase3_state["main"] as Dictionary)["status"]), "available", "El prólogo no acepta automáticamente el juramento del jugador")
	scene.finish_dialogue()
	await frame(tree, scene)
	suite.equal(scene.game_state, "valdoria_explore", "El prólogo de la demo entrega el control en Valdoria")
	suite.check(scene.hd2d_stage != null, "La escena principal compone una capa HD-2D reutilizable")
	suite.equal(scene.hd2d_stage.active_theme, "valdoria", "Valdoria activa iluminación y profundidad propias")
	suite.check(slice_hud.visible, "La ruta vertical utiliza un HUD desacoplado del render principal")
	suite.check((slice_hud.get_node("Root/Route/Content/Progress") as ProgressBar).value >= 0.0, "El HUD expone progreso de ruta con un control accesible")
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
		scene.update_screen_scenes()
		suite.equal(scene.game_state, "battle", "%s inicia un combate" % enemy_id)
		if enemy_id == "crypt_rat":
			suite.check(scene.battle_hud.visible, "El combate presenta su HUD desde una escena desacoplada")
			suite.equal(scene.battle_hud.command_count(), 8, "El HUD de combate expone las ocho órdenes")
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

	suite.section("Integración de Fase 5 · Equipo y progresión")
	suite.check(EquipmentSystem.validate(scene.equipment_state).is_empty(), "El botín de la vertical slice mantiene un inventario de equipo válido")
	suite.check((scene.equipment_state["owned"] as Dictionary).has("lion_mail") and (scene.equipment_state["owned"] as Dictionary).has("oath_brooch"), "Miniboss y jefe conceden botín de rareza especial")
	var lion_quantity_before := int((scene.equipment_state["owned"] as Dictionary)["lion_mail"]["quantity"])
	scene.open_game_menu("valdoria_explore")
	scene.menu_tab = 1
	scene.menu_index = 4
	scene.workshop_recipe_index = 0
	scene.activate_menu_item()
	suite.equal(int((scene.equipment_state["owned"] as Dictionary)["lion_mail"]["quantity"]), lion_quantity_before + 1, "El taller del menú fabrica una Cota del León")
	scene.menu_tab = 2
	scene.menu_index = 1
	scene.activate_menu_item()
	suite.check(str(AdvancementSystem.member_state(scene.advancement_state, "aren")["secondary_job"]) != "none", "El menú asigna un trabajo secundario con los PT ganados")
	suite.check(EquipmentSystem.validate(scene.equipment_state).is_empty() and AdvancementSystem.validate(scene.advancement_state).is_empty(), "Equipo y progresión siguen siendo válidos tras operar desde la interfaz")

	suite.section("Integración de Fase 6 · Decisiones persistentes")
	suite.equal(scene.active_directed_scene, "council_of_memory", "Completar la Fase 3 inicia el Consejo Abierto")
	suite.check(not scene.dialogue_system.current_metadata().is_empty(), "La escena dirigida aporta expresión, cámara y movimiento")
	suite.equal(scene.directed_music_cue, "council", "La dirección narrativa activa su señal musical")
	scene.advance_directed_scene()
	scene.advance_directed_scene()
	suite.equal(scene.narrative_system.current_choices(scene.narrative_state).size(), 2, "El consejo ofrece dos decisiones jugables")
	var mid_choice_payload: Dictionary = scene.save_payload()
	scene.narrative_state["variables"]["council_path"] = "corrupted-test-value"
	scene.apply_loaded_data(mid_choice_payload)
	suite.equal(scene.active_directed_scene, "council_of_memory", "Cargar reanuda una escena a mitad de decisión")
	suite.equal(scene.narrative_system.current_choices(scene.narrative_state).size(), 2, "Las opciones siguen disponibles tras cargar")
	scene.advance_directed_scene(1)
	scene.complete_directed_scene_with_default_choices()
	suite.equal(str((scene.narrative_state["variables"] as Dictionary)["council_path"]), "mercy", "La decisión de clemencia persiste en variables narrativas")
	suite.equal(str((scene.narrative_state["quests"] as Dictionary)["main_open_council"]["status"]), "completed", "La misión principal ramificada puede completarse")
	suite.check("event_mercy_path" in (scene.narrative_state["codex_unlocked"] as Array), "La decisión desbloquea su entrada de códice")
	suite.check(scene.journal_menu_entries().any(func(entry: Dictionary): return str(entry.get("entry_type", "")) == "codex" and not str(entry.get("objective", "")).is_empty()), "El Diario permite leer el texto completo de personajes, lugares y acontecimientos")
	suite.check(scene.start_directed_scene("aren_memorial", "valdoria_explore", "personal_quest", "valdoria"), "Una misión personal se inicia desde su escena externa")
	scene.complete_directed_scene_with_default_choices()
	suite.equal(str((scene.narrative_state["quests"] as Dictionary)["personal_aren"]["status"]), "completed", "Una misión personal alcanza y persiste su desenlace")

	suite.section("Integración de Fase 7 · Mundo explorable")
	scene.game_state = "world_map"
	scene.chapter = 5
	for location_value in scene.locations:
		var world_location: Dictionary = location_value
		WorldExplorationSystem.discover(scene.world_exploration_state, str(world_location["id"]))
		scene.unlock_location(str(world_location["id"]))
	WorldExplorationSystem.synchronize_progress(scene.world_exploration_state, scene.unlocked_locations, scene.chapter)
	suite.check(bool(scene.world_exploration_state["ship_unlocked"]), "Completar Celestia desbloquea barcos y rutas marítimas")
	for destination_value in scene.locations:
		var destination: Dictionary = destination_value
		suite.check(not WorldExplorationSystem.route_between("valdoria", str(destination["id"]), scene.world_exploration_state, scene.chapter).is_empty(), "La campaña conserva una ruta a %s" % str(destination["id"]))
	var danger: Dictionary = WorldExplorationSystem.DANGER_ZONES[0]
	WorldExplorationSystem.set_position(scene.world_exploration_state, danger["position"] as Vector2)
	scene.start_world_encounter(danger, "world")
	suite.equal(scene.game_state, "battle", "Entrar en un peligro visible inicia el combate del mapa")
	suite.check(await win_current_battle(tree, scene), "El encuentro del mundo puede resolverse con las órdenes reales")
	suite.equal(scene.game_state, "world_map", "Vencer devuelve al punto exacto del mapa mundial")
	suite.check(str(danger["id"]) in (scene.world_exploration_state["defeated_encounters"] as Array), "La reaparición del peligro queda registrada")
	WorldExplorationSystem.set_position(scene.world_exploration_state, Vector2(235, 300))
	var world_camp := WorldExplorationSystem.camp(scene.world_exploration_state, scene.locations)
	suite.check(bool(world_camp["success"]), "El grupo puede acampar y fijar un retorno seguro")
	for landmark_value in WorldExplorationSystem.LANDMARKS:
		var landmark: Dictionary = landmark_value
		scene.enter_world_location(str(landmark["id"]))
		await frame(tree, scene)
		suite.equal(scene.game_state, "landmark", "%s se puede visitar sin perder el punto de retorno" % str(landmark["name"]))
		scene.return_to_world_map()
		suite.equal(scene.game_state, "world_map", "%s permite regresar al mapa" % str(landmark["name"]))

	suite.section("Integración de Fase 8 · Ciudades vivas")
	for city_id in ["valdoria", "brumaforja", "celestia", "sylvaran"]:
		scene.enter_city(city_id)
		await frame(tree, scene)
		suite.equal(scene.game_state, "city", "%s abre su centro urbano vivo tras completar su capítulo" % city_id)
		var visited_district_names: Array[String] = []
		for district_step in 3:
			var district: Dictionary = scene.city_life_system.district(scene.city_life_state, city_id)
			visited_district_names.append(str(district["name"]))
			suite.check(scene.city_actions().any(func(action: Dictionary): return str(action["id"]) == "venue"), "%s ofrece interiores en %s" % [city_id, str(district["name"])])
			scene.city_life_system.change_district(scene.city_life_state, city_id, 1)
		suite.equal(visited_district_names.size(), 3, "%s permite recorrer sus tres barrios" % city_id)
		var current_district: Dictionary = scene.city_life_system.district(scene.city_life_state, city_id)
		var first_venue: Dictionary = (current_district["venues"] as Array)[0]
		suite.check(scene.city_life_system.enter_venue(scene.city_life_state, city_id, str(first_venue["id"])), "%s permite entrar en %s" % [city_id, str(first_venue["name"])])
		await frame(tree, scene)
		suite.check(scene.city_actions().any(func(action: Dictionary): return str(action["id"]) == "service"), "El interior de %s ofrece una interacción propia" % city_id)
		scene.begin_city_conversation()
		suite.equal(scene.dialogue_system.lines.size(), 4, "Los NPC con horario de %s reaccionan al capítulo y la hora" % city_id)
		scene.finish_dialogue()
		scene.city_life_system.leave_venue(scene.city_life_state, city_id)
		scene.hear_city_rumor()
		var conflict_result: Dictionary = {}
		for conflict_stage in 3: conflict_result = scene.city_life_system.advance_conflict(scene.city_life_state, city_id)
		suite.check(bool(conflict_result.get("completed", false)), "El conflicto local de %s puede completarse" % city_id)
		var challenge: Dictionary = scene.city_life_system.activity_challenge(scene.city_life_state, city_id)
		scene.city_activity_active = true
		scene.city_activity_choice = int(challenge["answer"])
		await frame(tree, scene)
		scene.resolve_city_activity()
		suite.check(not scene.city_activity_active and int(((scene.city_life_state["activities"] as Dictionary)[city_id] as Dictionary)["plays"]) > 0, "La actividad característica de %s se renderiza y es jugable" % city_id)
		scene.return_to_world_map()
	suite.check(scene.city_life_system.validate_state(scene.city_life_state).is_empty(), "El recorrido completo de las ciudades conserva un estado válido")

	suite.section("Integración de Fase 9 · Mazmorras multinivel")
	scene.current_landmark = "eira_ruins"
	scene.game_state = "landmark"
	scene.explore_current_landmark()
	await frame(tree, scene)
	suite.equal(scene.game_state, "dungeon_crawl", "Explorar una localización abre su mazmorra isométrica")
	suite.equal(str(scene.dungeon_exploration_state["active_dungeon"]), "eira_ruins", "La mazmorra activa coincide con la localización mundial")
	var start_cell := DungeonExplorationSystem.position(scene.dungeon_exploration_state)
	var movement_result := DungeonExplorationSystem.move(scene.dungeon_exploration_state, Vector2i.RIGHT)
	suite.check(bool(movement_result["success"]) and DungeonExplorationSystem.position(scene.dungeon_exploration_state) != start_cell, "El control de mazmorra mueve al héroe sobre tiles")
	scene.dungeon_exploration_state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(0, "P"))
	scene.resolve_dungeon_interaction(DungeonExplorationSystem.interact(scene.dungeon_exploration_state, DungeonExplorationSystem.available_abilities(scene.party)))
	suite.check("eira_ruins" in (scene.dungeon_exploration_state["revealed_secrets"] as Array), "La capacidad de Aren revela el secreto de las ruinas")
	scene.dungeon_exploration_state["floor"] = 2
	scene.dungeon_exploration_state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(2, "E"))
	scene.resolve_dungeon_interaction(DungeonExplorationSystem.interact(scene.dungeon_exploration_state, DungeonExplorationSystem.available_abilities(scene.party)))
	await frame(tree, scene)
	suite.equal(scene.game_state, "landmark", "Completar la última planta devuelve a la localización sin bloquear la campaña")
	suite.check("eira_ruins" in (scene.dungeon_exploration_state["completed_dungeons"] as Array), "La finalización de la mazmorra persiste")

	suite.section("Integración de Fase 10 · Historias y formación")
	for personal_id in ["aren_1", "naia_1"]:
		suite.check(bool(scene.hero_story_system.start_chapter(scene.hero_story_state, personal_id)["success"]), "%s puede iniciarse desde el diario" % personal_id)
		scene.start_dialogue(scene.hero_story_system.chapter_dialogue_lines(personal_id), "world_map", "hero_chapter:" + personal_id, "world")
		await frame(tree, scene)
		suite.equal(scene.dialogue_system.lines.size(), 5, "%s renderiza su secuencia narrativa" % personal_id)
		scene.finish_dialogue()
		await frame(tree, scene)
	suite.check(bool((scene.party[4] as Dictionary)["joined"]), "El prólogo de Naia la incorpora como protagonista jugable")
	suite.check(bool(HeroStorySystem.toggle_active(scene.party, "brom")["success"]), "Un miembro inicial puede pasar a reserva")
	suite.check(bool(HeroStorySystem.toggle_active(scene.party, "naia")["success"]), "Naia puede entrar en la formación activa")
	scene.open_game_menu("world_map")
	scene.menu_tab = 3
	scene.menu_index = 4
	await frame(tree, scene)
	suite.equal(scene.game_state, "game_menu", "El menú de grupo renderiza el retrato del quinto protagonista")
	scene.close_game_menu()
	scene.start_world_encounter({"id":"phase10_playable", "enemy":"crypt_rat"}, "world")
	suite.check((scene.party_battle["allies"] as Array).any(func(member: Dictionary): return str(member["id"]) == "naia"), "La formación elegida lleva a Naia al combate real")
	suite.check(await win_current_battle(tree, scene), "El combate con una protagonista nueva se resuelve")

	suite.section("Integración de Fases 11-15 · Sistemas finales")
	suite.check(int(scene.bestiary_state["total_defeated"]) > 0 and (scene.bestiary_state["records"] as Dictionary).has("crypt_rat"), "Los combates reales alimentan el bestiario")
	suite.check(bool(BestiarySystem.scan(scene.bestiary_state, "crypt_rat")["success"]), "La criatura observada se puede analizar desde Extras")
	var gold_before_market: int = int(scene.gold)
	var market_result := CommerceSystem.buy(scene.commerce_state, "valdoria", 0, scene.gold, scene.inventory, scene.equipment_state)
	scene.gold = int(market_result.get("gold", scene.gold))
	suite.check(bool(market_result["success"]) and scene.gold < gold_before_market, "El mercado integrado compra, entrega y descuenta oro")
	scene.current_city = "valdoria"
	scene.open_game_menu("world_map")
	scene.menu_tab = 5
	scene.menu_index = 2
	scene.activate_menu_item()
	await frame(tree, scene)
	suite.equal(scene.game_state, "dialogue", "Aceptar una misión de facción abre su escena narrativa")
	scene.finish_dialogue()
	await frame(tree, scene)
	scene.open_game_menu("world_map")
	scene.menu_tab = 5
	scene.menu_index = 2
	scene.activate_menu_item()
	await frame(tree, scene)
	scene.finish_dialogue()
	await frame(tree, scene)
	suite.equal(str((scene.faction_state["quest_status"] as Dictionary)["lion_crown_01"]), "completed", "La misión de facción completa sus etapas y persiste")
	EndgameSystem.unlock(scene.endgame_state)
	scene.open_game_menu("world_map")
	scene.menu_tab = 5
	scene.menu_index = 3
	scene.activate_menu_item()
	await frame(tree, scene)
	suite.equal(scene.game_state, "battle", "La Arena de los Ecos inicia un combate escalado")
	suite.check(await win_current_battle(tree, scene), "El combate de arena se resuelve con el sistema de batalla completo")
	suite.check(1 in (scene.endgame_state["arena_cleared"] as Array), "La victoria de arena queda registrada")
	scene.refresh_completion_progress()
	suite.check((scene.completion_state["unlocked"] as Array).size() > 0, "Los logros se sincronizan con la partida real")
	var phase_three_payload: Dictionary = scene.save_payload()
	suite.check(phase_three_payload.has("phase3_state") and phase_three_payload.has("dungeon_defeated"), "El guardado conserva toda la Fase 3")
	suite.check(bool(phase_three_payload.get("resonance_tutorial_seen", false)), "El guardado conserva el tutorial de Resonancia de la Fase 4")
	suite.check(phase_three_payload.has("equipment_state") and phase_three_payload.has("advancement_state") and phase_three_payload.has("narrative_state"), "El guardado conserva íntegramente las Fases 5 y 6")
	suite.check(phase_three_payload.has("world_exploration_state") and phase_three_payload.has("city_life_state"), "El guardado conserva mundo, clima, campamentos, barrios, horarios y actividades")
	suite.check(phase_three_payload.has("dungeon_exploration_state") and phase_three_payload.has("hero_story_state"), "El guardado v11 conserva las fases 9 y 10")
	suite.check(phase_three_payload.has("bestiary_state") and phase_three_payload.has("commerce_state") and phase_three_payload.has("faction_state") and phase_three_payload.has("endgame_state") and phase_three_payload.has("completion_state"), "El guardado v16 conserva todos los sistemas finales")

	var payload: Dictionary = scene.save_payload() as Dictionary
	scene.gold = 0
	scene.apply_loaded_data(payload)
	suite.check(scene.gold > 0, "Aplicar un guardado restaura la economía")
	for tab in 7:
		scene.open_game_menu("world_map")
		scene.menu_tab = tab
		await frame(tree, scene)
		suite.equal(scene.game_state, "game_menu", "La pestaña %d del menú se renderiza" % tab)
		scene.close_game_menu()
	scene.arrive_at_destination("sanctuary")
	await frame(tree, scene)
	suite.equal(scene.active_directed_scene, "road_valdoria_banter", "Viajar activa una conversación opcional del grupo")
	scene.finish_dialogue()
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
	suite.check(EquipmentSystem.validate(scene.equipment_state).is_empty(), "El equipo final mantiene todas sus invariantes")
	suite.check(AdvancementSystem.validate(scene.advancement_state).is_empty(), "La progresión final mantiene todas sus invariantes")
	suite.check(scene.narrative_system.validate_state(scene.narrative_state).is_empty(), "La narrativa final mantiene todas sus ramas persistentes")
	EndgameSystem.unlock(scene.endgame_state)
	scene.endgame_state["arena_cleared"] = range(1, 26)
	for boss in EndgameSystem.SUPERBOSSES: (scene.endgame_state["superbosses_defeated"] as Array).append(str((boss as Array)[0]))
	var carried_level := int((scene.party[0] as Dictionary)["level"])
	scene.start_new_game_plus_campaign()
	await frame(tree, scene)
	suite.equal(int(scene.endgame_state["ng_plus_cycle"]), 1, "La Nueva Partida + se inicia desde el menú final")
	suite.equal(int((scene.party[0] as Dictionary)["level"]), carried_level, "Nueva Partida + conserva niveles, equipo e inventario")
	suite.equal(scene.game_state, "dialogue", "El nuevo ciclo vuelve al prólogo sin perder el legado")
	scene.queue_free()
	await tree.process_frame
	UnitTests.cleanup_test_directory(integration_save_dir)
