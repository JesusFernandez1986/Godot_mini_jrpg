class_name BestiarySystem
extends RefCounted

const VARIANT_BASES := ["lunar_wolf", "crypt_rat", "hollow_sentinel", "amber_wisp", "ossuary_spider", "veil_cultist", "stone_gargoyle"]
const VARIANTS := [
	{"suffix":"ceniciento", "affix":"frenzy", "name":"Ceniciento", "scale":1.18},
	{"suffix":"prismatico", "affix":"warded", "name":"Prismatico", "scale":1.35},
	{"suffix":"abismal", "affix":"relentless", "name":"Abismal", "scale":1.58}
]
const ELITE_AFFIXES := {
	"frenzy":{"name":"Frenetico", "attack":1.30, "speed":1.15},
	"warded":{"name":"Protegido", "defense":1.35, "shield":2},
	"relentless":{"name":"Implacable", "hp":1.45, "attack":1.15},
	"vampiric":{"name":"Vampirico", "hp":1.25, "attack":1.20},
	"volatile":{"name":"Volatil", "attack":1.45, "defense":0.85},
	"ancient":{"name":"Ancestral", "hp":1.60, "defense":1.20},
	"swift":{"name":"Veloz", "speed":1.45, "attack":1.10},
	"royal":{"name":"Regio", "hp":1.35, "attack":1.25, "defense":1.20}
}
const HABITATS := {
	"lunar_wolf":"Bosques lunares", "shadow_ent":"Sylvaran", "moss_dragon":"Santuario de Eira",
	"crypt_rat":"Catacumbas", "hollow_sentinel":"Ruinas de Valdoria", "amber_wisp":"Celestia",
	"ossuary_spider":"Osarios", "veil_cultist":"Caminos velados", "stone_gargoyle":"Brumaforja",
	"oathbreaker_knight":"Fortalezas caidas", "hollow_lion":"Corona Hueca"
}

static func catalog() -> Array:
	var result: Array = []
	for definition in GameDatabase.ENEMIES:
		result.append(_entry(definition.id, definition.id, definition.display_name, "", 1.0))
	for base_id in VARIANT_BASES:
		var enemy := GameDatabase.enemy_by_id(base_id)
		for variant in VARIANTS:
			var variant_id := "%s_%s" % [base_id, variant["suffix"]]
			result.append(_entry(variant_id, base_id, "%s %s" % [enemy.get("name", base_id), variant["name"]], str(variant["affix"]), float(variant["scale"])))
	return result

static func _entry(entry_id: String, base_id: String, entry_name: String, affix: String, scale: float) -> Dictionary:
	var runtime := GameDatabase.enemy_by_id(base_id)
	return {
		"id":entry_id, "base_id":base_id, "name":entry_name, "affix":affix, "scale":scale,
		"habitat":str(HABITATS.get(base_id, "Tierras de Eryndor")),
		"rank":str(runtime.get("rank", "normal")), "weaknesses":runtime.get("weaknesses", []).duplicate(),
		"resistances":runtime.get("resistances", []).duplicate(),
		"lore":"Los cronistas describen a %s como una criatura ligada a los recuerdos quebrados de Eryndor." % entry_name
	}

static func create_state() -> Dictionary:
	var contracts: Dictionary = {}
	for index in 12:
		contracts["hunt_%02d" % (index + 1)] = {"target":VARIANT_BASES[index % VARIANT_BASES.size()], "required":2 + index % 4, "progress":0, "claimed":false}
	return {"records":{}, "contracts":contracts, "total_defeated":0, "elite_defeated":0}

static func entry(entry_id: String) -> Dictionary:
	for candidate in catalog():
		if str(candidate["id"]) == entry_id: return candidate
	return {}

static func observe(state: Dictionary, enemy: Dictionary) -> void:
	var entry_id := str(enemy.get("bestiary_id", enemy.get("id", "")))
	if entry(entry_id).is_empty(): entry_id = str(enemy.get("id", ""))
	if entry_id.is_empty(): return
	var records: Dictionary = state["records"]
	if not records.has(entry_id): records[entry_id] = {"seen":0, "defeated":0, "scanned":false, "weaknesses":[]}
	(records[entry_id] as Dictionary)["seen"] = int((records[entry_id] as Dictionary)["seen"]) + 1

static func scan(state: Dictionary, entry_id: String) -> Dictionary:
	var definition := entry(entry_id)
	if definition.is_empty(): return {"success":false, "message":"Entrada desconocida."}
	var records: Dictionary = state["records"]
	if not records.has(entry_id): records[entry_id] = {"seen":1, "defeated":0, "scanned":false, "weaknesses":[]}
	var record: Dictionary = records[entry_id]
	record["scanned"] = true
	record["weaknesses"] = (definition["weaknesses"] as Array).duplicate()
	return {"success":true, "message":"Analizado: debil a %s." % ", ".join(definition["weaknesses"] as Array)}

