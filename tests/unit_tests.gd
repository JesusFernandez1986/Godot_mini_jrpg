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
	test_equipment_and_advancement(suite)
	test_phase5_balance_matrix(suite)
	test_phase6_narrative(suite)
	test_phase7_world_exploration(suite)
	test_phase8_living_cities(suite)
	test_phase9_dungeons(suite)
	test_phase10_eight_protagonists(suite)
	test_phase11_bestiary(suite)
	test_phase12_commerce(suite)
	test_phase13_factions(suite)
	test_phase14_endgame(suite)
	test_phase15_completion(suite)
	test_phase3_quests(suite)
	test_character_animation(suite)
	test_camera(suite)
	test_sanctuary_movement(suite)
	test_settings(suite)
	test_save_system(suite)
	test_logger(suite)

static func test_database(suite: TestSuite) -> void:
	suite.section("Recursos de datos")
	suite.equal(GameDatabase.CHARACTERS.size(), 8, "Hay ocho definiciones de protagonista")
	suite.equal(GameDatabase.ITEMS.size(), 7, "Hay cuatro objetos iniciales y tres materiales de fabricación")
	suite.equal(GameDatabase.EQUIPMENT.size(), 12, "Hay doce piezas de equipo de cinco rarezas")
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
	var directed := DialogueSystem.new()
	directed.begin([{"speaker":"Lyra", "text":"La estrella recuerda.", "expression":"worried", "camera":"close_up"}], "world_map", "test", "celestia")
	suite.equal(directed.current_pair(), ["Lyra", "La estrella recuerda."], "El diálogo acepta nodos externos estructurados")
	suite.equal(str(directed.current_metadata()["expression"]), "worried", "Los metadatos conservan expresión y dirección de escena")

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

static func test_equipment_and_advancement(suite: TestSuite) -> void:
	suite.section("Fase 5 · Equipamiento y progresión")
	var equipment := EquipmentSystem.create_state()
	var advancement := AdvancementSystem.create_state()
	var inventory := GameDatabase.create_initial_inventory()
	for material_name in ["Hierro resonante", "Hilo lunar", "Fragmento prismático"]:
		InventorySystem.add_item(inventory, material_name, GameDatabase.item_by_name(material_name), 20)
	suite.check(EquipmentSystem.validate(equipment).is_empty(), "El equipo inicial respeta propiedad, ranuras y compatibilidad")
	suite.check(AdvancementSystem.validate(advancement).is_empty(), "La progresión inicial tiene trabajos, artes y puntos válidos")
	EquipmentSystem.add_owned(equipment, "lion_mail")
	var preview := EquipmentSystem.preview(equipment, GameDatabase.create_party()[0], "lion_mail")
	suite.check(not preview.is_empty(), "Se comparan estadísticas antes de equipar")
	suite.check(int((preview["delta"] as Dictionary)["defense"]) > 0, "La comparación identifica una mejora defensiva")
	suite.check(bool(EquipmentSystem.equip(equipment, "aren", "armor", "lion_mail")["success"]), "Aren puede equipar una armadura compatible")
	suite.check(not bool(EquipmentSystem.equip(equipment, "lyra", "armor", "lion_mail")["success"]), "Una restricción impide equipo incompatible")
	var craft_result := EquipmentSystem.craft(equipment, inventory, "ward_charm", 500)
	suite.check(bool(craft_result["success"]), "El taller fabrica equipo consumiendo receta y oro")
	suite.equal(int(craft_result["gold"]), 425, "La fabricación descuenta su coste exacto")
	var upgrade_result := EquipmentSystem.upgrade(equipment, inventory, "iron_sword", 500)
	suite.check(bool(upgrade_result["success"]), "Se puede mejorar un arma poseída")
	suite.equal(int((equipment["owned"] as Dictionary)["iron_sword"]["upgrade"]), 1, "La mejora queda registrada")
	AdvancementSystem.grant_points(advancement, "aren", 10, 6)
	suite.check(bool(AdvancementSystem.set_job(advancement, "aren", "guardian")["success"]), "Los puntos desbloquean una especialización secundaria")
	for talent_id in ["aren_heart", "aren_edge", "aren_crown"]:
		suite.check(bool(AdvancementSystem.unlock_talent(advancement, "aren", talent_id)["success"]), "Se aprende %s respetando dependencias" % talent_id)
	suite.check(bool(AdvancementSystem.cycle_skill(advancement, "aren")["success"]), "Se selecciona una habilidad activa desbloqueada")
	suite.check(AdvancementSystem.set_formation(advancement, "vanguard"), "Se puede cambiar la formación del grupo")
	var party := full_test_party()
	EquipmentSystem.refresh_party_stats(party, equipment, advancement)
	var first_stats := [party[0]["max_hp"], party[0]["attack"], party[0]["defense"], party[0]["speed"]]
	EquipmentSystem.refresh_party_stats(party, equipment, advancement)
	suite.equal([party[0]["max_hp"], party[0]["attack"], party[0]["defense"], party[0]["speed"]], first_stats, "Recalcular equipo no acumula estadísticas infinitamente")
	suite.check("unyielding" in (party[0]["passives"] as Array), "Trabajos, talentos y equipo activan habilidades pasivas")
	suite.check(ProgressionSystem.validate_party(party).is_empty(), "El grupo equipado conserva estadísticas válidas")

