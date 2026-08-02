class_name CombatIdentitySystem
extends RefCounted

const DATA_PATH := "res://data/combat/phase25_identities.json"
const HERO_IDS := ["aren", "lyra", "brom", "seris", "naia", "kael", "mira", "orin"]
const RIDERS := ["oath_break", "delay", "shatter", "resonance", "refund", "expose", "chorus", "colossus"]

static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty():
		return _data
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_data = parsed as Dictionary if parsed is Dictionary else {}
	return _data

static func max_focus() -> int:
	return int(data().get("max_focus", 3))

static func hero(hero_id: String) -> Dictionary:
	return (data().get("heroes", {}) as Dictionary).get(hero_id, {}) as Dictionary

static func boss_phase(enemy_id: String, phase: int) -> Dictionary:
	var bosses := data().get("bosses", {}) as Dictionary
	var boss := bosses.get(enemy_id, {}) as Dictionary
	return boss.get(str(clampi(phase, 1, 3)), {}) as Dictionary

static func power_multiplier(hero_id: String, focus: int, enemy: Dictionary) -> float:
	var multiplier := 1.0 + clampi(focus, 0, max_focus()) * 0.2
	if str(hero(hero_id).get("rider", "")) == "colossus" and str(enemy.get("rank", "normal")) in ["miniboss", "boss"]:
		multiplier *= 1.25
	return multiplier

static func enemy_damage_multiplier(enemy_id: String, phase: int) -> float:
	return float(boss_phase(enemy_id, phase).get("damage_multiplier", 1.0))

static func phase_title(enemy_id: String, phase: int) -> String:
	return str(boss_phase(enemy_id, phase).get("title", "Fase %d" % phase))

static func apply_rider(state: Dictionary, actor: Dictionary, focus: int, weak: bool) -> String:
	var profile := hero(str(actor.get("id", "")))
	var rider := str(profile.get("rider", ""))
	match rider:
		"oath_break":
			break_shield(state, 1)
			return "Juramento: Ruptura -1."
		"delay":
			var queue := state.get("queue", []) as Array
			var enemy_index := queue.find("enemy", int(state.get("queue_cursor", 0)) + 1)
			if enemy_index >= 0 and enemy_index + 1 < queue.size():
				var displaced: Variant = queue[enemy_index + 1]
				queue[enemy_index + 1] = "enemy"
				queue[enemy_index] = displaced
			return "Compás: turno enemigo retrasado."
		"shatter":
			break_shield(state, 2)
			return "Yunque: Ruptura -2."
		"resonance":
			if weak:
				state["resonance"] = mini(5, int(state.get("resonance", 0)) + 1)
				return "Eco: Resonancia +1."
		"refund":
			var restored := mini(maxi(1, focus), int(actor.get("max_mp", 0)) - int(actor.get("mp", 0)))
			actor["mp"] = int(actor.get("mp", 0)) + restored
			return "Marea: PM +%d." % restored
		"expose":
			var statuses := state.get("enemy_statuses", {}) as Dictionary
			var previous := statuses.get("blind", {}) as Dictionary
			statuses["blind"] = {"turns":maxi(3, int(previous.get("turns", 0))), "power":0}
			return "Velo: Ceguera prolongada."
		"chorus":
			var total := 0
			for ally in state.get("allies", []) as Array:
				if int((ally as Dictionary).get("hp", 0)) <= 0 or ally == actor:
					continue
				var healing := mini(maxi(2, focus * 3), int((ally as Dictionary).get("max_hp", 1)) - int((ally as Dictionary).get("hp", 0)))
				(ally as Dictionary)["hp"] = int((ally as Dictionary).get("hp", 0)) + healing
				total += healing
			return "Coro: grupo +%d PV." % total
		"colossus":
			return "Coloso: potencia aumentada."
	return ""

static func break_shield(state: Dictionary, amount: int) -> void:
	if int(state.get("shield", 0)) <= 0:
		return
	state["shield"] = maxi(0, int(state["shield"]) - maxi(0, amount))
	if int(state["shield"]) == 0:
		state["broken_turns"] = maxi(1, int(state.get("broken_turns", 0)))

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var heroes := data().get("heroes", {}) as Dictionary
	var riders: Array[String] = []
	for hero_id in HERO_IDS:
		var profile := heroes.get(hero_id, {}) as Dictionary
		var rider := str(profile.get("rider", ""))
		if str(profile.get("name", "")).is_empty() or rider not in RIDERS:
			errors.append("Identidad táctica inválida: %s." % hero_id)
		if rider in riders:
			errors.append("Mecánica de identidad duplicada: %s." % rider)
		riders.append(rider)
	for phase in range(1, 4):
		var profile := boss_phase("hollow_lion", phase)
		if str(profile.get("title", "")).is_empty() or float(profile.get("damage_multiplier", 0.0)) < 1.0:
			errors.append("Fase %d de la Corona Hueca inválida." % phase)
	return errors
