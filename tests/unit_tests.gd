class_name UnitTests
extends RefCounted

static func run(suite: TestSuite) -> void:
	test_database(suite)
	test_scene_router(suite)
	test_inventory(suite)
	test_progression(suite)
	test_dialogue(suite)
	test_travel(suite)
	test_battle(suite)
	test_party_battle(suite)
	test_battle_statuses_and_ai(suite)
	test_battle_simulations(suite)
	test_phase3_quests(suite)
	test_character_animation(suite)
	test_camera(suite)
	test_sanctuary_movement(suite)
	test_settings(suite)
	test_save_system(suite)
	test_logger(suite)

static func test_database(suite: TestSuite) -> void:
	suite.section("Recursos de datos")
	suite.equal(GameDatabase.CHARACTERS.size(), 4, "Hay cuatro definiciones de personaje")
	suite.equal(GameDatabase.ITEMS.size(), 4, "Hay cuatro definiciones iniciales de objeto")
	suite.equal(GameDatabase.ENEMIES.size(), 11, "Hay tres guardianes y ocho enemigos de la vertical slice")
	suite.equal(GameDatabase.LOCATIONS.size(), 5, "Hay cinco localizaciones en el mapa")
	suite.equal(GameDatabase.QUESTS.size(), 7, "Hay siete hitos narrativos")
	suite.check(GameDatabase.validate().is_empty(), "Los identificadores de recursos son válidos y únicos")
	var party := GameDatabase.create_party()
	suite.equal(str(party[0]["name"]), "Aren", "La definición de Aren produce datos de ejecución")
	suite.equal(bool(party[1]["joined"]), false, "Lyra comienza fuera del grupo")
	var phase3_enemies := GameDatabase.ENEMIES.filter(func(enemy: EnemyDefinition): return enemy.phase3_atlas)
	suite.equal(phase3_enemies.size(), 8, "La Fase 3 incorpora seis enemigos, un miniboss y un jefe")
	suite.equal(phase3_enemies.filter(func(enemy: EnemyDefinition): return enemy.rank == "normal").size(), 6, "Existen seis tipos de enemigo normal distintos")
	suite.equal(phase3_enemies.filter(func(enemy: EnemyDefinition): return enemy.rank == "miniboss").size(), 1, "Existe exactamente un miniboss")
	suite.equal(phase3_enemies.filter(func(enemy: EnemyDefinition): return enemy.rank == "boss").size(), 1, "Existe exactamente un jefe")
	suite.equal(str(GameDatabase.enemy_by_id("hollow_lion")["name"]), "León de la Corona Hueca", "Los enemigos de mazmorra se resuelven por id")

static func test_scene_router(suite: TestSuite) -> void:
	suite.section("Gestor de escenas")
	var router := SceneRouter.new()
	suite.equal(router.current_state, "title", "El estado inicial es el título")
	suite.check(router.change_state("world_map"), "Acepta una transición válida")
	suite.equal(router.previous_state, "title", "Conserva el estado anterior")
	suite.equal(router.current_state, "world_map", "Actualiza el estado actual")
	suite.check(router.transition_alpha > 0.0, "Inicia un fundido visual")
	router.update(1.0)
	suite.equal(router.transition_alpha, 0.0, "El fundido termina de forma determinista")

static func test_inventory(suite: TestSuite) -> void:
	suite.section("Inventario")
	var inventory := GameDatabase.create_initial_inventory()
	var potion := GameDatabase.item_by_name("Poción menor")
	suite.check(potion != null, "La poción se resuelve desde la base de datos")
	var add_result := InventorySystem.add_item(inventory, "Poción menor", potion, 2)
	suite.check(bool(add_result["success"]), "Se puede acumular un consumible")
	suite.equal(int(inventory["Poción menor"]["quantity"]), 5, "La cantidad acumulada es correcta")
	var target := GameDatabase.create_party()[0] as Dictionary
	target["hp"] = 5
	var use_result := InventorySystem.use_item(inventory, "Poción menor", target)
	suite.check(bool(use_result["success"]), "Una poción se puede utilizar")
	suite.equal(int(target["hp"]), 25, "La poción restaura exactamente 20 PV")
	suite.equal(int(inventory["Poción menor"]["quantity"]), 4, "Utilizar consume una unidad")
	var key_result := InventorySystem.use_item(inventory, "Cristal de Eira", target)
	suite.check(not bool(key_result["success"]), "Un objeto clave no se consume")
	suite.check(InventorySystem.validate(inventory).is_empty(), "El inventario resultante supera la validación")