static func test_phase5_balance_matrix(suite: TestSuite) -> void:
	suite.section("Fase 5 · Matriz de balance")
	var invalid_combinations := 0
	var excessive_damage := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5062026
	for combination in 1200:
		var equipment := EquipmentSystem.create_state()
		var advancement := AdvancementSystem.create_state()
		var party := full_test_party()
		for member in party: AdvancementSystem.grant_points(advancement, str(member["id"]), 20, 8)
		for item in GameDatabase.EQUIPMENT:
			EquipmentSystem.add_owned(equipment, item.id, 4)
			var owned_entry: Dictionary = (equipment["owned"] as Dictionary)[item.id]
			owned_entry["upgrade"] = combination % (item.max_upgrade + 1)
		var formation_ids := AdvancementSystem.FORMATIONS.keys()
		AdvancementSystem.set_formation(advancement, str(formation_ids[combination % formation_ids.size()]))
		var job_ids := AdvancementSystem.JOBS.keys()
		for member_index in party.size():
			var member: Dictionary = party[member_index]
			AdvancementSystem.set_job(advancement, str(member["id"]), str(job_ids[(combination + member_index) % job_ids.size()]))
			var weapon_options := EquipmentSystem.compatible_available(equipment, str(member["id"]), "weapon")
			if not weapon_options.is_empty(): EquipmentSystem.equip(equipment, str(member["id"]), "weapon", str(weapon_options[combination % weapon_options.size()]))
		EquipmentSystem.refresh_party_stats(party, equipment, advancement)
		if not EquipmentSystem.validate(equipment).is_empty() or not AdvancementSystem.validate(advancement).is_empty() or not ProgressionSystem.validate_party(party).is_empty(): invalid_combinations += 1
		for member in party:
			for stat in ["max_hp", "max_mp", "attack", "defense", "magic", "speed"]:
				if int(member[stat]) < 1 or int(member[stat]) > (9999 if stat == "max_hp" else 999): invalid_combinations += 1
		var state := PartyBattleSystem.create_battle(party, GameDatabase.enemy_by_id("hollow_lion"))
		var attacker: Dictionary = party[combination % party.size()]
		var hit := PartyBattleSystem.deal_enemy_damage(state, attacker, 31, "magic", str(attacker["element"]), rng)
		if int(hit["damage"]) < 0 or int(hit["damage"]) > 9999: excessive_damage += 1
	suite.equal(invalid_combinations, 0, "1.200 combinaciones no generan estadísticas negativas, inválidas o acumulativas")
	suite.equal(excessive_damage, 0, "1.200 combinaciones limitan el daño y evitan valores infinitos")

static func test_phase6_narrative(suite: TestSuite) -> void:
	suite.section("Fase 6 · Misiones y narrativa ramificada")
	var narrative := NarrativeSystem.new()
	suite.check(not narrative.data.is_empty(), "La narrativa se carga desde un archivo JSON externo")
	suite.check(narrative.validate_data().is_empty(), "Todas las escenas y destinos narrativos son válidos")
	for scene_id in narrative.data["scenes"] as Dictionary:
		var nodes: Dictionary = narrative.scene(str(scene_id))["nodes"]
		suite.equal(narrative.reachable_nodes(str(scene_id)).size(), nodes.size(), "Todas las ramas de %s son alcanzables" % scene_id)
	for branch_index in 2:
		var state := narrative.create_state()
		suite.check(bool(narrative.start_scene(state, "council_of_memory")["success"]), "El consejo puede comenzar por la rama %d" % branch_index)
		var guard := 0
		while narrative.current_choices(state).is_empty() and guard < 16:
			narrative.advance(state)
			guard += 1
		narrative.advance(state, branch_index)
		while not str(state["active_scene"]).is_empty() and guard < 32:
			narrative.advance(state)
			guard += 1
		var expected_path := "truth" if branch_index == 0 else "mercy"
		suite.equal(str((state["variables"] as Dictionary)["council_path"]), expected_path, "La decisión %s persiste" % expected_path)
		suite.equal(str((state["quests"] as Dictionary)["main_open_council"]["status"]), "completed", "La rama %s completa su misión" % expected_path)
		suite.check(("event_truth_path" if branch_index == 0 else "event_mercy_path") in (state["codex_unlocked"] as Array), "La rama %s desbloquea su códice" % expected_path)
	var personal_state := narrative.create_state()
	for scene_id in ["aren_memorial", "lyra_forbidden_map", "brom_last_bell", "seris_root_name"]:
		narrative.start_scene(personal_state, scene_id)
		var guard := 0
		while not str(personal_state["active_scene"]).is_empty() and guard < 32:
			var choices := narrative.current_choices(personal_state)
			narrative.advance(personal_state, 0 if not choices.is_empty() else -1)
			guard += 1
	suite.equal((personal_state["completed_scenes"] as Array).size(), 4, "Las cuatro misiones personales pueden iniciarse y completarse")
	var banter_state := narrative.create_state()
	var banter_id := narrative.next_banter(banter_state, "travel_banter")
	narrative.start_scene(banter_state, banter_id)
	while not str(banter_state["active_scene"]).is_empty(): narrative.advance(banter_state)
	suite.check(banter_id in (banter_state["seen_banter"] as Array), "Las conversaciones opcionales no se repiten")
	suite.check(narrative.validate_state(personal_state).is_empty(), "El estado narrativo completo puede persistirse")