static func record_defeat(state: Dictionary, enemy: Dictionary) -> void:
	observe(state, enemy)
	var entry_id := str(enemy.get("bestiary_id", enemy.get("id", "")))
	if not (state["records"] as Dictionary).has(entry_id): entry_id = str(enemy.get("id", ""))
	var record: Dictionary = (state["records"] as Dictionary)[entry_id]
	record["defeated"] = int(record["defeated"]) + 1
	state["total_defeated"] = int(state["total_defeated"]) + 1
	if not str(enemy.get("elite_affix", "")).is_empty(): state["elite_defeated"] = int(state["elite_defeated"]) + 1
	var base_id := str(enemy.get("id", ""))
	for contract_id in state["contracts"] as Dictionary:
		var contract: Dictionary = (state["contracts"] as Dictionary)[contract_id]
		if str(contract["target"]) == base_id and not bool(contract["claimed"]):
			contract["progress"] = mini(int(contract["required"]), int(contract["progress"]) + 1)

static func claim_contract(state: Dictionary, contract_id: String) -> Dictionary:
	var contracts: Dictionary = state.get("contracts", {})
	if not contracts.has(contract_id): return {"success":false, "gold":0, "message":"Contrato desconocido."}
	var contract: Dictionary = contracts[contract_id]
	if bool(contract["claimed"]) or int(contract["progress"]) < int(contract["required"]): return {"success":false, "gold":0, "message":"La caceria aun no esta completa."}
	contract["claimed"] = true
	var reward := 80 + int(contract_id.right(2)) * 15
	return {"success":true, "gold":reward, "message":"Contrato cobrado: %d oro." % reward}

static func create_variant(base_id: String, variant_index: int) -> Dictionary:
	var enemy := GameDatabase.enemy_by_id(base_id)
	if enemy.is_empty() or base_id not in VARIANT_BASES: return enemy
	var variant: Dictionary = VARIANTS[wrapi(variant_index, 0, VARIANTS.size())]
	var variant_id := "%s_%s" % [base_id, variant["suffix"]]
	enemy["bestiary_id"] = variant_id
	enemy["name"] = "%s %s" % [enemy["name"], variant["name"]]
	apply_affix(enemy, str(variant["affix"]), float(variant["scale"]))
	return enemy

static func apply_affix(enemy: Dictionary, affix_id: String, scale: float = 1.0) -> void:
	if not ELITE_AFFIXES.has(affix_id): return
	var affix: Dictionary = ELITE_AFFIXES[affix_id]
	enemy["elite_affix"] = affix_id
	for stat in ["attack", "defense", "speed"]:
		enemy[stat] = maxi(1, roundi(float(enemy.get(stat, 1)) * scale * float(affix.get(stat, 1.0))))
	var hp_scale := scale * float(affix.get("hp", 1.0))
	enemy["max_hp"] = maxi(1, roundi(float(enemy.get("max_hp", enemy.get("hp", 1))) * hp_scale))
	enemy["hp"] = enemy["max_hp"]
	enemy["break_shield"] = int(enemy.get("break_shield", 1)) + int(affix.get("shield", 0))
	enemy["xp_reward"] = roundi(float(enemy.get("xp_reward", 1)) * scale * 1.35)
	enemy["gold_reward"] = roundi(float(enemy.get("gold_reward", 1)) * scale * 1.35)

static func completion_percent(state: Dictionary) -> float:
	var completed := 0
	for definition in catalog():
		var record: Dictionary = (state.get("records", {}) as Dictionary).get(str(definition["id"]), {})
		if bool(record.get("scanned", false)) and int(record.get("defeated", 0)) > 0: completed += 1
	return float(completed) / float(catalog().size()) * 100.0

static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	var ids: Array[String] = []
	for definition in catalog():
		if str(definition["id"]) in ids: errors.append("Entrada de bestiario duplicada: %s" % definition["id"])
		ids.append(str(definition["id"]))
	if ids.size() != 32: errors.append("El bestiario debe contener 32 criaturas.")
	if ELITE_AFFIXES.size() != 8: errors.append("Deben existir ocho afijos de elite.")
	return errors

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not state.get("records", {}) is Dictionary: errors.append("Registros de bestiario invalidos.")
	if not state.get("contracts", {}) is Dictionary or (state.get("contracts", {}) as Dictionary).size() != 12: errors.append("Contratos de caza invalidos.")
	if int(state.get("total_defeated", -1)) < 0: errors.append("Contador de derrotas invalido.")
	return errors
