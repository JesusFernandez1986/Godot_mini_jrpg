class_name EndgameSystem
extends RefCounted

const DIFFICULTIES := {
	"story":{"name":"Relato", "enemy":0.82, "rewards":0.85},
	"standard":{"name":"Estandar", "enemy":1.0, "rewards":1.0},
	"veteran":{"name":"Veterano", "enemy":1.25, "rewards":1.25},
	"nightmare":{"name":"Pesadilla", "enemy":1.55, "rewards":1.55}
}
const ENEMY_ROTATION := ["crypt_rat", "lunar_wolf", "amber_wisp", "hollow_sentinel", "ossuary_spider", "veil_cultist", "stone_gargoyle", "shadow_ent", "oathbreaker_knight", "moss_dragon", "hollow_lion"]
const SUPERBOSSES := [
	["memory_dragon", "Azhar, Dragon de la Memoria", "moss_dragon", 2.1], ["void_lion", "Leon del Vacio", "hollow_lion", 2.3],
	["first_oath", "El Primer Juramento", "oathbreaker_knight", 2.45], ["star_eater", "Devorador de Estrellas", "amber_wisp", 2.6],
	["root_queen", "Reina de las Raices", "shadow_ent", 2.75], ["iron_colossus", "Coloso de Hierro", "stone_gargoyle", 2.9],
	["veil_oracle", "Oraculo del Velo", "veil_cultist", 3.05], ["forgotten_author", "El Autor Olvidado", "hollow_lion", 3.3]
]

static func arena_trials() -> Array:
	var result: Array = []
	for index in 25:
		var floor := index + 1
		result.append({"floor":floor, "enemy":ENEMY_ROTATION[index % ENEMY_ROTATION.size()], "scale":1.0 + floor * 0.055, "boss":floor % 5 == 0, "reward":30 + floor * 12})
	return result

static func challenges() -> Array:
	var result: Array = []
	var rules := ["sin_objetos", "sin_curar", "solo_artes", "ruptura_obligatoria", "tiempo_limite"]
	for index in 20: result.append({"id":"challenge_%02d" % (index + 1), "rule":rules[index % rules.size()], "target":3 + index % 7})
	return result

static func create_state() -> Dictionary:
	return {"unlocked":false, "difficulty":"standard", "arena_floor":1, "arena_active":false, "arena_cleared":[], "boss_rush_index":0, "boss_rush_active":false, "superbosses_defeated":[], "challenges_completed":[], "ng_plus_cycle":0, "legacy_points":0, "highest_streak":0, "current_streak":0}

static func unlock(state: Dictionary) -> void:
	state["unlocked"] = true

static func set_difficulty(state: Dictionary, difficulty_id: String) -> bool:
	if not DIFFICULTIES.has(difficulty_id): return false
	state["difficulty"] = difficulty_id
	return true

static func cycle_difficulty(state: Dictionary) -> String:
	var ids := DIFFICULTIES.keys()
	var index := ids.find(str(state.get("difficulty", "standard")))
	var next_id := str(ids[wrapi(index + 1, 0, ids.size())])
	state["difficulty"] = next_id
	return next_id

static func start_arena_trial(state: Dictionary) -> Dictionary:
	if not bool(state.get("unlocked", false)): return {"success":false, "message":"Completa el final comun para abrir la Arena de los Ecos."}
	var floor := clampi(int(state.get("arena_floor", 1)), 1, 25)
	var trial: Dictionary = arena_trials()[floor - 1]
	state["arena_active"] = true
	return {"success":true, "enemy":trial["enemy"], "scale":trial["scale"], "rank_override":"boss" if bool(trial["boss"]) else "normal", "display_name":"Eco %02d" % floor, "floor":floor}

static func start_superboss(state: Dictionary, boss_index: int) -> Dictionary:
	if not bool(state.get("unlocked", false)): return {"success":false, "message":"El contenido final aun esta sellado."}
	var boss: Array = SUPERBOSSES[wrapi(boss_index, 0, SUPERBOSSES.size())]
	if str(boss[0]) in (state.get("superbosses_defeated", []) as Array): return {"success":false, "message":"Ese superjefe ya fue vencido."}
	return {"success":true, "enemy":boss[2], "scale":boss[3], "rank_override":"boss", "display_name":boss[1], "superboss_id":boss[0]}

static func apply_scaling(enemy: Dictionary, scale: float, state: Dictionary) -> void:
	var difficulty: Dictionary = DIFFICULTIES.get(str(state.get("difficulty", "standard")), DIFFICULTIES["standard"])
	var cycle_scale := 1.0 + int(state.get("ng_plus_cycle", 0)) * 0.18
	var final_scale := scale * float(difficulty["enemy"]) * cycle_scale
	for stat in ["max_hp", "attack", "defense", "speed"]: enemy[stat] = maxi(1, roundi(float(enemy.get(stat, 1)) * final_scale))
	enemy["hp"] = enemy["max_hp"]
	enemy["xp_reward"] = roundi(float(enemy.get("xp_reward", 1)) * final_scale * float(difficulty["rewards"]))
	enemy["gold_reward"] = roundi(float(enemy.get("gold_reward", 1)) * final_scale * float(difficulty["rewards"]))

static func record_arena_victory(state: Dictionary) -> Dictionary:
	var floor := clampi(int(state.get("arena_floor", 1)), 1, 25)
	if floor not in (state["arena_cleared"] as Array): (state["arena_cleared"] as Array).append(floor)
	state["arena_active"] = false
	state["current_streak"] = int(state["current_streak"]) + 1
	state["highest_streak"] = maxi(int(state["highest_streak"]), int(state["current_streak"]))
	var reward := int(arena_trials()[floor - 1]["reward"])
	if floor < 25: state["arena_floor"] = floor + 1
	else: state["legacy_points"] = int(state["legacy_points"]) + 5
	return {"gold":reward, "message":"Prueba %d superada. Recompensa: %d oro." % [floor, reward]}

static func record_superboss_victory(state: Dictionary, boss_id: String) -> Dictionary:
	if boss_id.is_empty() or boss_id in (state["superbosses_defeated"] as Array): return {"gold":0, "message":"Victoria ya registrada."}
	(state["superbosses_defeated"] as Array).append(boss_id)
	state["legacy_points"] = int(state["legacy_points"]) + 3
	return {"gold":500, "message":"Superjefe vencido. Obtienes 3 puntos de legado."}

static func start_new_game_plus(state: Dictionary) -> Dictionary:
	if (state.get("arena_cleared", []) as Array).size() < 25: return {"success":false, "message":"Supera las 25 pruebas de la Arena."}
	state["ng_plus_cycle"] = int(state["ng_plus_cycle"]) + 1
	state["legacy_points"] = int(state["legacy_points"]) + 10
	state["arena_floor"] = 1
	state["arena_cleared"] = []
	return {"success":true, "message":"Nueva Partida +%d preparada." % int(state["ng_plus_cycle"])}

static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	if arena_trials().size() != 25: errors.append("La arena debe contener 25 pruebas.")
	if SUPERBOSSES.size() != 8: errors.append("Deben existir ocho superjefes.")
	if challenges().size() != 20: errors.append("Deben existir veinte desafios finales.")
	return errors

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not DIFFICULTIES.has(str(state.get("difficulty", ""))): errors.append("Dificultad invalida.")
	if int(state.get("arena_floor", 0)) < 1 or int(state.get("arena_floor", 0)) > 25: errors.append("Piso de arena invalido.")
	if int(state.get("ng_plus_cycle", -1)) < 0: errors.append("Ciclo NG+ invalido.")
	return errors