static func test_progression(suite: TestSuite) -> void:
	suite.section("Progresión")
	var member := GameDatabase.create_party()[0] as Dictionary
	var original_level := int(member["level"])
	var gained := ProgressionSystem.grant_xp(member, 100)
	suite.check(gained >= 2, "Una gran recompensa puede conceder varios niveles")
	suite.check(int(member["level"]) > original_level, "El nivel aumenta")
	member["hp"] = 1
	member["mp"] = 0
	ProgressionSystem.restore_party([member])
	suite.equal(int(member["hp"]), int(member["max_hp"]), "Descansar restaura PV")
	suite.equal(int(member["mp"]), int(member["max_mp"]), "Descansar restaura PM")
	suite.check(ProgressionSystem.validate_party([member]).is_empty(), "Las estadísticas permanecen válidas")

static func test_dialogue(suite: TestSuite) -> void:
	suite.section("Diálogo")
	var dialogue := DialogueSystem.new()
	var lines := [["Aren", "Una promesa debe recordarse."], ["Lyra", "Incluso cuando duele."]]
	dialogue.begin(lines, "world_map", "test", "valdoria")
	suite.equal(str(dialogue.current_pair()[0]), "Aren", "Comienza en la primera intervención")
	dialogue.update(0.1, 10.0)
	suite.check(dialogue.visible_text().length() > 0, "El texto aparece de forma progresiva")
	suite.check(not dialogue.advance(), "El primer Enter revela la línea incompleta")
	suite.check(dialogue.is_line_revealed(), "La línea queda completamente revelada")
	suite.check(not dialogue.advance(), "Avanzar a la segunda línea no finaliza el diálogo")
	dialogue.reveal_line()
	suite.check(dialogue.advance(), "La última línea completa el diálogo")
	var chunk := DialogueSystem.city_chunk(StoryData.get_city_lines("valdoria"), 39, 4)
	suite.equal((chunk["lines"] as Array).size(), 4, "Los diálogos urbanos se dividen en bloques")
	suite.equal(int(chunk["next"]), 3, "El bloque urbano vuelve al principio sin desbordarse")
	suite.greater_or_equal(StoryData.dialogue_count(), 200, "La campaña conserva cientos de diálogos")

static func test_travel(suite: TestSuite) -> void:
	suite.section("Viaje")
	var unlocked: Array = []
	suite.check(TravelSystem.unlock(unlocked, "valdoria"), "Se desbloquea un destino nuevo")
	suite.check(not TravelSystem.unlock(unlocked, "valdoria"), "No se duplica un destino")
	suite.check(TravelSystem.can_travel(unlocked, "valdoria"), "Se puede viajar a un destino desbloqueado")
	suite.check(not TravelSystem.can_travel(unlocked, "sylvaran"), "No se puede viajar a un destino bloqueado")
	suite.check(TravelSystem.validate_route(GameDatabase.locations(), unlocked).is_empty(), "La red de viaje es coherente")

static func test_battle(suite: TestSuite) -> void:
	suite.section("Combate")
	var random := RandomNumberGenerator.new()
	random.seed = 12345
	var hero := GameDatabase.create_party()[0] as Dictionary
	var enemy := GameDatabase.enemy(0)
	var physical := BattleSystem.physical_damage(hero, enemy, random)
	var magical := BattleSystem.crystal_damage(hero, enemy, random)
	var retaliation := BattleSystem.enemy_damage(enemy, hero, random)
	suite.check(physical > 0, "El daño físico nunca es cero o negativo")
	suite.check(magical > physical, "La técnica prismática es más potente en esta configuración")
	suite.check(retaliation > 0, "El enemigo produce daño válido")
	suite.check(BattleSystem.heal_amount(hero) > 0, "La curación produce un valor positivo")
	suite.check(BattleSystem.validate_combatant(hero).is_empty(), "El protagonista cumple el contrato de combatiente")