static func test_phase7_world_exploration(suite: TestSuite) -> void:
	suite.section("Fase 7 · Mundo explorable")
	var state := WorldExplorationSystem.create_state()
	var locations := WorldExplorationSystem.all_locations(GameDatabase.locations())
	suite.equal(locations.size(), 11, "El mapa conecta cinco destinos principales y seis localizaciones de exploración")
	suite.check(WorldExplorationSystem.validate(state).is_empty(), "El estado mundial inicial cumple su contrato persistente")
	var start := WorldExplorationSystem.position(state)
	var moved := WorldExplorationSystem.move(state, Vector2.RIGHT, 1.0)
	suite.check(moved.x > start.x, "El grupo se mueve libremente sobre el mapa mundial")
	suite.check(int(state["steps"]) > 0, "El movimiento mundial registra pasos sin teletransportar al grupo")
	var initial_period := WorldExplorationSystem.period(state)
	WorldExplorationSystem.advance_time(state, 720.0)
	suite.check(WorldExplorationSystem.period(state) != initial_period, "El tiempo avanza entre día, atardecer y noche")
	for region_id in WorldExplorationSystem.REGIONS:
		suite.check(not WorldExplorationSystem.weather(state, str(region_id)).is_empty(), "%s mantiene clima regional determinista" % region_id)
	state["ship_unlocked"] = false
	suite.check(not WorldExplorationSystem.can_occupy(Vector2(850, 300), state), "El océano bloquea al grupo antes de conseguir un barco")
	state["ship_unlocked"] = true
	suite.check(WorldExplorationSystem.can_occupy(Vector2(850, 300), state), "El barco habilita el corredor marítimo oriental")
	var all_ids: Array[String] = []
	for location_value in locations:
		var location: Dictionary = location_value
		var id := str(location["id"])
		all_ids.append(id)
		WorldExplorationSystem.discover(state, id)
	state["ship_unlocked"] = true
	for destination_id in all_ids:
		suite.check(not WorldExplorationSystem.route_between("valdoria", destination_id, state, 6).is_empty(), "Existe una ruta válida de Valdoria a %s" % destination_id)
	var danger: Dictionary = WorldExplorationSystem.DANGER_ZONES[0]
	WorldExplorationSystem.set_position(state, danger["position"] as Vector2)
	suite.equal(str(WorldExplorationSystem.danger_at_position(state)["id"]), str(danger["id"]), "Las zonas de peligro producen encuentros visibles")
	WorldExplorationSystem.resolve_danger(state, str(danger["id"]))
	suite.check(WorldExplorationSystem.danger_at_position(state).is_empty(), "Un encuentro resuelto respeta su tiempo de reaparición")
	WorldExplorationSystem.set_position(state, Vector2(235, 300))
	var camp_result := WorldExplorationSystem.camp(state, locations)
	suite.check(bool(camp_result["success"]), "Se puede montar un campamento fuera de una zona peligrosa")
	suite.equal(int(float(state["clock_minutes"])), 360, "Acampar avanza hasta el amanecer")
	suite.check("valdoria" in (state["fast_travel"] as Array), "El campamento conserva un punto de viaje rápido")
	var brumaforja := TravelSystem.location_by_id(locations, "brumaforja")
	(state["fast_travel"] as Array).append("brumaforja")
	suite.check(bool(WorldExplorationSystem.fast_travel(state, brumaforja)["success"]), "El viaje rápido mueve el grupo entre refugios descubiertos")
	suite.equal(WorldExplorationSystem.position(state), brumaforja["position"], "El viaje rápido conserva el destino exacto")
	var stress_state := WorldExplorationSystem.create_state()
	for step_index in 6000:
		var direction: Vector2 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][(step_index / 375) % 4]
		WorldExplorationSystem.move(stress_state, direction, 1.0 / 60.0, step_index % 120 < 30)
	suite.check(WorldExplorationSystem.validate(stress_state).is_empty(), "Seis mil pasos no atraviesan límites ni corrompen hora, clima o retorno")

static func test_phase8_living_cities(suite: TestSuite) -> void:
	suite.section("Fase 8 · Ciudades vivas")
	var system := CityLifeSystem.new()
	suite.check(not system.data.is_empty(), "Las ciudades vivas se cargan desde datos externos")
	suite.check(system.validate_data().is_empty(), "Barrios, interiores, horarios y actividades referencian datos válidos")
	var state := system.create_state()
	for city_id_value in system.cities():
		var city_id := str(city_id_value)
		var city_data := system.city(city_id)
		suite.equal((city_data["districts"] as Array).size(), 3, "%s contiene tres barrios diferenciados" % city_id)
		var venue_kinds: Array[String] = []
		for district_value in city_data["districts"] as Array:
			for venue_value in (district_value as Dictionary)["venues"] as Array:
				var kind := str((venue_value as Dictionary)["kind"])
				if kind not in venue_kinds: venue_kinds.append(kind)
		for required_venue in CityLifeSystem.REQUIRED_VENUES:
			suite.check(required_venue in venue_kinds, "%s ofrece %s con interior propio" % [city_id, required_venue])
		suite.greater_or_equal(system.content_minutes(city_id), 30, "%s ofrece al menos treinta minutos de contenido distinto" % city_id)
		var scheduled_periods := 0
		for period in WorldExplorationSystem.PERIODS:
			var period_npcs: Array[String] = []
			for district_index in 3:
				(state["districts"] as Dictionary)[city_id] = district_index
				for npc_value in system.visible_npcs(state, city_id, period):
					var npc_id := str((npc_value as Dictionary)["id"])
					if npc_id not in period_npcs: period_npcs.append(npc_id)
				for venue_value in ((city_data["districts"] as Array)[district_index] as Dictionary)["venues"] as Array:
					system.enter_venue(state, city_id, str((venue_value as Dictionary)["id"]))
					for npc_value in system.visible_npcs(state, city_id, period):
						var npc_id := str((npc_value as Dictionary)["id"])
						if npc_id not in period_npcs: period_npcs.append(npc_id)
					system.leave_venue(state, city_id)
			if not period_npcs.is_empty(): scheduled_periods += 1
		suite.equal(scheduled_periods, 4, "%s mantiene habitantes localizables en los cuatro periodos del día" % city_id)
		(state["districts"] as Dictionary)[city_id] = 0
		var early := system.conversation(state, city_id, "día", int(city_data["required_chapter"]))
		var late := system.conversation(state, city_id, "día", 6)
		suite.equal((early["lines"] as Array).size(), 4, "%s ofrece conversaciones urbanas completas" % city_id)
		suite.check(str((early["lines"] as Array)[0][1]) != str((late["lines"] as Array)[0][1]), "%s cambia sus conversaciones con el progreso argumental" % city_id)
		var unlocked_by_rumor := 0
		for rumor_index in 3:
			var rumor := system.next_rumor(state, city_id)
			if not str(rumor.get("unlocks", "")).is_empty(): unlocked_by_rumor += 1
		suite.check(unlocked_by_rumor > 0, "Los rumores de %s revelan misiones o localizaciones" % city_id)
		var conflict_result: Dictionary = {}
		for conflict_stage in 3: conflict_result = system.advance_conflict(state, city_id)
		suite.check(bool(conflict_result.get("completed", false)), "El conflicto político de %s alcanza una resolución persistente" % city_id)
		var first_reward := false
		for challenge_index in 3:
			var challenge := system.activity_challenge(state, city_id)
			var activity_result := system.resolve_activity(state, city_id, int(challenge["answer"]))
			first_reward = first_reward or bool(activity_result["reward"])
		suite.check(first_reward, "La actividad característica de %s concede una recompensa única" % city_id)
		suite.check(not bool(system.resolve_activity(state, city_id, int(system.activity_challenge(state, city_id)["answer"]))["reward"]), "La recompensa de %s no puede duplicarse" % city_id)
	suite.check(system.validate_state(state).is_empty(), "Horarios, rumores, conflictos y actividades sobreviven en un estado urbano válido")

