class_name AdvancementSystem
extends RefCounted

const SKILLS := {
	"prismatic_edge": {"name":"Filo prismático", "cost":3, "power":16, "element":"fire", "status":"fear", "kind":"damage"},
	"astral_bolt": {"name":"Rayo astral", "cost":3, "power":16, "element":"lightning", "status":"silence", "kind":"damage"},
	"runic_fault": {"name":"Falla rúnica", "cost":3, "power":17, "element":"earth", "status":"blind", "kind":"damage"},
	"winter_moon": {"name":"Luna invernal", "cost":3, "power":15, "element":"ice", "status":"poison", "kind":"damage"},
	"tidal_knives": {"name":"Cuchillas de marea", "cost":3, "power":16, "element":"water", "status":"blind", "kind":"damage"},
	"veil_piercer": {"name":"Lanza del velo", "cost":3, "power":17, "element":"dark", "status":"fear", "kind":"damage"},
	"rune_chorus": {"name":"Coro de runas", "cost":4, "power":25, "element":"light", "status":"regeneration", "kind":"heal"},
	"relic_crash": {"name":"Impacto de reliquia", "cost":3, "power":18, "element":"earth", "status":"blind", "kind":"damage"},
	"lion_lunge": {"name":"Embestida del León", "cost":5, "power":27, "element":"physical", "status":"fear", "kind":"damage"},
	"starfall": {"name":"Caída estelar", "cost":6, "power":31, "element":"light", "status":"silence", "kind":"damage"},
	"forge_quake": {"name":"Terremoto de fragua", "cost":5, "power":29, "element":"earth", "status":"blind", "kind":"damage"},
	"silver_rain": {"name":"Lluvia de plata", "cost":5, "power":26, "element":"wind", "status":"poison", "kind":"damage"},
	"renewal": {"name":"Renovación", "cost":4, "power":24, "element":"light", "status":"regeneration", "kind":"heal"}
}

const JOBS := {
	"none": {"name":"Sin especialización", "bonuses":{}, "skill":"", "passive":""},
	"guardian": {"name":"Guardián", "bonuses":{"max_hp":16,"defense":4,"speed":-1}, "skill":"lion_lunge", "passive":"unyielding"},
	"arcanist": {"name":"Arcanista", "bonuses":{"max_mp":8,"magic":5,"defense":-1}, "skill":"starfall", "passive":"elemental_focus"},
	"ranger": {"name":"Explorador", "bonuses":{"attack":3,"speed":5,"max_hp":-4}, "skill":"silver_rain", "passive":"weakness_hunter"},
	"apothecary": {"name":"Boticario", "bonuses":{"max_mp":5,"magic":3,"defense":2}, "skill":"renewal", "passive":"field_medic"}
}

const FORMATIONS := {
	"balanced": {"name":"Equilibrada", "bonuses":{"max_hp":2,"defense":1,"magic":1}},
	"vanguard": {"name":"Vanguardia", "bonuses":{"attack":4,"defense":2,"magic":-2}},
	"arcane": {"name":"Convergencia arcana", "bonuses":{"magic":5,"max_mp":4,"defense":-2}},
	"skirmish": {"name":"Hostigamiento", "bonuses":{"speed":5,"attack":2,"max_hp":-5}}
}