static func test_party_battle(suite: TestSuite) -> void:
	suite.section("Fase 4 · Combate completo de grupo")
	var random := RandomNumberGenerator.new()
	random.seed = 41004
	var party := full_test_party()
	var battle := PartyBattleSystem.create_battle(party, GameDatabase.enemy_by_id("crypt_rat"))
	suite.equal((battle["allies"] as Array).size(), 4, "Los cuatro personajes participan activamente")
	suite.equal(PartyBattleSystem.current_actor_id(battle), "ally:seris", "La iniciativa comienza por el personaje más veloz")
	var visible_order := PartyBattleSystem.visible_turn_order(battle, 7)
	suite.equal(visible_order.size(), 7, "La interfaz puede anticipar siete turnos")
	suite.check("enemy" in visible_order and "ally:brom" in visible_order, "El orden visible incluye aliados y enemigo")
	PartyBattleSystem.resolve_until_player(battle, random)
	suite.equal(str(PartyBattleSystem.current_ally(battle).get("id", "")), "seris", "La resolución se detiene ante una decisión del jugador")

	var aren: Dictionary = party[0]
	var weakness_battle := PartyBattleSystem.create_battle(party, GameDatabase.enemy_by_id("crypt_rat"))
	var weak_hit := force_enemy_hit(weakness_battle, aren, 8, "physical", "sword", random)
	suite.check(bool(weak_hit["weak"]), "El daño físico puede explotar una debilidad de arma")
	suite.equal(int(weakness_battle["resonance"]), 1, "Explotar una debilidad genera Resonancia")
	suite.equal(int(weakness_battle["shield"]), 0, "La debilidad reduce el escudo de ruptura")
	suite.equal(int(weakness_battle["broken_turns"]), 1, "Vaciar el escudo provoca una ruptura defensiva")
	var sentinel := GameDatabase.enemy_by_id("hollow_sentinel")
	suite.equal(PartyBattleSystem.affinity_multiplier(sentinel, "lightning"), 1.5, "El daño elemental aplica multiplicador de debilidad")
	suite.equal(PartyBattleSystem.affinity_multiplier(sentinel, "sword"), 0.55, "Las resistencias reducen el daño de forma explícita")
	suite.equal(PartyBattleSystem.affinity_multiplier(sentinel, "ice"), 1.0, "Una afinidad neutral conserva el daño base")

	var art_battle := PartyBattleSystem.create_battle(party, GameDatabase.enemy_by_id("amber_wisp"))
	PartyBattleSystem.resolve_until_player(art_battle, random)
	var art_actor := PartyBattleSystem.current_ally(art_battle)
	var mp_before := int(art_actor["mp"])
	var art_result := PartyBattleSystem.perform_player_action(art_battle, "art", {}, {}, random)
	suite.check(bool(art_result["success"]), "Cada personaje puede ejecutar su arte mágico y elemental")
	suite.equal(int(art_actor["mp"]), mp_before - 3, "El arte consume sus PM definidos")

	var action_battle := PartyBattleSystem.create_battle(full_test_party(), GameDatabase.enemy_by_id("stone_gargoyle"))
	PartyBattleSystem.resolve_until_player(action_battle, random)
	var action_actor := PartyBattleSystem.current_ally(action_battle)
	var defend_result := PartyBattleSystem.player_defend(action_battle, action_actor)
	suite.check(bool(defend_result["success"]) and bool((action_battle["defending"] as Dictionary).get(str(action_actor["id"]), false)), "Defender prepara una reducción del próximo impacto")
	var inventory := GameDatabase.create_initial_inventory()
	action_actor["hp"] = maxi(1, int(action_actor["hp"]) - 12)
	var potion_before := int((inventory["Poción menor"] as Dictionary)["quantity"])
	var item_target_index := PartyBattleSystem.living_allies(action_battle).find(action_actor)
	var item_result := PartyBattleSystem.player_item(action_battle, action_actor, {"item_name":"Poción menor", "target_index":item_target_index}, inventory)
	suite.check(bool(item_result["success"]), "Los objetos se pueden usar durante el combate")
	suite.equal(int((inventory["Poción menor"] as Dictionary)["quantity"]), potion_before - 1, "Usar un objeto consume exactamente una unidad")
	var switch_result := PartyBattleSystem.player_switch(action_battle, action_actor, {"target_index":1})
	suite.check(bool(switch_result["success"]), "Se puede ceder el siguiente turno a otro personaje")
	action_battle["resonance"] = PartyBattleSystem.COMBO_COST
	var combo_result := PartyBattleSystem.player_combo(action_battle, action_actor, random)
	suite.check(bool(combo_result["success"]) and int(combo_result["damage"]) > 0, "Dos o más aliados pueden ejecutar un ataque combinado")
	suite.equal(int(action_battle["resonance"]), 0, "El ataque combinado consume tres puntos de Resonancia")

	var normal_flee := PartyBattleSystem.create_battle(full_test_party(), GameDatabase.enemy_by_id("crypt_rat"))
	for attempt in 12:
		if str(normal_flee["outcome"]) == "fled": break
		PartyBattleSystem.player_flee(normal_flee, random)
	suite.equal(str(normal_flee["outcome"]), "fled", "Los intentos sucesivos permiten huir de un encuentro normal")
	var boss_flee := PartyBattleSystem.create_battle(full_test_party(), GameDatabase.enemy_by_id("hollow_lion"))
	var blocked_flee := PartyBattleSystem.player_flee(boss_flee, random)
	suite.check(not bool(blocked_flee["success"]), "La huida está bloqueada ante un jefe")

	var loot_battle := PartyBattleSystem.create_battle(full_test_party(), GameDatabase.enemy_by_id("hollow_lion"))
	(loot_battle["enemy"] as Dictionary)["hp"] = 0
	PartyBattleSystem.check_outcome(loot_battle, random)
	suite.equal(str(loot_battle["outcome"]), "victory", "Reducir los PV enemigos a cero concluye la batalla")
	suite.equal((loot_battle["loot"] as Array).size(), 1, "El botín garantizado del jefe se sortea al vencer")
	suite.check(PartyBattleSystem.validate_state(loot_battle).is_empty(), "El estado completo conserva todas sus invariantes")