static func test_phase9_dungeons(suite: TestSuite) -> void:
	suite.section("Fase 9 · Mazmorras y exploración")
	suite.check(DungeonExplorationSystem.validate_definitions().is_empty(), "Las seis mazmorras y sus plantas cumplen el contrato de datos")
	suite.equal(DungeonExplorationSystem.DUNGEONS.size(), 6, "Las seis localizaciones especiales contienen una mazmorra completa")
	suite.equal(DungeonExplorationSystem.FLOOR_LAYOUTS.size(), 3, "Cada mazmorra dispone de tres niveles conectados")
	suite.equal(DungeonExplorationSystem.ABILITIES.size(), 8, "Cada protagonista aporta una capacidad de exploración propia")
	for floor_index in DungeonExplorationSystem.FLOOR_LAYOUTS.size():
		var entrance := DungeonExplorationSystem.find_tile(floor_index, DungeonExplorationSystem.TILE_START)
		var exit := DungeonExplorationSystem.find_tile(floor_index, DungeonExplorationSystem.TILE_EXIT)
		suite.check(DungeonExplorationSystem.path_exists(floor_index, entrance, exit), "La planta %d siempre conserva una ruta principal sin objetos perdibles" % (floor_index + 1))
	var used_abilities: Array[String] = []
	for dungeon_id in DungeonExplorationSystem.DUNGEON_IDS:
		var state := DungeonExplorationSystem.create_state()
		suite.check(bool(DungeonExplorationSystem.enter(state, dungeon_id)["success"]), "%s admite una entrada segura" % dungeon_id)
		suite.check(DungeonExplorationSystem.validate_state(state).is_empty(), "%s comienza con un estado persistente válido" % dungeon_id)
		var initial_percent := DungeonExplorationSystem.map_percentage(state)
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(0, "K"))
		suite.equal(str(DungeonExplorationSystem.interact(state).get("kind", "")), "key", "%s permite recoger llaves" % dungeon_id)
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(0, "M"))
		suite.equal(str(DungeonExplorationSystem.interact(state).get("kind", "")), "mechanism", "%s permite activar mecanismos sin consumir la salida" % dungeon_id)
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(0, "C"))
		suite.equal(str(DungeonExplorationSystem.interact(state).get("kind", "")), "shortcut", "%s conserva atajos desbloqueables" % dungeon_id)
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(0, "N"))
		suite.equal(str(DungeonExplorationSystem.interact(state).get("kind", "")), "chest", "%s contiene cofres normales" % dungeon_id)
		for floor_index in DungeonExplorationSystem.FLOOR_LAYOUTS.size():
			state["floor"] = floor_index
			state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(floor_index, "P"))
			var ability := DungeonExplorationSystem.puzzle_ability(dungeon_id, floor_index)
			if ability not in used_abilities: used_abilities.append(ability)
			var blocked := DungeonExplorationSystem.interact(state, [])
			suite.equal(str(blocked.get("kind", "")), "ability_required", "%s comunica la habilidad requerida en planta %d" % [dungeon_id, floor_index + 1])
			var solved := DungeonExplorationSystem.interact(state, [ability])
			suite.equal(str(solved.get("kind", "")), "puzzle", "%s resuelve el puzle de planta %d con la capacidad correcta" % [dungeon_id, floor_index + 1])
		state["floor"] = 1
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(1, "R"))
		suite.equal(str(DungeonExplorationSystem.interact(state).get("kind", "")), "secret_chest", "%s revela un cofre secreto opcional" % dungeon_id)
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(1, "T"))
		var trap := DungeonExplorationSystem.interact(state)
		suite.equal(str(trap.get("kind", "")), "trap", "%s incorpora trampas persistentes" % dungeon_id)
		suite.check(not bool(DungeonExplorationSystem.interact(state).get("success", true)), "La trampa de %s no se dispara dos veces" % dungeon_id)
		state["floor"] = 2
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(2, "B"))
		var miniboss := DungeonExplorationSystem.interact(state)
		suite.equal(str(miniboss.get("kind", "")), "miniboss", "%s ofrece un minijefe opcional" % dungeon_id)
		DungeonExplorationSystem.resolve_encounter(state, str(miniboss["encounter_id"]))
		state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(2, "X"))
		var secret_boss := DungeonExplorationSystem.interact(state)
		suite.equal(str(secret_boss.get("kind", "")), "secret_boss", "%s contiene un jefe secreto revelable" % dungeon_id)
		DungeonExplorationSystem.resolve_encounter(state, str(secret_boss["encounter_id"]), true)
		for floor_index in DungeonExplorationSystem.FLOOR_LAYOUTS.size():
			state["floor"] = floor_index
			state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.find_tile(floor_index, "E"))
			var transition := DungeonExplorationSystem.interact(state)
			if floor_index < DungeonExplorationSystem.FLOOR_LAYOUTS.size() - 1: suite.equal(str(transition.get("kind", "")), "floor", "%s conecta la planta %d" % [dungeon_id, floor_index + 1])
			else: suite.equal(str(transition.get("kind", "")), "complete", "%s puede completarse sin un objeto perdible" % dungeon_id)
		suite.check(dungeon_id in (state["completed_dungeons"] as Array), "%s registra su finalización" % dungeon_id)
		suite.check(DungeonExplorationSystem.map_percentage(state) >= initial_percent, "%s conserva un porcentaje de descubrimiento monotónico" % dungeon_id)
		suite.check(DungeonExplorationSystem.validate_state(state).is_empty(), "%s termina en un estado guardable" % dungeon_id)
	suite.equal(used_abilities.size(), 8, "Los ocho talentos de exploración intervienen en puzles reales")

