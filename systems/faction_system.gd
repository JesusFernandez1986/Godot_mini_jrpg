class_name FactionSystem
extends RefCounted

const MAX_ACTIVE_QUESTS := 3
const FACTIONS := {
	"lion_crown":{"name":"Corona del Leon", "city":"valdoria", "color":"d5c47f"},
	"ember_guild":{"name":"Gremio de la Brasa", "city":"brumaforja", "color":"e27a47"},
	"astral_conclave":{"name":"Conclave Astral", "city":"celestia", "color":"8ec9ff"},
	"green_covenant":{"name":"Pacto Verde", "city":"sylvaran", "color":"75c98c"}
}
const QUEST_TITLES := {
	"lion_crown":["El estandarte roto", "Voces del consejo", "La deuda del vigia", "Juicio bajo la fuente", "Los leones sin nombre", "Una corona para todos"],
	"ember_guild":["Carbon y juramentos", "La veta perdida", "Hijos del yunque", "El precio del acero", "Campanas de guerra", "La ultima forja"],
	"astral_conclave":["Cartas sin cielo", "El cometa cautivo", "Nombres en la lente", "La torre dividida", "Un firmamento de ceniza", "La estrella que elige"],
	"green_covenant":["Raices inquietas", "La senda del ciervo", "Semillas del pasado", "El tribunal de hojas", "Bosques sin guardian", "El nombre del mundo"]
}

static func quests() -> Array:
	var result: Array = []
	for faction_id in FACTIONS:
		for index in 6:
			var number := index + 1
			result.append({
				"id":"%s_%02d" % [faction_id, number], "faction":faction_id, "chapter":number,
				"title":QUEST_TITLES[faction_id][index], "stages":3,
				"objective":"Resuelve el conflicto %d de %s y decide que recuerdo debe prevalecer." % [number, FACTIONS[faction_id]["name"]],
				"gold":55 + number * 25, "reputation":5 + number
			})
	return result

static func quest(quest_id: String) -> Dictionary:
	for definition in quests():
		if str(definition["id"]) == quest_id: return definition
	return {}

static func create_state() -> Dictionary:
	var reputation: Dictionary = {}
	var status: Dictionary = {}
	var stages: Dictionary = {}
	for faction_id in FACTIONS: reputation[faction_id] = 0
	for definition in quests():
		status[str(definition["id"])] = "available" if int(definition["chapter"]) == 1 else "locked"
		stages[str(definition["id"])] = 0
	return {"reputation":reputation, "quest_status":status, "quest_stages":stages, "active":[], "completed":[], "choices":{}, "world_events":[], "peace_score":0}

static func accept(state: Dictionary, quest_id: String) -> Dictionary:
	var definition := quest(quest_id)
	if definition.is_empty(): return {"success":false, "message":"Mision desconocida."}
	if str((state["quest_status"] as Dictionary).get(quest_id, "locked")) != "available": return {"success":false, "message":"Esta mision no esta disponible."}
	if (state["active"] as Array).size() >= MAX_ACTIVE_QUESTS: return {"success":false, "message":"Ya hay tres encargos de faccion activos."}
	(state["active"] as Array).append(quest_id)
	(state["quest_status"] as Dictionary)[quest_id] = "active"
	(state["quest_stages"] as Dictionary)[quest_id] = 1
	return {"success":true, "message":"Mision aceptada: %s." % definition["title"]}

static func advance(state: Dictionary, quest_id: String, choice: String = "concord") -> Dictionary:
	var definition := quest(quest_id)
	if definition.is_empty() or str((state["quest_status"] as Dictionary).get(quest_id, "")) != "active": return {"success":false, "completed":false, "message":"La mision no esta activa."}
	var stage := int((state["quest_stages"] as Dictionary).get(quest_id, 1)) + 1
	(state["quest_stages"] as Dictionary)[quest_id] = stage
	if stage < int(definition["stages"]): return {"success":true, "completed":false, "message":"La investigacion avanza a su etapa %d." % stage}
	return complete(state, quest_id, choice)

