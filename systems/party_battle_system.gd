class_name PartyBattleSystem
extends RefCounted

const MAX_ACTIVE_ALLIES := 4
const MAX_RESONANCE := 5
const COMBO_COST := 3
const STATUS_IDS := ["poison", "silence", "sleep", "fear", "blind", "regeneration"]
const ACTION_IDS := ["attack", "art", "heal", "defend", "item", "switch", "combo", "flee"]

static func create_battle(party: Array, enemy: Dictionary) -> Dictionary:
	var allies: Array = []
	var ally_statuses: Dictionary = {}
	for member in party:
		if member is Dictionary and bool(member.get("joined", false)) and allies.size() < MAX_ACTIVE_ALLIES:
			allies.append(member)
			ally_statuses[str(member.get("id", allies.size()))] = {}
	if allies.is_empty() and not party.is_empty() and party[0] is Dictionary:
		allies.append(party[0])
		ally_statuses[str((party[0] as Dictionary).get("id", "aren"))] = {}
	var runtime_enemy := enemy.duplicate(true)
	runtime_enemy["hp"] = int(runtime_enemy.get("hp", runtime_enemy.get("max_hp", 1)))
	runtime_enemy["max_hp"] = maxi(1, int(runtime_enemy.get("max_hp", runtime_enemy["hp"])))
	var shield_max := maxi(1, int(runtime_enemy.get("break_shield", 2)))
	var state := {
		"allies": allies,
		"ally_statuses": ally_statuses,
		"enemy": runtime_enemy,
		"enemy_statuses": {},
		"queue": [],
		"queue_cursor": 0,
		"turn_prepared": false,
		"round": 1,
		"turns_taken": 0,
		"resonance": 0,
		"shield": shield_max,
		"shield_max": shield_max,
		"broken_turns": 0,
		"enemy_phase": 1,
		"ai_cursor": {1: 0, 2: 0, 3: 0},
		"defending": {},
		"outcome": "ongoing",
		"loot": [],
		"combat_log": [],
		"last_action": {},
		"last_enemy_target": "",
		"flee_attempts": 0
	}
	build_round_queue(state)
	return state

static func build_round_queue(state: Dictionary) -> void:
	var entries: Array[Dictionary] = []
	for member in state["allies"] as Array:
		if int(member.get("hp", 0)) > 0:
			entries.append({"id": ally_actor_id(member), "speed": int(member.get("speed", 1))})
	var enemy: Dictionary = state["enemy"]
	if int(enemy.get("hp", 0)) > 0:
		entries.append({"id": "enemy", "speed": int(enemy.get("speed", 8))})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["speed"]) == int(b["speed"]): return str(a["id"]) < str(b["id"])
		return int(a["speed"]) > int(b["speed"])
	)
	var queue: Array = []
	for entry in entries:
		queue.append(entry["id"])
	state["queue"] = queue
	state["queue_cursor"] = 0
	state["turn_prepared"] = false

static func ally_actor_id(member: Dictionary) -> String:
	return "ally:" + str(member.get("id", member.get("name", "unknown")))

static func current_actor_id(state: Dictionary) -> String:
	var queue: Array = state.get("queue", [])
	if queue.is_empty(): return ""
	return str(queue[clampi(int(state.get("queue_cursor", 0)), 0, queue.size() - 1)])

static func visible_turn_order(state: Dictionary, count: int = 6) -> Array[String]:
	var result: Array[String] = []
	var queue: Array = state.get("queue", [])
	if queue.is_empty(): return result
	var cursor := int(state.get("queue_cursor", 0))
	while result.size() < count:
		for i in range(cursor, queue.size()):
			result.append(str(queue[i]))
			if result.size() >= count: break
		cursor = 0
	return result

static func current_ally(state: Dictionary) -> Dictionary:
	var actor_id := current_actor_id(state)
	if not actor_id.begins_with("ally:"): return {}
	return ally_by_actor_id(state, actor_id)

static func ally_by_actor_id(state: Dictionary, actor_id: String) -> Dictionary:
	for member in state["allies"] as Array:
		if ally_actor_id(member) == actor_id:
			return member
	return {}

static func living_allies(state: Dictionary) -> Array:
	return (state["allies"] as Array).filter(func(member: Dictionary): return int(member.get("hp", 0)) > 0)