static func test_phase10_eight_protagonists(suite: TestSuite) -> void:
	suite.section("Fase 10 · Ocho protagonistas y sus historias")
	var system := HeroStorySystem.new()
	suite.check(system.validate_data().is_empty(), "El archivo narrativo de los ocho protagonistas es válido")
	suite.equal((system.data["heroes"] as Dictionary).size(), 8, "Hay ocho protagonistas jugables")
	var total_chapters := 0
	for hero_id in HeroStorySystem.HERO_ORDER:
		var hero := system.hero(hero_id)
		suite.equal((hero["chapters"] as Array).size(), 4, "%s dispone de cuatro capítulos personales" % hero_id)
		suite.check(not str(hero["conflict"]).is_empty() and not str(hero["antagonist"]).is_empty() and not str(hero["boss"]).is_empty(), "%s tiene conflicto, antagonista y jefe propios" % hero_id)
		total_chapters += (hero["chapters"] as Array).size()
	suite.equal(total_chapters, 32, "La fase contiene al menos los 32 capítulos personales comprometidos")
	suite.check(system.dialogue_count() >= 200, "Las historias añaden más de doscientas intervenciones narrativas")
	var state := system.create_state()
	for hero_id in HeroStorySystem.HERO_ORDER:
		for raw_chapter in system.hero(hero_id)["chapters"] as Array:
			var chapter_id := str((raw_chapter as Dictionary)["id"])
			suite.check(system.can_start_chapter(state, chapter_id), "%s se desbloquea sin saltos imposibles" % chapter_id)
			suite.check(bool(system.start_chapter(state, chapter_id)["success"]), "%s puede comenzar" % chapter_id)
			var lines := system.chapter_dialogue_lines(chapter_id)
			suite.equal(lines.size(), 5, "%s contiene planteamiento, conflicto, antagonista, revelación y cierre" % chapter_id)
			suite.check(bool(system.complete_chapter(state, chapter_id, "truth")["success"]), "%s puede completarse" % chapter_id)
	suite.equal(system.completed_chapter_count(state), 32, "Los 32 capítulos quedan registrados de forma independiente")
	suite.equal((state["unlocked_heroes"] as Array).size(), 8, "Completar los prólogos recluta a los ocho protagonistas")
	suite.equal(str(state["finale_status"]), "available", "Los 32 capítulos abren el final común")
	for raw_cross in system.data["cross_quests"] as Array:
		var cross_id := str((raw_cross as Dictionary)["id"])
		suite.check(cross_id in (state["unlocked_cross_quests"] as Array), "%s enlaza varias historias completadas" % cross_id)
		suite.equal(system.cross_dialogue_lines(cross_id).size(), 4, "%s contiene una conversación cruzada completa" % cross_id)
		suite.check(bool(system.complete_cross_quest(state, cross_id)["success"]), "%s persiste su resolución" % cross_id)
	var released_state := state.duplicate(true)
	var shared_state := state.duplicate(true)
	var released := system.complete_finale(released_state, "released")
	var shared := system.complete_finale(shared_state, "shared")
	suite.check(bool(released["success"]) and bool(shared["success"]), "El capítulo final común admite desenlaces persistentes")
	suite.equal((released_state["epilogues"] as Dictionary).size(), 8, "El final escribe un epílogo para cada protagonista")
	suite.check(str((released_state["epilogues"] as Dictionary)["aren"]) != str((shared_state["epilogues"] as Dictionary)["aren"]), "Los epílogos cambian según la decisión final")
	var roster := full_test_party()
	for member in roster: (member as Dictionary)["active"] = false
	for index in 4: (roster[index] as Dictionary)["active"] = true
	suite.equal(HeroStorySystem.active_party(roster).size(), 4, "La formación admite exactamente cuatro héroes activos")
	suite.check(not bool(HeroStorySystem.toggle_active(roster, "naia")["success"]), "No se puede superar el límite de cuatro miembros activos")
	suite.check(bool(HeroStorySystem.toggle_active(roster, "aren")["success"]), "Un héroe puede pasar a la reserva")
	suite.check(bool(HeroStorySystem.toggle_active(roster, "naia")["success"]), "Un protagonista nuevo puede entrar en el grupo activo")
	var battle := PartyBattleSystem.create_battle(roster, GameDatabase.enemy_by_id("crypt_rat"))
	suite.check(not (battle["allies"] as Array).filter(func(member: Dictionary): return str(member["id"]) == "naia").is_empty(), "Los nuevos protagonistas son jugables en combate")
	for index in range(4, 8):
		for animation_state in CharacterAnimationSystem.STATES:
			var region := CharacterAnimationSystem.atlas_region(index, "south", animation_state, 0.2)
			suite.check(region.position.x >= 0.0 and region.end.x <= 1536.0 and region.position.y >= 0.0 and region.end.y <= 1280.0, "El protagonista %d anima %s dentro del atlas" % [index + 1, animation_state])
	suite.check(system.validate_state(released_state).is_empty(), "Historias, vínculos y epílogos producen un estado guardable")

static func test_phase11_bestiary(suite: TestSuite) -> void:
	suite.section("Fase 11 · Bestiario, élites y cacerías")
	suite.equal(BestiarySystem.catalog().size(), 32, "El bestiario contiene 32 criaturas y variantes")
	suite.equal(BestiarySystem.ELITE_AFFIXES.size(), 8, "Hay ocho afijos de élite diferenciados")
	suite.check(BestiarySystem.validate_definitions().is_empty(), "El catálogo no contiene identificadores duplicados")
	var state := BestiarySystem.create_state()
	var rat := GameDatabase.enemy_by_id("crypt_rat")
	BestiarySystem.observe(state, rat)
	suite.equal(int(((state["records"] as Dictionary)["crypt_rat"] as Dictionary)["seen"]), 1, "Observar registra la criatura")
	suite.check(bool(BestiarySystem.scan(state, "crypt_rat")["success"]), "Analizar revela sus afinidades")
	BestiarySystem.record_defeat(state, rat)
	suite.equal(int(state["total_defeated"]), 1, "La victoria alimenta el registro global")
	var elite := BestiarySystem.create_variant("crypt_rat", 1)
	suite.check(int(elite["max_hp"]) > int(rat["max_hp"]) and not str(elite.get("elite_affix", "")).is_empty(), "Una variante escala estadísticas y conserva su afijo")
	for kill in 2: BestiarySystem.record_defeat(state, rat)
	var claim := BestiarySystem.claim_contract(state, "hunt_02")
	suite.check(bool(claim["success"]) and int(claim["gold"]) > 0, "Los contratos completados conceden recompensa")
	suite.check(not bool(BestiarySystem.claim_contract(state, "hunt_02")["success"]), "Un contrato no puede cobrarse dos veces")
	suite.check(BestiarySystem.validate_state(state).is_empty(), "El progreso del bestiario mantiene sus invariantes")