static func test_battle_statuses_and_ai(suite: TestSuite) -> void:
	suite.section("Fase 4 · Estados e inteligencia enemiga")
	var statuses: Dictionary = {}
	for status_id in PartyBattleSystem.STATUS_IDS:
		suite.check(PartyBattleSystem.apply_status(statuses, status_id, 2), "Se puede aplicar el estado %s" % status_id)
	suite.equal(statuses.size(), PartyBattleSystem.STATUS_IDS.size(), "Los seis estados coexisten sin sobrescribirse")
	suite.check(not PartyBattleSystem.apply_status(statuses, "inexistente", 2), "Un estado desconocido se rechaza")

	var random := RandomNumberGenerator.new()
	random.seed = 43004
	var poison_target := (full_test_party()[0] as Dictionary).duplicate(true)
	var poison_status := {"poison":{"turns":2, "power":0}}
	var hp_before := int(poison_target["hp"])
	PartyBattleSystem.tick_statuses(poison_target, poison_status, random)
	suite.check(int(poison_target["hp"]) < hp_before, "El veneno causa daño periódico")
	var regen_target := (full_test_party()[1] as Dictionary).duplicate(true)
	regen_target["hp"] = 1
	var regen_status := {"regeneration":{"turns":2, "power":7}}
	PartyBattleSystem.tick_statuses(regen_target, regen_status, random)
	suite.equal(int(regen_target["hp"]), 8, "Regeneración restaura la cantidad configurada")
	var sleep_target := (full_test_party()[2] as Dictionary).duplicate(true)
	var sleep_tick := PartyBattleSystem.tick_statuses(sleep_target, {"sleep":{"turns":2, "power":0}}, random)
	suite.check(bool(sleep_tick["skip"]), "Dormir hace perder el turno")

	var silence_battle := PartyBattleSystem.create_battle(full_test_party(), GameDatabase.enemy_by_id("amber_wisp"))
	PartyBattleSystem.resolve_until_player(silence_battle, random)
	var silenced_actor := PartyBattleSystem.current_ally(silence_battle)
	var actor_statuses: Dictionary = (silence_battle["ally_statuses"] as Dictionary)[str(silenced_actor["id"])]
	PartyBattleSystem.apply_status(actor_statuses, "silence", 2)
	var silence_result := PartyBattleSystem.player_art(silence_battle, silenced_actor, random)
	suite.check(not bool(silence_result["success"]), "Silencio impide usar artes mágicas")
	var blind_battle := PartyBattleSystem.create_battle(full_test_party(), GameDatabase.enemy_by_id("crypt_rat"))
	var blind_actor := (blind_battle["allies"] as Array)[0] as Dictionary
	PartyBattleSystem.apply_status((blind_battle["ally_statuses"] as Dictionary)[str(blind_actor["id"])], "blind", 2)
	var misses := 0
	for shot in 80:
		var hit := PartyBattleSystem.deal_enemy_damage(blind_battle, blind_actor, 1, "physical", "neutral", random)
		if bool(hit["miss"]): misses += 1
	suite.check(misses >= 20, "Ceguera reduce de forma observable la precisión")

	var boss := GameDatabase.enemy_by_id("hollow_lion")
	var phase_battle := PartyBattleSystem.create_battle(full_test_party(), boss)
	(phase_battle["enemy"] as Dictionary)["hp"] = int(float((phase_battle["enemy"] as Dictionary)["max_hp"]) * 0.6)
	PartyBattleSystem.update_enemy_phase(phase_battle)
	suite.equal(int(phase_battle["enemy_phase"]), 2, "El jefe cambia a su segunda fase por debajo del 66 %")
	suite.equal(PartyBattleSystem.predicted_enemy_action(phase_battle), "silence", "La intención muestra el siguiente paso del patrón")
	(phase_battle["enemy"] as Dictionary)["hp"] = int(float((phase_battle["enemy"] as Dictionary)["max_hp"]) * 0.2)
	PartyBattleSystem.update_enemy_phase(phase_battle)
	suite.equal(int(phase_battle["enemy_phase"]), 3, "El jefe alcanza una tercera fase crítica")
	var first_phase_three_action := PartyBattleSystem.next_enemy_action(phase_battle)
	var second_phase_three_action := PartyBattleSystem.next_enemy_action(phase_battle)
	suite.equal(first_phase_three_action, "regeneration", "La fase final inicia su patrón de regeneración")
	suite.equal(second_phase_three_action, "fear", "La IA avanza de forma determinista por su patrón")
	var covered_statuses: Array[String] = []
	for definition in GameDatabase.ENEMIES:
		for action in definition.ai_phase_1 + definition.ai_phase_2 + definition.ai_phase_3:
			if action in PartyBattleSystem.STATUS_IDS and action not in covered_statuses:
				covered_statuses.append(action)
	covered_statuses.sort()
	var expected_statuses := PartyBattleSystem.STATUS_IDS.duplicate()
	expected_statuses.sort()
	suite.equal(covered_statuses, expected_statuses, "Los patrones enemigos ejercitan todos los estados implementados")