const TALENT_TREES := {
	"aren": [
		{"id":"aren_heart", "name":"Corazón de ámbar", "cost":1, "requires":"", "bonuses":{"max_hp":12}},
		{"id":"aren_edge", "name":"Juramento afilado", "cost":2, "requires":"aren_heart", "bonuses":{"attack":4}, "skill":"lion_lunge"},
		{"id":"aren_crown", "name":"Corona compartida", "cost":3, "requires":"aren_edge", "bonuses":{"defense":4}, "passive":"unyielding"}
	],
	"lyra": [
		{"id":"lyra_focus", "name":"Foco celeste", "cost":1, "requires":"", "bonuses":{"max_mp":6}},
		{"id":"lyra_comet", "name":"Memoria del cometa", "cost":2, "requires":"lyra_focus", "bonuses":{"magic":5}, "skill":"starfall"},
		{"id":"lyra_veil", "name":"Más allá del velo", "cost":3, "requires":"lyra_comet", "bonuses":{"speed":3}, "passive":"elemental_focus"}
	],
	"brom": [
		{"id":"brom_anvil", "name":"Piel de yunque", "cost":1, "requires":"", "bonuses":{"defense":4}},
		{"id":"brom_quake", "name":"Voz de la montaña", "cost":2, "requires":"brom_anvil", "bonuses":{"attack":4}, "skill":"forge_quake"},
		{"id":"brom_clan", "name":"Último del clan", "cost":3, "requires":"brom_quake", "bonuses":{"max_hp":18}, "passive":"guard_master"}
	],
	"seris": [
		{"id":"seris_step", "name":"Paso sin huella", "cost":1, "requires":"", "bonuses":{"speed":4}},
		{"id":"seris_rain", "name":"Lluvia del claro", "cost":2, "requires":"seris_step", "bonuses":{"attack":4}, "skill":"silver_rain"},
		{"id":"seris_name", "name":"Nombre verdadero", "cost":3, "requires":"seris_rain", "bonuses":{"magic":3}, "passive":"weakness_hunter"}
	],
	"naia": [
		{"id":"naia_current", "name":"Leer la corriente", "cost":1, "requires":"", "bonuses":{"speed":4}},
		{"id":"naia_knives", "name":"Filo de bajamar", "cost":2, "requires":"naia_current", "bonuses":{"attack":4}, "skill":"tidal_knives"},
		{"id":"naia_harbor", "name":"Puerto para todos", "cost":3, "requires":"naia_knives", "bonuses":{"max_hp":10}, "passive":"weakness_hunter"}
	],
	"kael": [
		{"id":"kael_step", "name":"Paso velado", "cost":1, "requires":"", "bonuses":{"speed":5}},
		{"id":"kael_piercer", "name":"Verdad punzante", "cost":2, "requires":"kael_step", "bonuses":{"attack":4}, "skill":"veil_piercer"},
		{"id":"kael_witness", "name":"Guardar al testigo", "cost":3, "requires":"kael_piercer", "bonuses":{"defense":3}, "passive":"unyielding"}
	],
	"mira": [
		{"id":"mira_tone", "name":"Tono fundamental", "cost":1, "requires":"", "bonuses":{"max_mp":7}},
		{"id":"mira_chorus", "name":"Coro compartido", "cost":2, "requires":"mira_tone", "bonuses":{"magic":5}, "skill":"rune_chorus"},
		{"id":"mira_echo", "name":"Eco del presente", "cost":3, "requires":"mira_chorus", "bonuses":{"defense":3}, "passive":"field_medic"}
	],
	"orin": [
		{"id":"orin_grip", "name":"Agarre de bronce", "cost":1, "requires":"", "bonuses":{"defense":4}},
		{"id":"orin_crash", "name":"Caída del explorador", "cost":2, "requires":"orin_grip", "bonuses":{"attack":5}, "skill":"relic_crash"},
		{"id":"orin_return", "name":"Devolver el hallazgo", "cost":3, "requires":"orin_crash", "bonuses":{"max_hp":16}, "passive":"guard_master"}
	]
}

const INNATE_SKILLS := {
	"aren":"prismatic_edge", "lyra":"astral_bolt", "brom":"runic_fault", "seris":"winter_moon",
	"naia":"tidal_knives", "kael":"veil_piercer", "mira":"rune_chorus", "orin":"relic_crash"
}

static func create_state() -> Dictionary:
	var members: Dictionary = {}
	for character_id in INNATE_SKILLS:
		members[character_id] = {
			"talent_points": 1,
			"job_points": 0,
			"secondary_job": "none",
			"talents": [],
			"active_skills": [INNATE_SKILLS[character_id]],
			"selected_skill": INNATE_SKILLS[character_id],
			"passives": []
		}
	return {"members": members, "formation": "balanced"}

static func member_state(state: Dictionary, character_id: String) -> Dictionary:
	var members: Dictionary = state.get("members", {})
	if not members.has(character_id):
		members[character_id] = {"talent_points":0,"job_points":0,"secondary_job":"none","talents":[],"active_skills":[INNATE_SKILLS.get(character_id, "prismatic_edge")],"selected_skill":INNATE_SKILLS.get(character_id, "prismatic_edge"),"passives":[]}
	return members[character_id] as Dictionary

static func grant_points(state: Dictionary, character_id: String, job_points: int, talent_points: int = 0) -> void:
	var member := member_state(state, character_id)
	member["job_points"] = clampi(int(member.get("job_points", 0)) + maxi(0, job_points), 0, 9999)
	member["talent_points"] = clampi(int(member.get("talent_points", 0)) + maxi(0, talent_points), 0, 999)

static func set_job(state: Dictionary, character_id: String, job_id: String) -> Dictionary:
	if not JOBS.has(job_id): return {"success":false,"message":"Trabajo desconocido."}
	var member := member_state(state, character_id)
	if job_id != "none" and int(member.get("job_points", 0)) < 3:
		return {"success":false,"message":"Se requieren 3 PT para especializarse."}
	member["secondary_job"] = job_id
	var skill := str(JOBS[job_id].get("skill", ""))
	if not skill.is_empty() and skill not in (member["active_skills"] as Array): member["active_skills"].append(skill)
	return {"success":true,"message":"Especialización: %s." % JOBS[job_id]["name"]}

static func cycle_job(state: Dictionary, character_id: String, direction: int = 1) -> Dictionary:
	var ids := JOBS.keys()
	var current := str(member_state(state, character_id).get("secondary_job", "none"))
	var start := ids.find(current)
	for offset in ids.size():
		var job_id := str(ids[wrapi(start + (offset + 1) * direction, 0, ids.size())])
		var result := set_job(state, character_id, job_id)
		if bool(result.get("success", false)): return result
	return {"success":false,"message":"Aún no hay otro trabajo disponible."}

