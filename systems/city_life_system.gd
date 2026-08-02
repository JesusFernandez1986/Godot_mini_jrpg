class_name CityLifeSystem
extends RefCounted

const DEFAULT_PATH := "res://data/cities/phase8_cities.json"
const REQUIRED_VENUES := ["tavern", "inn", "market", "smithy", "house"]

var data: Dictionary = {}

func _init(path: String = DEFAULT_PATH) -> void:
	load_database(path)

func load_database(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		GameLogger.error("city", "Living-city database not found", {"path":path})
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		GameLogger.error("city", "Living-city database is invalid JSON", {"path":path})
		return false
	data = parsed as Dictionary
	return true

func create_state() -> Dictionary:
	var districts: Dictionary = {}
	var interiors: Dictionary = {}
	var conflicts: Dictionary = {}
	var activities: Dictionary = {}
	for city_id in cities():
		districts[city_id] = 0
		interiors[city_id] = ""
		conflicts[city_id] = {"stage":0, "status":"available", "choice":""}
		activities[city_id] = {"plays":0, "best":0, "reward_claimed":false}
	return {
		"districts":districts,
		"interiors":interiors,
		"visited_districts":{},
		"conversations":{},
		"rumors_seen":[],
		"conflicts":conflicts,
		"activities":activities,
		"service_uses":{},
		"local_minutes":0
	}

func cities() -> Dictionary:
	return data.get("cities", {}) as Dictionary

func city(city_id: String) -> Dictionary:
	return cities().get(city_id, {}) as Dictionary

func district_index(state: Dictionary, city_id: String) -> int:
	var districts: Array = city(city_id).get("districts", []) as Array
	return clampi(int((state.get("districts", {}) as Dictionary).get(city_id, 0)), 0, maxi(0, districts.size() - 1))

func district(state: Dictionary, city_id: String) -> Dictionary:
	var districts: Array = city(city_id).get("districts", []) as Array
	if districts.is_empty(): return {}
	return districts[district_index(state, city_id)] as Dictionary

func change_district(state: Dictionary, city_id: String, direction: int) -> Dictionary:
	var districts: Array = city(city_id).get("districts", []) as Array
	if districts.is_empty(): return {}
	var next := wrapi(district_index(state, city_id) + direction, 0, districts.size())
	(state.get("districts", {}) as Dictionary)[city_id] = next
	(state.get("interiors", {}) as Dictionary)[city_id] = ""
	var key := city_id + ":" + str((districts[next] as Dictionary)["id"])
	(state.get("visited_districts", {}) as Dictionary)[key] = true
	state["local_minutes"] = int(state.get("local_minutes", 0)) + 8
	return districts[next] as Dictionary

func current_interior(state: Dictionary, city_id: String) -> String:
	return str((state.get("interiors", {}) as Dictionary).get(city_id, ""))

func venue_by_id(city_id: String, venue_id: String) -> Dictionary:
	for district_data in city(city_id).get("districts", []) as Array:
		for venue in (district_data as Dictionary).get("venues", []) as Array:
			if str((venue as Dictionary).get("id", "")) == venue_id: return venue as Dictionary
	return {}

func enter_venue(state: Dictionary, city_id: String, venue_id: String) -> bool:
	if venue_by_id(city_id, venue_id).is_empty(): return false
	(state.get("interiors", {}) as Dictionary)[city_id] = venue_id
	state["local_minutes"] = int(state.get("local_minutes", 0)) + 5
	return true

func leave_venue(state: Dictionary, city_id: String) -> void:
	(state.get("interiors", {}) as Dictionary)[city_id] = ""

func chapter_tier(city_id: String, chapter: int) -> String:
	var required := int(city(city_id).get("required_chapter", 1))
	if chapter <= required: return "early"
	if chapter < 5: return "mid"
	return "late"

func visible_npcs(state: Dictionary, city_id: String, period: String) -> Array:
	var result: Array = []
	var district_data := district(state, city_id)
	var district_id := str(district_data.get("id", ""))
	var interior := current_interior(state, city_id)
	for npc_value in city(city_id).get("npcs", []) as Array:
		var npc: Dictionary = npc_value
		var scheduled := str((npc.get("schedule", {}) as Dictionary).get(period, district_id))
		if scheduled == district_id or (not interior.is_empty() and scheduled == interior): result.append(npc)
	return result

func conversation(state: Dictionary, city_id: String, period: String, chapter: int) -> Dictionary:
	var npcs := visible_npcs(state, city_id, period)
	if npcs.is_empty(): return {"npc_id":"", "lines":[]}
	var counts: Dictionary = state.get("conversations", {}) as Dictionary
	var selected: Dictionary = npcs[0]
	var selected_count := 999999
	for npc_value in npcs:
		var npc: Dictionary = npc_value
		var key := city_id + ":" + str(npc["id"])
		var count := int(counts.get(key, 0))
		if count < selected_count:
			selected = npc
			selected_count = count
	var npc_id := str(selected["id"])
	var conversation_key := city_id + ":" + npc_id
	counts[conversation_key] = selected_count + 1
	state["local_minutes"] = int(state.get("local_minutes", 0)) + 4
	var tier := chapter_tier(city_id, chapter)
	var core_line := str((selected.get("lines", {}) as Dictionary).get(tier, "La ciudad cambia con cada jornada."))
	var city_data := city(city_id)
	var district_data := district(state, city_id)
	var lines: Array = [
		[str(selected["name"]), core_line],
		["Aren", "¿Qué ha cambiado en %s desde nuestra última visita?" % str(district_data.get("name", city_id))],
		[str(selected["name"]), "Ahora es %s; se oyen %s." % [period, str(city_data.get("ambience", "la ciudad"))]],
		["Lyra", "Lo recordaré. Los detalles también cuentan la historia de un reino."]
	]
	return {"npc_id":npc_id, "lines":lines, "speaker":str(selected["name"]), "tier":tier}

func next_rumor(state: Dictionary, city_id: String) -> Dictionary:
	var seen: Array = state.get("rumors_seen", []) as Array
	for rumor_value in city(city_id).get("rumors", []) as Array:
		var rumor: Dictionary = rumor_value
		var key := city_id + ":" + str(rumor["id"])
		if key not in seen:
			seen.append(key)
			state["local_minutes"] = int(state.get("local_minutes", 0)) + 6
			return rumor
	return {"id":"", "text":"Los rumores de hoy ya han sido escuchados.", "unlocks":""}

func advance_conflict(state: Dictionary, city_id: String, choice: String = "concordia") -> Dictionary:
	var city_conflict := city(city_id).get("conflict", {}) as Dictionary
	var stages: Array = city_conflict.get("stages", []) as Array
	var conflicts: Dictionary = state.get("conflicts", {}) as Dictionary
	var progress: Dictionary = conflicts.get(city_id, {"stage":0, "status":"available", "choice":""}) as Dictionary
	if str(progress.get("status", "")) == "completed": return {"success":false, "message":"El conflicto local ya tiene una resolución."}
	var stage := clampi(int(progress.get("stage", 0)), 0, maxi(0, stages.size() - 1))
	var message := str(stages[stage])
	stage += 1
	progress["stage"] = stage
	if stage >= stages.size():
		progress["status"] = "completed"
		progress["choice"] = choice
		message += " Resolución: %s." % choice
	else:
		progress["status"] = "active"
	conflicts[city_id] = progress
	state["local_minutes"] = int(state.get("local_minutes", 0)) + 10
	return {"success":true, "message":message, "completed":str(progress["status"]) == "completed", "stage":stage}

func activity(city_id: String) -> Dictionary:
	return city(city_id).get("activity", {}) as Dictionary

func activity_challenge(state: Dictionary, city_id: String) -> Dictionary:
	var challenges: Array = activity(city_id).get("challenges", []) as Array
	if challenges.is_empty(): return {}
	var plays := int(((state.get("activities", {}) as Dictionary).get(city_id, {}) as Dictionary).get("plays", 0))
	return challenges[plays % challenges.size()] as Dictionary

func resolve_activity(state: Dictionary, city_id: String, selected_answer: int) -> Dictionary:
	var challenge := activity_challenge(state, city_id)
	if challenge.is_empty(): return {"success":false, "message":"La actividad no está disponible."}
	var activities: Dictionary = state.get("activities", {}) as Dictionary
	var progress: Dictionary = activities.get(city_id, {"plays":0, "best":0, "reward_claimed":false}) as Dictionary
	var correct := selected_answer == int(challenge.get("answer", -1))
	var score := 3 if correct else 1
	progress["plays"] = int(progress.get("plays", 0)) + 1
	progress["best"] = maxi(int(progress.get("best", 0)), score)
	var reward := correct and not bool(progress.get("reward_claimed", false))
	if reward: progress["reward_claimed"] = true
	activities[city_id] = progress
	state["local_minutes"] = int(state.get("local_minutes", 0)) + 7
	return {"success":true, "correct":correct, "score":score, "reward":reward, "message":"Respuesta correcta." if correct else "La ciudad conserva sus secretos; puedes intentarlo otra vez."}

func mark_service(state: Dictionary, city_id: String, venue_kind: String) -> void:
	var key := city_id + ":" + venue_kind
	var uses: Dictionary = state.get("service_uses", {}) as Dictionary
	uses[key] = int(uses.get(key, 0)) + 1
	state["local_minutes"] = int(state.get("local_minutes", 0)) + 8

func content_minutes(city_id: String) -> int:
	var city_data := city(city_id)
	var districts: Array = city_data.get("districts", []) as Array
	var npcs: Array = city_data.get("npcs", []) as Array
	var rumors: Array = city_data.get("rumors", []) as Array
	var conflict_stages: Array = (city_data.get("conflict", {}) as Dictionary).get("stages", []) as Array
	var challenges: Array = (city_data.get("activity", {}) as Dictionary).get("challenges", []) as Array
	return districts.size() * 5 + npcs.size() * 3 + rumors.size() * 2 + conflict_stages.size() * 4 + challenges.size() * 3

func validate_data() -> Array[String]:
	var errors: Array[String] = []
	if cities().size() != 4: errors.append("La base urbana debe contener cuatro ciudades.")
	for city_id in cities():
		var city_data := city(str(city_id))
		var districts: Array = city_data.get("districts", []) as Array
		if districts.size() < 3: errors.append("%s necesita al menos tres barrios." % city_id)
		var venue_kinds: Array[String] = []
		var district_ids: Array[String] = []
		var venue_ids: Array[String] = []
		for district_value in districts:
			var district_data: Dictionary = district_value
			district_ids.append(str(district_data.get("id", "")))
			for venue_value in district_data.get("venues", []) as Array:
				var venue: Dictionary = venue_value
				venue_ids.append(str(venue.get("id", "")))
				var kind := str(venue.get("kind", ""))
				if kind not in venue_kinds: venue_kinds.append(kind)
		for required in REQUIRED_VENUES:
			if required not in venue_kinds: errors.append("%s no ofrece %s." % [city_id, required])
		for npc_value in city_data.get("npcs", []) as Array:
			var npc: Dictionary = npc_value
			for period in WorldExplorationSystem.PERIODS:
				var scheduled := str((npc.get("schedule", {}) as Dictionary).get(period, ""))
				if scheduled not in district_ids and scheduled not in venue_ids: errors.append("Horario inválido para %s/%s." % [city_id, npc.get("id", "")])
		if content_minutes(str(city_id)) < 30: errors.append("%s no alcanza treinta minutos de contenido." % city_id)
	return errors

func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in ["districts", "interiors", "visited_districts", "conversations", "rumors_seen", "conflicts", "activities", "service_uses", "local_minutes"]:
		if not state.has(field): errors.append("Estado urbano sin campo %s." % field)
	for city_id in cities():
		if not (state.get("districts", {}) as Dictionary).has(city_id): errors.append("Falta el barrio actual de %s." % city_id)
		var interior := str((state.get("interiors", {}) as Dictionary).get(city_id, ""))
		if not interior.is_empty() and venue_by_id(str(city_id), interior).is_empty(): errors.append("Interior desconocido en %s." % city_id)
	return errors