static func test_battle_simulations(suite: TestSuite) -> void:
	suite.section("Fase 4 · Simulación masiva")
	var simulated := 2500
	var timeouts := 0
	var invalid_states := 0
	var victories := 0
	var defeats := 0
	for simulation_index in simulated:
		var enemy_index := 3 + simulation_index % 8
		var state := PartyBattleSystem.simulate_battle(full_test_party(), GameDatabase.ENEMIES[enemy_index].create_runtime(), 44000 + simulation_index)
		match str(state["outcome"]):
			"victory": victories += 1
			"defeat": defeats += 1
			"timeout": timeouts += 1
		if not PartyBattleSystem.validate_state(state).is_empty(): invalid_states += 1
	suite.equal(timeouts, 0, "Ninguna de las 2.500 batallas queda bloqueada")
	suite.equal(invalid_states, 0, "Las 2.500 simulaciones preservan PV, escudos y Resonancia válidos")
	suite.equal(victories + defeats, simulated, "Todas las simulaciones producen un resultado terminal")
	suite.check(victories > 0, "La estrategia automática puede vencer encuentros y jefes")
	var fragile_party := full_test_party()
	for member in fragile_party:
		member["hp"] = 1
		member["mp"] = 0
	var deliberate_defeat := PartyBattleSystem.simulate_battle(fragile_party, GameDatabase.enemy_by_id("hollow_lion"), 49999)
	suite.equal(str(deliberate_defeat["outcome"]), "defeat", "Un grupo exhausto puede ser derrotado por el jefe")

static func full_test_party() -> Array:
	var party := GameDatabase.create_party()
	for member in party:
		if member is Dictionary: member["joined"] = true
	return party

static func force_enemy_hit(state: Dictionary, attacker: Dictionary, power: int, damage_kind: String, affinity: String, random: RandomNumberGenerator) -> Dictionary:
	var result: Dictionary = {}
	for attempt in 32:
		result = PartyBattleSystem.deal_enemy_damage(state, attacker, power, damage_kind, affinity, random)
		if not bool(result["miss"]): break
	return result

static func test_phase3_quests(suite: TestSuite) -> void:
	suite.section("Fase 3 · Misiones y progresión")
	var state := QuestSystem.create_phase3_state()
	suite.check(QuestSystem.validate(state).is_empty(), "El estado inicial de misiones es válido")
	suite.equal(str((state["main"] as Dictionary)["status"]), "available", "La misión principal comienza disponible")
	suite.check(QuestSystem.accept_main(state), "La capitana permite aceptar la misión principal")
	suite.check(bool((state["flags"] as Dictionary)["dungeon_unlocked"]), "Aceptar la misión abre las catacumbas")
	for quest_id in QuestSystem.SIDE_IDS:
		suite.check(QuestSystem.accept_side(state, quest_id), "Se acepta la secundaria %s" % quest_id)
	suite.check(QuestSystem.collect_objective(state, "ledger_found"), "Se recoge el registro perdido")
	suite.check(QuestSystem.collect_objective(state, "herb_found"), "Se recoge la hoja lunar")
	for enemy_id in ["crypt_rat", "amber_wisp", "ossuary_spider"]:
		QuestSystem.record_enemy_defeat(state, enemy_id)
	suite.equal(str((state["side"] as Dictionary)["sentry_oath"]["status"]), "ready", "Tres victorias completan el encargo del centinela")
	suite.check(QuestSystem.activate_seal(state, "seal_west"), "Se activa el sello occidental")
	suite.check(QuestSystem.activate_seal(state, "seal_east"), "Se activa el sello oriental")
	suite.check(QuestSystem.can_fight_miniboss(state), "Los dos sellos habilitan el miniboss")
	suite.check("Caballero Perjuro" in QuestSystem.objective(state), "El diario señala claramente el siguiente encuentro")
	QuestSystem.record_enemy_defeat(state, "oathbreaker_knight", "miniboss")
	suite.check(QuestSystem.can_fight_boss(state), "Derrotar al miniboss habilita el jefe")
	QuestSystem.record_enemy_defeat(state, "hollow_lion", "boss")
	suite.check(QuestSystem.can_return_main(state), "Derrotar al jefe exige regresar a Valdoria")
	for quest_id in QuestSystem.SIDE_IDS:
		suite.check(not QuestSystem.turn_in_side(state, quest_id).is_empty(), "La secundaria %s concede recompensa una sola vez" % quest_id)
		suite.check(QuestSystem.turn_in_side(state, quest_id).is_empty(), "La recompensa de %s no se puede duplicar" % quest_id)
	suite.check(not QuestSystem.turn_in_main(state).is_empty(), "La misión principal concede su recompensa")
	suite.equal(str((state["main"] as Dictionary)["status"]), "completed", "La vertical slice queda completada")
	suite.greater_or_equal(StoryData.dialogue_count() + Phase3StoryData.dialogue_count(), 275, "La narrativa combinada supera 275 intervenciones")