static func unlock_talent(state: Dictionary, character_id: String, talent_id: String) -> Dictionary:
	var talent := talent_definition(character_id, talent_id)
	if talent.is_empty(): return {"success":false,"message":"Talento desconocido."}
	var member := member_state(state, character_id)
	if talent_id in (member["talents"] as Array): return {"success":false,"message":"Talento ya aprendido."}
	var requirement := str(talent.get("requires", ""))
	if not requirement.is_empty() and requirement not in (member["talents"] as Array): return {"success":false,"message":"Falta el talento anterior."}
	var cost := int(talent.get("cost", 1))
	if int(member["talent_points"]) < cost: return {"success":false,"message":"Puntos de talento insuficientes."}
	member["talent_points"] = int(member["talent_points"]) - cost
	(member["talents"] as Array).append(talent_id)
	var skill := str(talent.get("skill", ""))
	if not skill.is_empty() and skill not in (member["active_skills"] as Array): member["active_skills"].append(skill)
	var passive := str(talent.get("passive", ""))
	if not passive.is_empty() and passive not in (member["passives"] as Array): member["passives"].append(passive)
	return {"success":true,"message":"Talento aprendido: %s." % talent["name"]}

static func unlock_next_talent(state: Dictionary, character_id: String) -> Dictionary:
	for talent in TALENT_TREES.get(character_id, []):
		if str(talent["id"]) not in (member_state(state, character_id)["talents"] as Array):
			return unlock_talent(state, character_id, str(talent["id"]))
	return {"success":false,"message":"Árbol de talentos completado."}

static func talent_definition(character_id: String, talent_id: String) -> Dictionary:
	for talent in TALENT_TREES.get(character_id, []):
		if str(talent["id"]) == talent_id: return talent
	return {}

static func selected_skill(state: Dictionary, character_id: String) -> String:
	return str(member_state(state, character_id).get("selected_skill", INNATE_SKILLS.get(character_id, "prismatic_edge")))

static func cycle_skill(state: Dictionary, character_id: String, direction: int = 1) -> Dictionary:
	var member := member_state(state, character_id)
	var skills: Array = member["active_skills"]
	if skills.is_empty(): return {"success":false,"message":"No hay artes disponibles."}
	var index := skills.find(member.get("selected_skill", ""))
	index = wrapi(index + direction, 0, skills.size())
	member["selected_skill"] = skills[index]
	return {"success":true,"message":"Arte equipada: %s." % SKILLS[str(skills[index])]["name"]}

static func set_formation(state: Dictionary, formation_id: String) -> bool:
	if not FORMATIONS.has(formation_id): return false
	state["formation"] = formation_id
	return true

static func cycle_formation(state: Dictionary, direction: int = 1) -> String:
	var ids := FORMATIONS.keys()
	var index := ids.find(state.get("formation", "balanced"))
	var formation_id := str(ids[wrapi(index + direction, 0, ids.size())])
	state["formation"] = formation_id
	return formation_id

static func stat_bonuses(state: Dictionary, character_id: String) -> Dictionary:
	var result := EquipmentSystem.zero_bonuses()
	var member := member_state(state, character_id)
	var job_id := str(member.get("secondary_job", "none"))
	for stat in JOBS.get(job_id, JOBS["none"]).get("bonuses", {}): result[stat] = int(result.get(stat, 0)) + int(JOBS[job_id]["bonuses"][stat])
	for talent_id in member.get("talents", []) as Array:
		var talent := talent_definition(character_id, str(talent_id))
		for stat in talent.get("bonuses", {}): result[stat] = int(result.get(stat, 0)) + int(talent["bonuses"][stat])
	var formation_id := str(state.get("formation", "balanced"))
	for stat in FORMATIONS.get(formation_id, FORMATIONS["balanced"])["bonuses"]: result[stat] = int(result.get(stat, 0)) + int(FORMATIONS[formation_id]["bonuses"][stat])
	return result

static func active_passives(state: Dictionary, character_id: String) -> Array:
	var member := member_state(state, character_id)
	var result := (member.get("passives", []) as Array).duplicate()
	var job_id := str(member.get("secondary_job", "none"))
	var job_passive := str(JOBS.get(job_id, JOBS["none"]).get("passive", ""))
	if not job_passive.is_empty() and job_passive not in result: result.append(job_passive)
	return result

static func validate(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(state.get("formation", "")) not in FORMATIONS: errors.append("Formación desconocida.")
	for character_id in INNATE_SKILLS:
		var member := member_state(state, character_id)
		if int(member.get("talent_points", 0)) < 0 or int(member.get("job_points", 0)) < 0: errors.append("Puntos negativos en %s" % character_id)
		if str(member.get("secondary_job", "none")) not in JOBS: errors.append("Trabajo desconocido en %s" % character_id)
		if str(member.get("selected_skill", "")) not in SKILLS: errors.append("Arte desconocida en %s" % character_id)
		for talent_id in member.get("talents", []) as Array:
			if talent_definition(character_id, str(talent_id)).is_empty(): errors.append("Talento desconocido: %s" % talent_id)
	return errors