static func resolve_until_player(state: Dictionary, rng: RandomNumberGenerator) -> Array[String]:
	var messages: Array[String] = []
	var guard := 0
	while str(state.get("outcome", "ongoing")) == "ongoing" and guard < 32:
		guard += 1
		check_outcome(state, rng)
		if str(state["outcome"]) != "ongoing": break
		var actor_id := current_actor_id(state)
		if actor_id.is_empty():
			build_round_queue(state)
			continue
		if bool(state.get("turn_prepared", false)) and actor_id.begins_with("ally:"):
			break
		if actor_id == "enemy":
			var enemy: Dictionary = state["enemy"]
			var tick := tick_statuses(enemy, state["enemy_statuses"] as Dictionary, rng)
			messages.append_array(tick["messages"] as Array[String])
			if int(enemy["hp"]) <= 0:
				check_outcome(state, rng)
				break
			if int(state.get("broken_turns", 0)) > 0:
				messages.append("%s está en ruptura y pierde su turno." % str(enemy["name"]))
				state["broken_turns"] = int(state["broken_turns"]) - 1
				if int(state["broken_turns"]) <= 0:
					state["shield"] = int(state["shield_max"])
			elif not bool(tick["skip"]):
				messages.append(enemy_turn(state, rng))
			else:
				messages.append("%s no puede actuar." % str(enemy["name"]))
			advance_actor(state)
			continue
		var ally := ally_by_actor_id(state, actor_id)
		if ally.is_empty() or int(ally.get("hp", 0)) <= 0:
			advance_actor(state)
			continue
		var statuses: Dictionary = (state["ally_statuses"] as Dictionary).get(str(ally["id"]), {})
		var ally_tick := tick_statuses(ally, statuses, rng)
		messages.append_array(ally_tick["messages"] as Array[String])
		if int(ally["hp"]) <= 0 or bool(ally_tick["skip"]):
			if bool(ally_tick["skip"]): messages.append("%s pierde su turno." % str(ally["name"]))
			advance_actor(state)
			continue
		state["turn_prepared"] = true
		break
	append_log(state, messages)
	return messages

static func advance_actor(state: Dictionary) -> void:
	state["turns_taken"] = int(state.get("turns_taken", 0)) + 1
	state["queue_cursor"] = int(state.get("queue_cursor", 0)) + 1
	state["turn_prepared"] = false
	var queue: Array = state["queue"]
	if int(state["queue_cursor"]) >= queue.size():
		state["round"] = int(state.get("round", 1)) + 1
		build_round_queue(state)