static func test_character_animation(suite: TestSuite) -> void:
	suite.section("Animación frame a frame")
	var atlas: Texture2D = load("res://assets/party_animation_atlas.png") as Texture2D
	suite.equal(atlas.get_width(), 1536, "El atlas conserva su anchura de producción")
	suite.equal(atlas.get_height(), 1024, "El atlas contiene ocho filas direccionales")
	var atlas_image := atlas.get_image()
	suite.check(atlas_image.get_pixel(0, 0).a < 0.05, "El fondo del atlas es realmente transparente")
	var enemy_atlas: Texture2D = load("res://assets/phase3_enemies.png") as Texture2D
	var enemy_image := enemy_atlas.get_image()
	suite.check(enemy_image.get_pixel(0, 0).a < 0.05, "La hoja de enemigos usa transparencia real")
	for sprite_index in 8:
		var enemy_region := GameUI.grid_source(enemy_atlas, sprite_index, 4, 2)
		suite.check(enemy_region.end.x <= enemy_atlas.get_width() and enemy_region.end.y <= enemy_atlas.get_height(), "El sprite de enemigo %d ocupa una celda válida" % sprite_index)
	var dungeon_texture: Texture2D = load("res://assets/valdoria_catacombs_hd2d.png") as Texture2D
	var dungeon_aspect := float(dungeon_texture.get_width()) / float(dungeon_texture.get_height())
	suite.check(absf(dungeon_aspect - 16.0 / 9.0) < 0.002, "El fondo de mazmorra conserva formato 16:9")
	var direction_vectors := {
		"south": Vector2.DOWN,
		"southwest": Vector2(-1, 1),
		"west": Vector2.LEFT,
		"northwest": Vector2(-1, -1),
		"north": Vector2.UP,
		"northeast": Vector2(1, -1),
		"east": Vector2.RIGHT,
		"southeast": Vector2(1, 1)
	}
	for direction in CharacterAnimationSystem.DIRECTIONS:
		suite.equal(CharacterAnimationSystem.direction_from_vector(direction_vectors[direction]), direction, "La orientación %s se resuelve correctamente" % direction)
	for character_index in 4:
		for direction in CharacterAnimationSystem.DIRECTIONS:
			var region := CharacterAnimationSystem.atlas_region(character_index, direction, "walk", 0.0)
			suite.check(region.position.x >= 0.0 and region.position.y >= 0.0 and region.end.x <= atlas.get_width() and region.end.y <= atlas.get_height(), "Personaje %d/%s usa una región válida" % [character_index, direction])
		var first := CharacterAnimationSystem.frame_index("walk", 0.0, character_index)
		var next := CharacterAnimationSystem.frame_index("walk", 0.18, character_index)
		suite.check(first != next, "El personaje %d cambia de fotograma al caminar" % character_index)
	for state in CharacterAnimationSystem.STATES:
		suite.check(CharacterAnimationSystem.validate_state(state), "La acción %s tiene secuencia discreta" % state)
		if state != "idle":
			var unique_frames: Array = []
			for frame in CharacterAnimationSystem.frame_sequence(state, 3):
				if frame not in unique_frames:
					unique_frames.append(frame)
			suite.check(unique_frames.size() >= 2, "La acción %s contiene cambios visibles de fotograma" % state)

static func test_camera(suite: TestSuite) -> void:
	suite.section("Cámara y profundidad")
	var camera := CameraSystem.new()
	camera.snap(Vector2(315, 400))
	var initial_position := camera.position
	camera.update(0.2, Vector2(760, 420), true)
	suite.check(camera.position != initial_position, "La cámara converge suavemente hacia el jugador")
	suite.equal(camera.target_zoom, 1.04, "Correr activa el zoom contextual de exploración")
	camera.update(0.2, Vector2(500, 220), false, true)
	suite.equal(camera.target_zoom, 1.18, "Una interacción cercana acerca la cámara")
	var screen_point := camera.world_to_screen(camera.position)
	suite.check(screen_point.distance_to(CameraSystem.VIEWPORT_SIZE * 0.5) < 0.01, "El foco de cámara se proyecta al centro del viewport")