static func test_phase12_commerce(suite: TestSuite) -> void:
	suite.section("Fase 12 · Economía, mercados y recolección")
	var state := CommerceSystem.create_state()
	var inventory := GameDatabase.create_initial_inventory()
	var equipment := EquipmentSystem.create_state()
	suite.equal(CommerceSystem.CITIES.size(), 4, "Las cuatro ciudades tienen economía propia")
	suite.equal(CommerceSystem.GATHERING_NODES.size(), 8, "Existen ocho nodos de recursos renovables")
	var price_before := CommerceSystem.price(state, "valdoria", CommerceSystem.stock(state, "valdoria")[0])
	var bought := CommerceSystem.buy(state, "valdoria", 0, 500, inventory, equipment)
	suite.check(bool(bought["success"]) and int(bought["gold"]) < 500, "Comprar descuenta oro y entrega el producto")
	suite.check(CommerceSystem.price(state, "valdoria", CommerceSystem.stock(state, "valdoria")[0]) > price_before, "La demanda modifica el precio local")
	var gathered := CommerceSystem.gather(state, "prism_geode", inventory)
	suite.check(bool(gathered["success"]) and inventory.has("Fragmento prismático"), "La recolección entrega materiales válidos")
	suite.check(not bool(CommerceSystem.gather(state, "prism_geode", inventory)["success"]), "Un nodo no se explota dos veces el mismo día")
	suite.check(bool(CommerceSystem.negotiate(state, "valdoria", 99)["success"]), "Una negociación competente mejora la reputación comercial")
	CommerceSystem.advance_day(state, 2)
	suite.equal(int((CommerceSystem.stock(state, "valdoria")[0] as Dictionary)["quantity"]), int((CommerceSystem.stock(state, "valdoria")[0] as Dictionary)["max_quantity"]), "El mercado repone existencias cada dos días")
	suite.check(CommerceSystem.validate_state(state).is_empty(), "La economía conserva cantidades y mercados válidos")

static func test_phase13_factions(suite: TestSuite) -> void:
	suite.section("Fase 13 · Facciones y misiones secundarias")
	suite.equal(FactionSystem.FACTIONS.size(), 4, "Eryndor contiene cuatro facciones con territorio")
	suite.equal(FactionSystem.quests().size(), 24, "Hay seis misiones encadenadas por facción")
	var state := FactionSystem.create_state()
	suite.equal(FactionSystem.journal_entries(state).size(), 4, "El diario comienza con un encargo por facción")
	suite.check(bool(FactionSystem.accept(state, "lion_crown_01")["success"]), "Se puede aceptar un encargo disponible")
	var midpoint := FactionSystem.advance(state, "lion_crown_01")
	suite.check(bool(midpoint["success"]) and not bool(midpoint["completed"]), "La misión avanza por varias etapas")
	var completed := FactionSystem.advance(state, "lion_crown_01", "concord")
	suite.check(bool(completed["completed"]) and int(completed["gold"]) > 0, "Resolver la etapa final concede oro y reputación")
	suite.equal(str((state["quest_status"] as Dictionary)["lion_crown_02"]), "available", "Completar un capítulo abre el siguiente")
	suite.check(FactionSystem.dialogue_lines("lion_crown_01").size() >= 4, "Cada encargo posee una escena narrativa")
	suite.check(FactionSystem.validate_definitions().is_empty() and FactionSystem.validate_state(state).is_empty(), "Definiciones y progreso de facciones son válidos")

static func test_phase14_endgame(suite: TestSuite) -> void:
	suite.section("Fase 14 · Arena, superjefes y Nueva Partida +")
	suite.equal(EndgameSystem.arena_trials().size(), 25, "La Arena de los Ecos contiene 25 pruebas")
	suite.equal(EndgameSystem.SUPERBOSSES.size(), 8, "Existen ocho superjefes opcionales")
	suite.equal(EndgameSystem.challenges().size(), 20, "El endgame incorpora veinte desafíos especiales")
	var state := EndgameSystem.create_state()
	suite.check(not bool(EndgameSystem.start_arena_trial(state)["success"]), "La arena permanece sellada antes del final")
	EndgameSystem.unlock(state)
	var first_trial := EndgameSystem.start_arena_trial(state)
	suite.check(bool(first_trial["success"]) and str(first_trial["enemy"]) != "", "El final común abre un combate de arena real")
	var enemy := GameDatabase.enemy_by_id(str(first_trial["enemy"]))
	var base_hp := int(enemy["max_hp"])
	EndgameSystem.apply_scaling(enemy, float(first_trial["scale"]), state)
	suite.check(int(enemy["max_hp"]) > base_hp, "Las pruebas escalan enemigos sin romper su contrato de combate")
	for floor in 25: EndgameSystem.record_arena_victory(state)
	suite.equal((state["arena_cleared"] as Array).size(), 25, "Las 25 victorias quedan registradas sin duplicados")
	var superboss := EndgameSystem.start_superboss(state, 0)
	suite.check(bool(superboss["success"]) and float(superboss["scale"]) > 2.0, "Los superjefes usan encuentros de rango final")
	EndgameSystem.record_superboss_victory(state, str(superboss["superboss_id"]))
	suite.check(bool(EndgameSystem.start_new_game_plus(state)["success"]) and int(state["ng_plus_cycle"]) == 1, "Completar la arena habilita Nueva Partida +")
	suite.check(EndgameSystem.validate_definitions().is_empty() and EndgameSystem.validate_state(state).is_empty(), "El endgame conserva todas sus invariantes")

static func test_phase15_completion(suite: TestSuite) -> void:
	suite.section("Fase 15 · Logros, accesibilidad y lanzamiento")
	suite.equal(CompletionSystem.achievements().size(), 40, "La versión final incluye cuarenta logros")
	var state := CompletionSystem.create_state()
	var unlocked := CompletionSystem.synchronize(state, {"defeated":100, "elite":10, "bestiary":32, "gold":1500, "cities":4, "heroes":8, "hero_chapters":32, "finale":1, "dungeons":6, "factions":24, "arena":25, "superbosses":8, "ng_plus":1, "legacy":25, "max_level":25})
	suite.check(unlocked.size() >= 15 and "bestiary_all" in (state["unlocked"] as Array), "El sincronizador desbloquea hitos desde el progreso real")
	suite.check(bool(CompletionSystem.toggle_accessibility(state, "reduced_motion")["success"]) and bool((state["accessibility"] as Dictionary)["reduced_motion"]), "Movimiento reducido se activa durante la partida")
	suite.equal(CompletionSystem.translate(state, "bestiary"), "Bestiario", "La interfaz española está disponible")
	CompletionSystem.cycle_language(state)
	suite.equal(CompletionSystem.translate(state, "bestiary"), "Bestiary", "La interfaz inglesa está disponible")
	var release_states := {"bestiary":BestiarySystem.create_state(), "commerce":CommerceSystem.create_state(), "factions":FactionSystem.create_state(), "endgame":EndgameSystem.create_state()}
	suite.check(CompletionSystem.release_audit(release_states).is_empty(), "La auditoría de lanzamiento comprueba los sistemas persistentes")
	suite.check(CompletionSystem.validate_definitions().is_empty() and CompletionSystem.validate_state(state).is_empty(), "Logros, idiomas y accesibilidad superan validación")