static func perform_player_action(state: Dictionary, action_id: String, args: Dictionary, inventory: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if action_id not in ACTION_IDS or str(state.get("outcome", "ongoing")) != "ongoing":
		return {"success": false, "message": "Acción no disponible."}
	resolve_until_player(state, rng)
	var actor := current_ally(state)
	if actor.is_empty():
		return {"success": false, "message": "No hay un personaje listo para actuar."}
	var result: Dictionary
	match action_id:
		"attack": result = player_attack(state, actor, rng)
		"art": result = player_art(state, actor, rng)
		"heal": result = player_heal(state, actor, args)
		"defend": result = player_defend(state, actor)
		"item": result = player_item(state, actor, args, inventory)
		"switch": result = player_switch(state, actor, args)
		"combo": result = player_combo(state, actor, rng)
		"flee": result = player_flee(state, rng)
		_: result = {"success": false, "message": "Acción desconocida."}
	if not bool(result.get("success", false)):
		return result
	state["last_action"] = result.duplicate(true)
	var messages: Array[String] = [str(result["message"])]
	check_outcome(state, rng)
	if str(state["outcome"]) == "ongoing":
		advance_actor(state)
		messages.append_array(resolve_until_player(state, rng))
	result["message"] = " ".join(messages)
	append_log(state, [str(result["message"])])
	return result

static func player_attack(state: Dictionary, actor: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var weapon := str(actor.get("weapon", "sword"))
	var hit := deal_enemy_damage(state, actor, 8, "physical", weapon, rng)
	var message := "%s ataca: %d de daño." % [actor["name"], hit["damage"]]
	if bool(hit["miss"]): message = "%s falla el ataque." % actor["name"]
	elif bool(hit["weak"]): message += " ¡Debilidad! Resonancia +1."
	return {"success": true, "message": message, "damage": hit["damage"], "weak": hit["weak"], "animation": "attack"}

static func player_art(state: Dictionary, actor: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var statuses: Dictionary = (state["ally_statuses"] as Dictionary).get(str(actor["id"]), {})
	if statuses.has("silence"):
		return {"success": false, "message": "%s está en silencio." % actor["name"]}
	if int(actor.get("mp", 0)) < 3:
		return {"success": false, "message": "%s no tiene PM suficientes." % actor["name"]}
	actor["mp"] = int(actor["mp"]) - 3
	var skill := skill_for_member(str(actor.get("id", "aren")))
	var hit := deal_enemy_damage(state, actor, int(skill["power"]), "magic", str(skill["element"]), rng)
	if int(hit["damage"]) > 0 and not str(skill["status"]).is_empty():
		apply_status(state["enemy_statuses"] as Dictionary, str(skill["status"]), 2)
	var message := "%s usa %s: %d de daño %s." % [actor["name"], skill["name"], hit["damage"], str(skill["element"]).to_upper()]
	if bool(hit["weak"]): message += " ¡Debilidad explotada!"
	return {"success": true, "message": message, "damage": hit["damage"], "weak": hit["weak"], "animation": "special"}

static func player_heal(state: Dictionary, actor: Dictionary, args: Dictionary) -> Dictionary:
	var statuses: Dictionary = (state["ally_statuses"] as Dictionary).get(str(actor["id"]), {})
	if statuses.has("silence"): return {"success": false, "message": "%s está en silencio." % actor["name"]}
	if int(actor.get("mp", 0)) < 2: return {"success": false, "message": "%s no tiene PM suficientes." % actor["name"]}
	var allies := living_allies(state)
	var target_index := clampi(int(args.get("target_index", allies.find(actor))), 0, allies.size() - 1)
	var target: Dictionary = allies[target_index]
	if int(target["hp"]) >= int(target["max_hp"]): return {"success": false, "message": "%s ya tiene todos sus PV." % target["name"]}
	actor["mp"] = int(actor["mp"]) - 2
	var amount := mini(int(target["max_hp"]) - int(target["hp"]), 14 + int(actor.get("magic", 1)))
	target["hp"] = int(target["hp"]) + amount
	return {"success": true, "message": "%s cura a %s: +%d PV." % [actor["name"], target["name"], amount], "healing": amount, "animation": "heal"}

static func player_defend(state: Dictionary, actor: Dictionary) -> Dictionary:
	(state["defending"] as Dictionary)[str(actor["id"])] = true
	return {"success": true, "message": "%s adopta una guardia firme." % actor["name"], "animation": "defend"}

static func player_item(state: Dictionary, actor: Dictionary, args: Dictionary, inventory: Dictionary) -> Dictionary:
	var item_name := str(args.get("item_name", first_usable_item(inventory)))
	if item_name.is_empty(): return {"success": false, "message": "No hay objetos utilizables."}
	var allies := living_allies(state)
	var target_index := clampi(int(args.get("target_index", allies.find(actor))), 0, allies.size() - 1)
	var target: Dictionary = allies[target_index]
	var use_result := InventorySystem.use_item(inventory, item_name, target)
	if not bool(use_result["success"]): return use_result
	return {"success": true, "message": str(use_result["message"]), "animation": "use_item"}

static func player_switch(state: Dictionary, actor: Dictionary, args: Dictionary) -> Dictionary:
	var allies := living_allies(state)
	if allies.size() < 2: return {"success": false, "message": "No hay otro compañero disponible."}
	var target_index := wrapi(int(args.get("target_index", allies.find(actor) + 1)), 0, allies.size())
	var target: Dictionary = allies[target_index]
	if target == actor: return {"success": false, "message": "Selecciona otro compañero."}
	var queue: Array = state["queue"]
	var target_actor := ally_actor_id(target)
	var future_index := queue.find(target_actor, int(state["queue_cursor"]) + 1)
	if future_index >= 0 and int(state["queue_cursor"]) + 1 < queue.size():
		var next_index := int(state["queue_cursor"]) + 1
		var displaced: Variant = queue[next_index]
		queue[next_index] = target_actor
		queue[future_index] = displaced
	return {"success": true, "message": "%s cede la iniciativa a %s." % [actor["name"], target["name"]], "animation": "defend"}

static func player_combo(state: Dictionary, actor: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if int(state.get("resonance", 0)) < COMBO_COST: return {"success": false, "message": "Se necesitan %d puntos de Resonancia." % COMBO_COST}
	var allies := living_allies(state)
	if allies.size() < 2: return {"success": false, "message": "Se necesitan dos compañeros conscientes."}
	state["resonance"] = int(state["resonance"]) - COMBO_COST
	var combined_attack := 0
	var combined_magic := 0
	for member in allies:
		combined_attack += int(member.get("attack", 1))
		combined_magic += int(member.get("magic", 1))
	var proxy := {"attack": combined_attack / allies.size(), "magic": combined_magic / allies.size()}
	var hit := deal_enemy_damage(state, proxy, 22 + allies.size() * 4, "magic", "light", rng)
	apply_status(state["enemy_statuses"] as Dictionary, "fear", 1)
	return {"success": true, "message": "¡Convergencia del Cristal! El grupo causa %d de daño combinado." % hit["damage"], "damage": hit["damage"], "animation": "special"}

static func player_flee(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var enemy: Dictionary = state["enemy"]
	if str(enemy.get("rank", "normal")) in ["miniboss", "boss"]:
		return {"success": false, "message": "No se puede huir de este adversario."}
	state["flee_attempts"] = int(state.get("flee_attempts", 0)) + 1
	var allies := living_allies(state)
	var average_speed := 0.0
	for member in allies: average_speed += float(member.get("speed", 1))
	average_speed /= maxf(1.0, allies.size())
	var chance := clampf(0.35 + (average_speed - float(enemy.get("speed", 8))) * 0.035 + int(state["flee_attempts"]) * 0.1, 0.12, 0.95)
	if rng.randf() <= chance:
		state["outcome"] = "fled"
		return {"success": true, "message": "El grupo escapa con éxito.", "animation": "run"}
	return {"success": true, "message": "La ruta de huida está bloqueada.", "animation": "run"}

static func deal_enemy_damage(state: Dictionary, attacker: Dictionary, power: int, damage_kind: String, affinity: String, rng: RandomNumberGenerator) -> Dictionary:
	var enemy: Dictionary = state["enemy"]
	var attacker_statuses: Dictionary = {}
	if attacker.has("id"):
		attacker_statuses = (state["ally_statuses"] as Dictionary).get(str(attacker["id"]), {})
	var accuracy := 0.58 if attacker_statuses.has("blind") else 0.92
	var miss := rng.randf() > accuracy
	var weak := affinity in (enemy.get("weaknesses", []) as Array)
	var resistant := affinity in (enemy.get("resistances", []) as Array)
	var damage := 0
	if not miss:
		var defense := int(enemy.get("defense", 0))
		if int(state.get("shield", 1)) <= 0: defense /= 2
		var raw := float(power)
		if damage_kind == "physical": raw += float(attacker.get("attack", 1)) * 1.25 - defense * 0.52
		else: raw += float(attacker.get("magic", 1)) * 1.55 - defense * 0.34
		var variance := rng.randf_range(0.92, 1.08)
		var multiplier := 1.5 if weak else 0.55 if resistant else 1.0
		damage = maxi(1, int(round(raw * variance * multiplier)))
		enemy["hp"] = maxi(0, int(enemy["hp"]) - damage)
		if weak:
			state["resonance"] = mini(MAX_RESONANCE, int(state["resonance"]) + 1)
			if int(state["shield"]) > 0:
				state["shield"] = int(state["shield"]) - 1
				if int(state["shield"]) <= 0:
					state["broken_turns"] = 1
	return {"damage": damage, "weak": weak and not miss, "resistant": resistant, "miss": miss}

static func enemy_turn(state: Dictionary, rng: RandomNumberGenerator) -> String:
	update_enemy_phase(state)
	var enemy: Dictionary = state["enemy"]
	var action := next_enemy_action(state)
	var enemy_statuses: Dictionary = state["enemy_statuses"]
	if enemy_statuses.has("silence") and action != "attack": action = "attack"
	if action == "regeneration":
		apply_status(enemy_statuses, "regeneration", 3, maxi(2, int(enemy["max_hp"]) / 20))
		return "%s invoca Regeneración." % enemy["name"]
	if action == "defend":
		state["shield"] = mini(int(state["shield_max"]), int(state["shield"]) + 1)
		return "%s refuerza su escudo de ruptura." % enemy["name"]
	var allies := living_allies(state)
	if allies.is_empty(): return "%s no encuentra ningún objetivo." % enemy["name"]
	var target: Dictionary = allies[rng.randi_range(0, allies.size() - 1)]
	state["last_enemy_target"] = str(target["id"])
	var status_to_apply := action if action in STATUS_IDS and action != "regeneration" else ""
	var element := action if action in ["fire", "ice", "lightning", "earth", "wind", "light", "dark"] else "physical"
	var damage_kind := "physical" if action == "attack" or not status_to_apply.is_empty() else "magic"
	var accuracy := 0.58 if enemy_statuses.has("blind") else 0.9
	var miss := rng.randf() > accuracy
	var damage := 0
	if not miss:
		var raw := 5.0 + float(enemy.get("attack", 1)) * (0.75 if damage_kind == "physical" else 0.6) - float(target.get("defense", 0)) * 0.32
		var multiplier := affinity_multiplier(target, element)
		damage = maxi(1, int(round(raw * rng.randf_range(0.9, 1.1) * multiplier)))
		var defending: Dictionary = state["defending"]
		if bool(defending.get(str(target["id"]), false)):
			damage = maxi(1, damage / 2)
			defending.erase(str(target["id"]))
		target["hp"] = maxi(0, int(target["hp"]) - damage)
		if not status_to_apply.is_empty() and int(target["hp"]) > 0:
			var target_statuses: Dictionary = (state["ally_statuses"] as Dictionary)[str(target["id"])]
			apply_status(target_statuses, status_to_apply, 2)
	var phase_label := "Fase %d" % int(state["enemy_phase"])
	if miss: return "%s (%s) falla contra %s." % [enemy["name"], phase_label, target["name"]]
	var suffix := " y causa %s" % status_to_apply if not status_to_apply.is_empty() else ""
	return "%s (%s) usa %s contra %s: %d de daño%s." % [enemy["name"], phase_label, action.capitalize(), target["name"], damage, suffix]

static func update_enemy_phase(state: Dictionary) -> void:
	var enemy: Dictionary = state["enemy"]
	var ratio := float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"]))
	state["enemy_phase"] = 1 if ratio > 0.66 else 2 if ratio > 0.33 else 3

static func next_enemy_action(state: Dictionary) -> String:
	var action := predicted_enemy_action(state)
	var phase := int(state["enemy_phase"])
	var cursors: Dictionary = state["ai_cursor"]
	cursors[phase] = int(cursors.get(phase, 0)) + 1
	return action

static func predicted_enemy_action(state: Dictionary) -> String:
	var enemy: Dictionary = state["enemy"]
	var phase := int(state["enemy_phase"])
	var pattern_key := "ai_phase_%d" % phase
	var pattern: Array = enemy.get(pattern_key, ["attack"])
	if pattern.is_empty(): pattern = ["attack"]
	var cursors: Dictionary = state["ai_cursor"]
	var cursor := int(cursors.get(phase, 0))
	return str(pattern[cursor % pattern.size()])

static func tick_statuses(combatant: Dictionary, statuses: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var messages: Array[String] = []
	var skip := false
	if statuses.has("poison"):
		var poison_damage := maxi(1, int(combatant.get("max_hp", 1)) / 12)
		combatant["hp"] = maxi(0, int(combatant["hp"]) - poison_damage)
		messages.append("%s sufre %d de veneno." % [combatant["name"], poison_damage])
	if statuses.has("regeneration") and int(combatant["hp"]) > 0:
		var regen_data: Dictionary = statuses["regeneration"]
		var healing := int(regen_data.get("power", maxi(1, int(combatant["max_hp"]) / 14)))
		var restored := mini(healing, int(combatant["max_hp"]) - int(combatant["hp"]))
		combatant["hp"] = int(combatant["hp"]) + restored
		if restored > 0: messages.append("%s regenera %d PV." % [combatant["name"], restored])
	if statuses.has("sleep"): skip = true
	if statuses.has("fear") and rng.randf() < 0.45: skip = true
	var expired: Array = []
	for status_id in statuses:
		var data: Dictionary = statuses[status_id]
		data["turns"] = int(data.get("turns", 1)) - 1
		if int(data["turns"]) <= 0: expired.append(status_id)
	for status_id in expired: statuses.erase(status_id)
	return {"skip": skip, "messages": messages}

static func apply_status(statuses: Dictionary, status_id: String, turns: int, power: int = 0) -> bool:
	if status_id not in STATUS_IDS or turns <= 0: return false
	var previous: Dictionary = statuses.get(status_id, {})
	statuses[status_id] = {"turns": maxi(turns, int(previous.get("turns", 0))), "power": maxi(power, int(previous.get("power", 0)))}
	return true

static func affinity_multiplier(target: Dictionary, affinity: String) -> float:
	if affinity in (target.get("weaknesses", []) as Array): return 1.5
	if affinity in (target.get("resistances", []) as Array): return 0.55
	return 1.0

static func skill_for_member(member_id: String) -> Dictionary:
	match member_id:
		"lyra": return {"name":"Rayo astral", "element":"lightning", "power":16, "status":"silence"}
		"brom": return {"name":"Falla rúnica", "element":"earth", "power":17, "status":"blind"}
		"seris": return {"name":"Luna invernal", "element":"ice", "power":15, "status":"poison"}
	return {"name":"Filo prismático", "element":"fire", "power":16, "status":"fear"}

static func first_usable_item(inventory: Dictionary) -> String:
	for item_name in inventory:
		var stack: Dictionary = inventory[item_name]
		if int(stack.get("quantity", 0)) > 0 and str(stack.get("restores", "none")) in ["hp", "mp"]:
			return str(item_name)
	return ""

static func check_outcome(state: Dictionary, rng: RandomNumberGenerator) -> void:
	if str(state.get("outcome", "ongoing")) != "ongoing": return
	var enemy: Dictionary = state["enemy"]
	if int(enemy.get("hp", 0)) <= 0:
		state["outcome"] = "victory"
		roll_loot(state, rng)
	elif living_allies(state).is_empty():
		state["outcome"] = "defeat"

static func roll_loot(state: Dictionary, rng: RandomNumberGenerator) -> void:
	var enemy: Dictionary = state["enemy"]
	var item_name := str(enemy.get("loot_item", ""))
	if not item_name.is_empty() and rng.randf() <= float(enemy.get("loot_chance", 0.0)):
		(state["loot"] as Array).append({"item": item_name, "amount": maxi(1, int(enemy.get("loot_amount", 1)))})

static func append_log(state: Dictionary, messages: Array[String]) -> void:
	var log: Array = state["combat_log"]
	for message in messages:
		if not message.is_empty(): log.append(message)
	while log.size() > 30: log.pop_front()

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["allies", "enemy", "queue", "resonance", "shield", "outcome"]:
		if not state.has(key): errors.append("Combate sin campo %s" % key)
	if not errors.is_empty(): return errors
	if int(state["resonance"]) < 0 or int(state["resonance"]) > MAX_RESONANCE: errors.append("Resonancia fuera de rango")
	if int(state["shield"]) < 0 or int(state["shield"]) > int(state["shield_max"]): errors.append("Escudo de ruptura fuera de rango")
	for member in state["allies"] as Array:
		if int(member["hp"]) < 0 or int(member["hp"]) > int(member["max_hp"]): errors.append("PV inválidos en %s" % member["name"])
	var enemy: Dictionary = state["enemy"]
	if int(enemy["hp"]) < 0 or int(enemy["hp"]) > int(enemy["max_hp"]): errors.append("PV enemigos inválidos")
	return errors

static func simulate_battle(party: Array, enemy: Dictionary, seed: int, maximum_turns: int = 160) -> Dictionary:
	var simulation_party := party.duplicate(true)
	for member in simulation_party:
		if member is Dictionary: member["joined"] = true
	var state := create_battle(simulation_party, enemy)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	resolve_until_player(state, rng)
	var actions := 0
	var inventory: Dictionary = {}
	while str(state["outcome"]) == "ongoing" and actions < maximum_turns:
		var actor := current_ally(state)
		if actor.is_empty():
			resolve_until_player(state, rng)
			continue
		var action := "attack"
		if int(state["resonance"]) >= COMBO_COST and rng.randf() < 0.35: action = "combo"
		elif int(actor["hp"]) < int(actor["max_hp"]) / 2 and int(actor["mp"]) >= 2: action = "heal"
		elif int(actor["mp"]) >= 3 and rng.randf() < 0.58: action = "art"
		var result := perform_player_action(state, action, {}, inventory, rng)
		if not bool(result.get("success", false)):
			perform_player_action(state, "attack", {}, inventory, rng)
		actions += 1
	state["simulation_actions"] = actions
	if str(state["outcome"]) == "ongoing": state["outcome"] = "timeout"
	return state