static func test_sanctuary_movement(suite: TestSuite) -> void:
	suite.section("Movimiento, colisiones y navegación")
	var controller := SanctuaryController.new()
	var iso := SanctuaryController.isometric_direction(Vector2.RIGHT)
	suite.check(iso.x > 0.0 and iso.y > 0.0, "El movimiento horizontal se proyecta en diagonal isométrica")
	suite.check(controller.collides_with_world(Vector2(10, 10)), "Los límites exteriores bloquean al personaje")
	suite.check(controller.collides_with_world(SanctuaryController.OBSTACLES[0].get_center()), "Los decorados sólidos bloquean al personaje")
	suite.check(not controller.collides_with_world(SanctuaryController.START_POSITION), "La entrada del santuario es transitable")
	var simulated_position := SanctuaryController.START_POSITION
	var maximum_step := 0.0
	var inputs := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for frame_index in 36000:
		var previous := simulated_position
		simulated_position = controller.safe_motion_step(simulated_position, inputs[(frame_index / 450) % inputs.size()], frame_index % 120 < 60, 1.0 / 60.0)
		maximum_step = maxf(maximum_step, previous.distance_to(simulated_position))
		if controller.collides_with_world(simulated_position):
			suite.check(false, "La simulación de diez minutos nunca penetra un decorado")
			break
	suite.check(not controller.collides_with_world(simulated_position), "Diez minutos de movimiento terminan en una posición válida")
	suite.check(maximum_step <= SanctuaryController.RUN_SPEED / 60.0 + 0.01, "No hay saltos ni vibraciones superiores a un frame")
	suite.check(InputMap.has_action("run") and InputMap.has_action("interact"), "Correr e interactuar están registrados como acciones")
	suite.check(controller.configure_world("valdoria"), "Se puede configurar el perfil explorable de Valdoria")
	suite.equal(controller.interaction_points.size(), 12, "Valdoria ofrece diez NPC, puerta de mazmorra y salida")
	suite.check(not controller.collides_with_world(controller.profile_start_position()), "La entrada de Valdoria es transitable")
	suite.check(controller.configure_world("dungeon"), "Se puede configurar el perfil de las catacumbas")
	suite.equal(controller.interaction_points.size(), 5, "La mazmorra ofrece sellos, objetos y salida interactivos")
	controller.free()