static func full_test_party() -> Array:
	var party := GameDatabase.create_party()
	for index in party.size():
		var member: Dictionary = party[index]
		member["joined"] = true
		member["active"] = index < PartyBattleSystem.MAX_ACTIVE_ALLIES
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
	suite.check(AnimationFXSystem.validate().is_empty(), "Los ocho protagonistas tienen perfiles de movimiento válidos")
	var atlas: Texture2D = load("res://assets/party_animation_atlas_v2.png") as Texture2D
	suite.equal(atlas.get_width(), 1536, "El atlas conserva su anchura de producción")
	suite.equal(atlas.get_height(), 1280, "El atlas contiene ocho filas direccionales sin solapamientos")
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
			var left := int(region.position.x)
			var top := int(region.position.y)
			var right := int(region.end.x) - 1
			var bottom := int(region.end.y) - 1
			var clear_border := true
			for x in range(left, right + 1):
				clear_border = clear_border and atlas_image.get_pixel(x, top).a < 0.05 and atlas_image.get_pixel(x, bottom).a < 0.05
			for y in range(top, bottom + 1):
				clear_border = clear_border and atlas_image.get_pixel(left, y).a < 0.05 and atlas_image.get_pixel(right, y).a < 0.05
			suite.check(clear_border, "Personaje %d/%s no invade celdas vecinas" % [character_index, direction])
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
	for state in CharacterAnimationSystem.ONE_SHOT_DURATIONS:
		var last_sequence_index := CharacterAnimationSystem.frame_sequence(state, 3).size() - 1
		suite.equal(CharacterAnimationSystem.sequence_index(state, 99.0, 3), last_sequence_index, "La acción %s termina en su pose final sin reiniciarse" % state)
	for character_index in 8:
		var walk_pose := AnimationFXSystem.pose_scale("walk", 0.2, character_index)
		suite.check(walk_pose.x > 0.9 and walk_pose.y > 0.9, "El perfil animado de protagonista %d conserva una escala segura" % (character_index + 1))
	suite.check(not AnimationFXSystem.interaction_spark_positions(Vector2.ZERO, "special", 0.3, 0).is_empty(), "Las acciones especiales generan partículas visibles")
	suite.check(CombatPresentationSystem.validate().is_empty(), "Los efectos elementales ocupan regiones válidas del atlas")
	suite.check(CombatPresentationSystem.hit_stop_seconds(40, true) > CombatPresentationSystem.hit_stop_seconds(40, false), "Explotar una debilidad refuerza el impacto sin bloquear el combate")
	suite.equal(CombatPresentationSystem.shake_amplitude(99, false, true), 0.0, "Movimiento reducido desactiva la sacudida de cámara")
	for element in CombatPresentationSystem.ELEMENT_COLORS:
		suite.check(CombatPresentationSystem.effect_frame(element, 0.5) in range(16), "El efecto %s usa una celda gráfica válida" % element)
	suite.check(VerticalSliceSystem.validate().is_empty(), "La vertical slice define hitos únicos y legibles")
	var vertical_state := QuestSystem.create_phase3_state()
	suite.equal(str(VerticalSliceSystem.next_milestone(vertical_state, [], DungeonExplorationSystem.create_state())["id"]), "oath", "La demo dirige primero al juramento de Elara")
	QuestSystem.accept_main(vertical_state)
	suite.check(VerticalSliceSystem.completion_percent(vertical_state, [], DungeonExplorationSystem.create_state()) > 0.0, "Aceptar la misión actualiza el progreso visible de la demo")
	suite.check("RUPTURA" in VerticalSliceSystem.boss_directive(2, 0), "El jefe comunica su ventana táctica de ruptura")
	suite.check(WorldPresentationSystem.validate().is_empty(), "Profundidad y ciclos ambientales son coherentes")
	suite.check(WorldPresentationSystem.depth_scale(450.0) > WorldPresentationSystem.depth_scale(120.0), "Los personajes cercanos se renderizan a mayor escala")
	var patrol_origin := Vector2(500, 300)
	suite.check(WorldPresentationSystem.npc_patrol_position(patrol_origin, 1, 0.0, "día") != WorldPresentationSystem.npc_patrol_position(patrol_origin, 1, 1.0, "día"), "Los NPC recorren rutas animadas")
	suite.check(WorldPresentationSystem.weather_density("tormenta") > WorldPresentationSystem.weather_density("lluvia suave"), "La tormenta incrementa la densidad de partículas")
	suite.check(NarrativeDirectionSystem.validate().is_empty(), "Las expresiones narrativas tienen una dirección visual consistente")
	var consequence_choice := {"effects":[{"op":"inc", "key":"valor", "value":1}]}
	suite.check("valor +1" in NarrativeDirectionSystem.choice_hint(consequence_choice), "Las elecciones anticipan su consecuencia principal")
	var directed_party := full_test_party()
	var directed_hero_state := HeroStorySystem.new().create_state()
	suite.check(not NarrativeDirectionSystem.apply_choice_bond(directed_hero_state, directed_party, "Lyra", consequence_choice).is_empty(), "Una respuesta dirigida fortalece vínculos entre protagonistas")
	suite.check("Vínculo más fuerte" in NarrativeDirectionSystem.relationship_recap(directed_hero_state), "El diario puede resumir las relaciones del grupo")
	var unique_layouts: Array[String] = []
	for dungeon_id in DungeonExplorationSystem.DUNGEON_IDS:
		var layout_signature := "|".join(DungeonExplorationSystem.floor_layout(1, dungeon_id))
		if layout_signature not in unique_layouts: unique_layouts.append(layout_signature)
		suite.check(not DungeonExplorationSystem.theme(dungeon_id).is_empty(), "%s dispone de paleta ambiental propia" % dungeon_id)
	suite.equal(unique_layouts.size(), DungeonExplorationSystem.DUNGEON_IDS.size(), "Las seis mazmorras tienen topologías diferenciadas")
	var patrol_state := DungeonExplorationSystem.create_state()
	DungeonExplorationSystem.enter(patrol_state, "eira_ruins")
	patrol_state["position"] = DungeonExplorationSystem.vector_to_array(DungeonExplorationSystem.PATROL_CELLS[0] - Vector2i.RIGHT)
	var patrol_step := DungeonExplorationSystem.move(patrol_state, Vector2i.RIGHT)
	suite.equal(str(patrol_step.get("kind", "")), "encounter", "Las patrullas visibles activan combate al alcanzarlas")
	DungeonExplorationSystem.resolve_encounter(patrol_state, str(patrol_step.get("encounter_id", "")))
	suite.check(DungeonExplorationSystem.patrol_at(patrol_state, 0, DungeonExplorationSystem.PATROL_CELLS[0]).is_empty(), "Una patrulla derrotada desaparece de la mazmorra")

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
	suite.equal(int(phase_two_migration["save_version"]), SaveSystem.CURRENT_VERSION, "Una partida de fase 1 migra hasta las fases 5 y 6")
	suite.equal(str(phase_two_migration["facing_direction"]), "south", "La migración proporciona una orientación segura")
	var phase_three_migration := SaveSystem.migrate_payload({"save_version": 3, "chapter": 4})
	suite.equal(int(phase_three_migration["save_version"]), SaveSystem.CURRENT_VERSION, "Una partida de fase 2 migra hasta las fases 5 y 6")
	suite.check(phase_three_migration.has("phase3_state") and phase_three_migration.has("dungeon_defeated"), "La migración añade progreso de misiones y encuentros")
	var phase_four_party := GameDatabase.create_party()
	for member in phase_four_party:
		if member is Dictionary:
			member.erase("element")
			member.erase("weapon")
			member.erase("weaknesses")
			member.erase("resistances")
	var phase_four_migration := SaveSystem.migrate_payload({"save_version":4, "party":phase_four_party})
	suite.equal(int(phase_four_migration["save_version"]), SaveSystem.CURRENT_VERSION, "Una partida de fase 3 migra hasta las fases 5 y 6")
	suite.check(phase_four_migration.has("resonance_tutorial_seen"), "La migración conserva el estado del tutorial de Resonancia")
	var migrated_hero: Dictionary = (phase_four_migration["party"] as Array)[0]
	suite.check(migrated_hero.has("element") and migrated_hero.has("weapon") and migrated_hero.has("weaknesses") and migrated_hero.has("resistances"), "La migración completa las afinidades del grupo")
	suite.check(phase_four_migration.has("equipment_state") and phase_four_migration.has("advancement_state") and phase_four_migration.has("narrative_state"), "La migración añade equipo, progresión y narrativa persistente")
	var phase_seven_migration := SaveSystem.migrate_payload({"save_version":7, "chapter":5, "current_location":"celestia"})
	suite.equal(int(phase_seven_migration["save_version"]), SaveSystem.CURRENT_VERSION, "Una partida de fase 6 migra hasta las fases 7 y 8")
	suite.check(phase_seven_migration.has("world_exploration_state") and WorldExplorationSystem.validate(phase_seven_migration["world_exploration_state"] as Dictionary).is_empty(), "La migración añade posición, hora, clima, campamentos y transporte")
	var phase_eight_migration := SaveSystem.migrate_payload({"save_version":8, "chapter":5, "current_location":"brumaforja", "world_exploration_state":WorldExplorationSystem.create_state()})
	suite.check(phase_eight_migration.has("city_life_state") and phase_eight_migration.has("scene_state"), "La migración añade barrios, interiores, horarios y estado de escena")
	suite.check(CityLifeSystem.new().validate_state(phase_eight_migration["city_life_state"] as Dictionary).is_empty(), "El estado urbano migrado es válido")
	var phase_nine_migration := SaveSystem.migrate_payload({"save_version":9, "party":GameDatabase.create_party()})
	suite.check(phase_nine_migration.has("dungeon_exploration_state") and DungeonExplorationSystem.validate_state(phase_nine_migration["dungeon_exploration_state"] as Dictionary).is_empty(), "Una partida v9 migra las mazmorras multinivel")
	var old_four_party := GameDatabase.create_party().slice(0, 4)
	var phase_ten_migration := SaveSystem.migrate_payload({"save_version":10, "party":old_four_party, "dungeon_exploration_state":DungeonExplorationSystem.create_state()})
	suite.equal((phase_ten_migration["party"] as Array).size(), 8, "Una partida v10 incorpora los cuatro protagonistas nuevos sin perder el grupo anterior")
	suite.check(phase_ten_migration.has("hero_story_state") and HeroStorySystem.new().validate_state(phase_ten_migration["hero_story_state"] as Dictionary).is_empty(), "La migración v11 añade historias, vínculos, final y epílogos")
	var phase_eleven_migration := SaveSystem.migrate_payload({"save_version":11, "party":GameDatabase.create_party()})
	suite.check(phase_eleven_migration.has("bestiary_state") and BestiarySystem.validate_state(phase_eleven_migration["bestiary_state"] as Dictionary).is_empty(), "La migración v12 incorpora el bestiario")
	suite.check(phase_eleven_migration.has("commerce_state") and CommerceSystem.validate_state(phase_eleven_migration["commerce_state"] as Dictionary).is_empty(), "La migración v13 incorpora mercados y recolección")
	suite.check(phase_eleven_migration.has("faction_state") and FactionSystem.validate_state(phase_eleven_migration["faction_state"] as Dictionary).is_empty(), "La migración v14 incorpora las facciones")
	suite.check(phase_eleven_migration.has("endgame_state") and EndgameSystem.validate_state(phase_eleven_migration["endgame_state"] as Dictionary).is_empty(), "La migración v15 incorpora arena y NG+")
	suite.check(phase_eleven_migration.has("completion_state") and CompletionSystem.validate_state(phase_eleven_migration["completion_state"] as Dictionary).is_empty(), "La migración v16 incorpora logros y accesibilidad")
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
