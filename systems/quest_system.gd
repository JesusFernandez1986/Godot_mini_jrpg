class_name QuestSystem
extends RefCounted

const MAIN_ID := "echoes_below"
const SIDE_IDS := ["lost_ledger", "moonleaf_remedy", "sentry_oath"]

static func create_phase3_state() -> Dictionary:
	return {
		"main": {"id": MAIN_ID, "status": "available", "stage": 0},
		"side": {
			"lost_ledger": {"status": "available", "progress": 0, "target": 1},
			"moonleaf_remedy": {"status": "available", "progress": 0, "target": 1},
			"sentry_oath": {"status": "available", "progress": 0, "target": 3}
		},
		"flags": {
			"dungeon_unlocked": false, "ledger_found": false, "herb_found": false,
			"seal_west": false, "seal_east": false, "miniboss_defeated": false,
			"boss_defeated": false, "closing_seen": false
		},
		"enemy_defeats": {},
		"rewarded_quests": []
	}

static func accept_main(state: Dictionary) -> bool:
	var main: Dictionary = state["main"]
	if str(main["status"]) != "available":
		return false
	main["status"] = "active"
	main["stage"] = 1
	(state["flags"] as Dictionary)["dungeon_unlocked"] = true
	return true

static func accept_side(state: Dictionary, quest_id: String) -> bool:
	if quest_id not in SIDE_IDS:
		return false
	var quest: Dictionary = (state["side"] as Dictionary)[quest_id]
	if str(quest["status"]) != "available":
		return false
	quest["status"] = "active"
	refresh(state)
	return true

static func activate_seal(state: Dictionary, seal_id: String) -> bool:
	if seal_id not in ["seal_west", "seal_east"] or not bool((state["flags"] as Dictionary).get("dungeon_unlocked", false)):
		return false
	var flags: Dictionary = state["flags"]
	if bool(flags.get(seal_id, false)):
		return false
	flags[seal_id] = true
	refresh(state)
	return true

static func collect_objective(state: Dictionary, objective_id: String) -> bool:
	var quest_id := "lost_ledger" if objective_id == "ledger_found" else "moonleaf_remedy" if objective_id == "herb_found" else ""
	if quest_id.is_empty():
		return false
	var quest: Dictionary = (state["side"] as Dictionary)[quest_id]
	if str(quest["status"]) != "active" or bool((state["flags"] as Dictionary).get(objective_id, false)):
		return false
	(state["flags"] as Dictionary)[objective_id] = true
	quest["progress"] = 1
	refresh(state)
	return true

static func record_enemy_defeat(state: Dictionary, enemy_id: String, rank: String = "normal") -> void:
	var defeats: Dictionary = state["enemy_defeats"]
	defeats[enemy_id] = int(defeats.get(enemy_id, 0)) + 1
	if rank == "miniboss":
		(state["flags"] as Dictionary)["miniboss_defeated"] = true
	elif rank == "boss":
		(state["flags"] as Dictionary)["boss_defeated"] = true
	var sentry: Dictionary = (state["side"] as Dictionary)["sentry_oath"]
	if str(sentry["status"]) == "active" and rank == "normal":
		sentry["progress"] = mini(int(sentry["target"]), int(sentry["progress"]) + 1)
	refresh(state)

static func refresh(state: Dictionary) -> void:
	var flags: Dictionary = state["flags"]
	var main: Dictionary = state["main"]
	if str(main["status"]) == "active":
		if bool(flags.get("boss_defeated", false)):
			main["stage"] = 4
		elif bool(flags.get("miniboss_defeated", false)) and seals_active(state) == 2:
			main["stage"] = 3
		elif seals_active(state) > 0:
			main["stage"] = 2
	for quest_id in SIDE_IDS:
		var quest: Dictionary = (state["side"] as Dictionary)[quest_id]
		if str(quest["status"]) == "active" and int(quest["progress"]) >= int(quest["target"]):
			quest["status"] = "ready"

static func seals_active(state: Dictionary) -> int:
	var flags: Dictionary = state["flags"]
	return int(bool(flags.get("seal_west", false))) + int(bool(flags.get("seal_east", false)))

static func can_fight_miniboss(state: Dictionary) -> bool:
	return seals_active(state) == 2 and not bool((state["flags"] as Dictionary).get("miniboss_defeated", false))

static func can_fight_boss(state: Dictionary) -> bool:
	return can_return_main(state) == false and bool((state["flags"] as Dictionary).get("miniboss_defeated", false)) and not bool((state["flags"] as Dictionary).get("boss_defeated", false))

static func can_return_main(state: Dictionary) -> bool:
	return bool((state["flags"] as Dictionary).get("boss_defeated", false)) and str((state["main"] as Dictionary)["status"]) == "active"

static func turn_in_side(state: Dictionary, quest_id: String) -> Dictionary:
	if quest_id not in SIDE_IDS:
		return {}
	var quest: Dictionary = (state["side"] as Dictionary)[quest_id]
	if str(quest["status"]) != "ready":
		return {}
	quest["status"] = "completed"
	(state["rewarded_quests"] as Array).append(quest_id)
	match quest_id:
		"lost_ledger": return {"gold": 65, "item": "Mapa de las Catacumbas", "amount": 1}
		"moonleaf_remedy": return {"gold": 35, "item": "Poción menor", "amount": 3}
		"sentry_oath": return {"gold": 90, "item": "Pan de viaje", "amount": 2}
	return {}

static func turn_in_main(state: Dictionary) -> Dictionary:
	if not can_return_main(state):
		return {}
	(state["main"] as Dictionary)["status"] = "completed"
	(state["main"] as Dictionary)["stage"] = 5
	(state["flags"] as Dictionary)["closing_seen"] = true
	(state["rewarded_quests"] as Array).append(MAIN_ID)
	return {"gold": 250, "item": "Emblema del León Despierto", "amount": 1, "xp": 160}

static func objective(state: Dictionary) -> String:
	var main: Dictionary = state["main"]
	if str(main["status"]) == "available": return "Habla con la capitana Elara en la plaza de Valdoria."
	if str(main["status"]) == "completed": return "El León Despierto protege de nuevo Valdoria. Explora Eryndor a tu ritmo."
	match int(main["stage"]):
		1: return "Entra en las catacumbas por la puerta al norte de la plaza."
		2:
			if seals_active(state) < 2: return "Activa los dos sellos de cristal (%d/2)." % seals_active(state)
			return "Los sellos han despertado al Caballero Perjuro. Derrótalo en la cámara central."
		3: return "Alcanza el trono y derrota al León de la Corona Hueca."
		4: return "Regresa con la capitana Elara en Valdoria."
	return "Descubre qué despierta bajo Valdoria."

static func validate(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not state.has("main") or not state.has("side") or not state.has("flags"):
		errors.append("El estado de misiones de fase 3 está incompleto")
		return errors
	for quest_id in SIDE_IDS:
		if not (state["side"] as Dictionary).has(quest_id):
			errors.append("Falta la misión secundaria %s" % quest_id)
	return errors