static func test_settings(suite: TestSuite) -> void:
	suite.section("Ajustes")
	var manager := SettingsManager.new()
	var sanitized := manager.sanitize({"master_volume": 9.0, "text_speed_index": -4, "resolution_index": 99})
	suite.equal(float(sanitized["master_volume"]), 1.0, "El volumen se limita al rango válido")
	suite.equal(int(sanitized["text_speed_index"]), 0, "La velocidad de texto se sanea")
	suite.equal(int(sanitized["resolution_index"]), SettingsManager.RESOLUTIONS.size() - 1, "La resolución se sanea")
	manager.values = sanitized
	manager.adjust("control_scheme", 1)
	suite.equal(InputMap.action_get_events("move_left").size(), 1, "El esquema WASD reasigna los controles")
	var path := "user://test_settings.json"
	suite.check(manager.save_settings(path), "Los ajustes se escriben")
	var loaded := SettingsManager.new()
	suite.check(loaded.load_settings(path), "Los ajustes se leen")
	suite.equal(loaded.values, manager.values, "Los ajustes sobreviven una lectura completa")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func test_save_system(suite: TestSuite) -> void:
	suite.section("Persistencia")
	var base_dir := "user://tests/save_suite_%d" % Time.get_ticks_usec()
	var payload := {
		"save_version": SaveSystem.CURRENT_VERSION,
		"chapter": 1,
		"gold": 25,
		"play_seconds": 120.0,
		"current_location": "valdoria",
		"party": GameDatabase.create_party(),
		"inventory": GameDatabase.create_initial_inventory(),
		"unlocked_locations": ["valdoria"]
	}
	for slot in range(1, 4):
		var slot_payload := payload.duplicate(true)
		slot_payload["chapter"] = slot
		suite.check(SaveSystem.save_to_slot(slot, slot_payload, base_dir), "Se escribe la ranura %d" % slot)
		suite.check(SaveSystem.has_slot(slot, base_dir), "La ranura %d queda disponible" % slot)
		suite.equal(int(SaveSystem.load_slot(slot, base_dir)["chapter"]), slot, "La ranura %d conserva su capítulo" % slot)
		suite.equal(int(SaveSystem.slot_metadata(slot, base_dir)["slot"]), slot, "La ranura %d contiene metadatos" % slot)
	suite.check(SaveSystem.save_autosave(payload, base_dir), "Se escribe el autoguardado")
	suite.equal(int(SaveSystem.load_autosave(base_dir)["chapter"]), 1, "El autoguardado se puede cargar")
	var legacy := {"chapter": 2, "current_location": "brumaforja", "save_version": 1}
	var migrated := SaveSystem.migrate_payload(legacy)
	suite.equal(int(migrated["save_version"]), SaveSystem.CURRENT_VERSION, "Una partida v1 migra hasta la versión actual")
	suite.check(migrated.has("city_dialogue_progress"), "La migración añade el progreso de diálogos")
	suite.check(migrated.has("facing_direction") and migrated.has("opened_interactions"), "La migración añade el estado de movimiento e interacciones")
	var phase_one_save := {"save_version": 2, "chapter": 4, "hero_position": [300.0, 400.0]}
	var phase_two_migration := SaveSystem.migrate_payload(phase_one_save)
	suite.equal(int(phase_two_migration["save_version"]), 5, "Una partida de fase 1 migra hasta fase 4")
	suite.equal(str(phase_two_migration["facing_direction"]), "south", "La migración proporciona una orientación segura")
	var phase_three_migration := SaveSystem.migrate_payload({"save_version": 3, "chapter": 4})
	suite.equal(int(phase_three_migration["save_version"]), 5, "Una partida de fase 2 migra a fase 4")
	suite.check(phase_three_migration.has("phase3_state") and phase_three_migration.has("dungeon_defeated"), "La migración añade progreso de misiones y encuentros")
	var phase_four_party := GameDatabase.create_party()
	for member in phase_four_party:
		if member is Dictionary:
			member.erase("element")
			member.erase("weapon")
			member.erase("weaknesses")
			member.erase("resistances")
	var phase_four_migration := SaveSystem.migrate_payload({"save_version":4, "party":phase_four_party})
	suite.equal(int(phase_four_migration["save_version"]), 5, "Una partida de fase 3 migra a fase 4")
	suite.check(phase_four_migration.has("resonance_tutorial_seen"), "La migración conserva el estado del tutorial de Resonancia")
	var migrated_hero: Dictionary = (phase_four_migration["party"] as Array)[0]
	suite.check(migrated_hero.has("element") and migrated_hero.has("weapon") and migrated_hero.has("weaknesses") and migrated_hero.has("resistances"), "La migración completa las afinidades del grupo")
	var backup_payload := payload.duplicate(true)
	backup_payload["chapter"] = 7
	suite.check(SaveSystem.save_to_slot(1, backup_payload, base_dir), "Una segunda escritura crea una copia de seguridad")
	var main_path := SaveSystem.slot_path(1, base_dir)
	var read_file := FileAccess.open(main_path, FileAccess.READ)
	var corrupted_envelope: Dictionary = JSON.parse_string(read_file.get_as_text()) as Dictionary
	read_file.close()
	corrupted_envelope["checksum"] = "checksum-invalido-controlado"
	var corrupt_file := FileAccess.open(main_path, FileAccess.WRITE)
	corrupt_file.store_string(JSON.stringify(corrupted_envelope))
	corrupt_file.close()
	suite.equal(int(SaveSystem.load_slot(1, base_dir)["chapter"]), 1, "Una ranura dañada se recupera desde la copia anterior")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main_path))
	suite.equal(int(SaveSystem.load_slot(1, base_dir)["chapter"]), 1, "Una copia sigue cargando si el archivo principal desaparece")
	suite.check(not FileAccess.file_exists(main_path + ".tmp"), "La escritura atómica no deja temporales")
	cleanup_test_directory(base_dir)

static func cleanup_test_directory(base_dir: String) -> void:
	var absolute := ProjectSettings.globalize_path(base_dir)
	var directory := DirAccess.open(base_dir)
	if directory != null:
		for file_name in directory.get_files():
			DirAccess.remove_absolute(absolute.path_join(file_name))
	DirAccess.remove_absolute(absolute)

static func test_logger(suite: TestSuite) -> void:
	suite.section("Registro centralizado")
	GameLogger.clear()
	GameLogger.info("test", "Evento controlado", {"value": 42})
	var recent := GameLogger.recent(1)
	suite.equal(recent.size(), 1, "El logger conserva el evento")
	suite.equal(str(recent[0]["category"]), "test", "El logger conserva la categoría")
	suite.equal(int(recent[0]["context"]["value"]), 42, "El logger conserva contexto estructurado")