static func complete(state: Dictionary, quest_id: String, choice: String = "concord") -> Dictionary:
	var definition := quest(quest_id)
	if definition.is_empty() or str((state["quest_status"] as Dictionary).get(quest_id, "")) != "active": return {"success":false, "completed":false, "gold":0, "message":"La mision no esta activa."}
	(state["quest_status"] as Dictionary)[quest_id] = "completed"
	(state["active"] as Array).erase(quest_id)
	(state["completed"] as Array).append(quest_id)
	(state["choices"] as Dictionary)[quest_id] = choice
	var faction_id := str(definition["faction"])
	var delta := int(definition["reputation"])
	(state["reputation"] as Dictionary)[faction_id] = clampi(int((state["reputation"] as Dictionary)[faction_id]) + delta, -100, 100)
	if choice == "concord": state["peace_score"] = int(state["peace_score"]) + 1
	var next_id := "%s_%02d" % [faction_id, int(definition["chapter"]) + 1]
	if quest(next_id).size() > 0: (state["quest_status"] as Dictionary)[next_id] = "available"
	var event_id := "%s_event_%02d" % [faction_id, int(definition["chapter"])]
	(state["world_events"] as Array).append(event_id)
	return {"success":true, "completed":true, "gold":int(definition["gold"]), "reputation":delta, "message":"Mision completada: %s." % definition["title"]}

static func journal_entries(state: Dictionary) -> Array:
	var result: Array = []
	for definition in quests():
		var quest_id := str(definition["id"])
		var status := str((state.get("quest_status", {}) as Dictionary).get(quest_id, "locked"))
		if status == "locked": continue
		var entry: Dictionary = (definition as Dictionary).duplicate(true)
		entry["entry_type"] = "faction_quest"
		entry["status"] = status
		entry["objective"] = "%s · Etapa %d/3" % [definition["objective"], int((state["quest_stages"] as Dictionary).get(quest_id, 0))]
		result.append(entry)
	return result

static func dialogue_lines(quest_id: String, stage: int = 1) -> Array:
	var definition := quest(quest_id)
	if definition.is_empty(): return []
	var faction_name := str(FACTIONS[definition["faction"]]["name"])
	return [
		{"speaker":"Emisaria", "text":"%s necesita viajeros capaces de escuchar antes de desenvainar." % faction_name, "expression":"serious", "camera":"medium"},
		{"speaker":"Aren", "text":"No prometo obediencia. Prometo descubrir la verdad de %s." % str(definition["title"]), "expression":"determined", "camera":"close_up"},
		{"speaker":"Lyra", "text":"Cada faccion conserva una parte del relato. Ninguna posee el libro entero.", "expression":"thoughtful", "camera":"party"},
		{"speaker":"Emisaria", "text":"Entonces regresa con una decision que Eryndor pueda sobrevivir. Etapa %d." % stage, "expression":"calm", "camera":"wide"}
	]

static func rank_name(reputation: int) -> String:
	if reputation >= 75: return "Leyenda"
	if reputation >= 40: return "Aliado"
	if reputation >= 15: return "Confiable"
	if reputation <= -40: return "Enemigo"
	return "Desconocido"

static func ending(state: Dictionary) -> String:
	if (state.get("completed", []) as Array).size() < 24: return "incomplete"
	if int(state.get("peace_score", 0)) >= 18: return "concord_of_four"
	var best_faction := "lion_crown"
	for faction_id in FACTIONS:
		if int((state["reputation"] as Dictionary)[faction_id]) > int((state["reputation"] as Dictionary)[best_faction]): best_faction = faction_id
	return "ascendancy_%s" % best_faction

static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	if FACTIONS.size() != 4: errors.append("Deben existir cuatro facciones.")
	if quests().size() != 24: errors.append("Deben existir 24 misiones de faccion.")
	return errors

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not state.get("reputation", {}) is Dictionary or (state.get("reputation", {}) as Dictionary).size() != 4: errors.append("Reputaciones de faccion invalidas.")
	if not state.get("quest_status", {}) is Dictionary or (state.get("quest_status", {}) as Dictionary).size() != 24: errors.append("Estado de misiones de faccion invalido.")
	if (state.get("active", []) as Array).size() > MAX_ACTIVE_QUESTS: errors.append("Hay demasiadas misiones activas.")
	for faction_id in state.get("reputation", {}) as Dictionary:
		if abs(int((state["reputation"] as Dictionary)[faction_id])) > 100: errors.append("Reputacion fuera de rango: %s." % faction_id)
	return errors
