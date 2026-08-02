class_name HeroStorySystem
extends RefCounted

const DEFAULT_PATH := "res://data/stories/phase10_heroes.json"
const HERO_ORDER := ["aren", "lyra", "brom", "seris", "naia", "kael", "mira", "orin"]
const MAX_ACTIVE_PARTY := 4

var data: Dictionary = {}

func _init(path: String = DEFAULT_PATH) -> void:
	load_database(path)

func load_database(path: String = DEFAULT_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		data = {}
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	data = parsed as Dictionary if parsed is Dictionary else {}
	return not data.is_empty()

func create_state() -> Dictionary:
	return {
		"completed_chapters":[],
		"active_chapter":"",
		"chapter_outcomes":{},
		"unlocked_heroes":["aren"],
		"completed_cross_quests":[],
		"unlocked_cross_quests":[],
		"bonds":{},
		"finale_status":"locked",
		"ending_choice":"",
		"epilogues":{}
	}

func hero(hero_id: String) -> Dictionary:
	return (data.get("heroes", {}) as Dictionary).get(hero_id, {}) as Dictionary

func chapter(chapter_id: String) -> Dictionary:
	for hero_id in HERO_ORDER:
		var definition := hero(hero_id)
		for raw_chapter in definition.get("chapters", []) as Array:
			var entry: Dictionary = raw_chapter
			if str(entry.get("id", "")) == chapter_id:
				var result := entry.duplicate(true)
				result["hero_id"] = hero_id
				result["hero_name"] = str(definition.get("name", hero_id.capitalize()))
				result["antagonist"] = str(definition.get("antagonist", ""))
				result["boss"] = str(definition.get("boss", ""))
				result["conflict"] = str(definition.get("conflict", ""))
				return result
	return {}

func chapter_index(chapter_id: String) -> int:
	var definition := chapter(chapter_id)
	if definition.is_empty(): return -1
	var chapters: Array = hero(str(definition["hero_id"])).get("chapters", []) as Array
	for index in chapters.size():
		if str((chapters[index] as Dictionary).get("id", "")) == chapter_id: return index
	return -1

func chapter_status(state: Dictionary, chapter_id: String) -> String:
	if chapter_id in (state.get("completed_chapters", []) as Array): return "completed"
	if str(state.get("active_chapter", "")) == chapter_id: return "active"
	return "available" if can_start_chapter(state, chapter_id) else "locked"

func can_start_chapter(state: Dictionary, chapter_id: String) -> bool:
	var definition := chapter(chapter_id)
	if definition.is_empty() or chapter_id in (state.get("completed_chapters", []) as Array): return false
	if not str(state.get("active_chapter", "")).is_empty(): return false
	var index := chapter_index(chapter_id)
	if index <= 0: return true
	var prior: Dictionary = (hero(str(definition["hero_id"])).get("chapters", []) as Array)[index - 1]
	return str(prior.get("id", "")) in (state.get("completed_chapters", []) as Array)

func start_chapter(state: Dictionary, chapter_id: String) -> Dictionary:
	if not can_start_chapter(state, chapter_id):
		return {"success":false, "message":"Ese capítulo aún está bloqueado o ya se completó."}
	state["active_chapter"] = chapter_id
	return {"success":true, "message":"Comienza %s." % chapter(chapter_id).get("title", chapter_id)}

func complete_chapter(state: Dictionary, chapter_id: String, outcome: String = "truth") -> Dictionary:
	var definition := chapter(chapter_id)
	if definition.is_empty(): return {"success":false, "message":"Capítulo desconocido."}
	if chapter_id not in (state.get("completed_chapters", []) as Array): (state["completed_chapters"] as Array).append(chapter_id)
	state["active_chapter"] = ""
	(state["chapter_outcomes"] as Dictionary)[chapter_id] = outcome
	var hero_id := str(definition["hero_id"])
	if hero_id not in (state.get("unlocked_heroes", []) as Array): (state["unlocked_heroes"] as Array).append(hero_id)
	for other_id in HERO_ORDER:
		if other_id == hero_id or other_id not in (state.get("unlocked_heroes", []) as Array): continue
		var bond_key := canonical_bond(hero_id, other_id)
		(state["bonds"] as Dictionary)[bond_key] = int((state["bonds"] as Dictionary).get(bond_key, 0)) + 1
	refresh_cross_quests(state)
	if completed_chapter_count(state) >= 32: state["finale_status"] = "available"
	return {"success":true, "hero_id":hero_id, "message":"Capítulo completado. %s ya puede viajar y combatir con el grupo." % definition["hero_name"]}

func chapter_dialogue_lines(chapter_id: String) -> Array:
	var definition := chapter(chapter_id)
	if definition.is_empty(): return []
	var hero_name := str(definition["hero_name"])
	var antagonist := str(definition["antagonist"])
	var index := chapter_index(chapter_id)
	return [
		line("NARRADOR", "%s. %s" % [definition["place"], definition["synopsis"]], "pan_up", "solemn"),
		line(hero_name, "No he llegado hasta aquí para conservar una verdad cómoda. %s" % definition["conflict"], "close_up", "determined"),
		line(antagonist, antagonist_line(index, hero_name), "pan_left", "cold"),
		line(hero_name, "%s Pero ningún recuerdo merece convertirse en una cadena." % definition["revelation"], "pan_right", "resolve"),
		line("NARRADOR", closing_line(index, str(definition["boss"]), hero_name), "wide", "triumph")
	]

func journal_entries(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hero_id in HERO_ORDER:
		var definition := hero(hero_id)
		for raw_chapter in definition.get("chapters", []) as Array:
			var entry: Dictionary = raw_chapter
			var id := str(entry.get("id", ""))
			result.append({
				"id":id, "entry_type":"hero_chapter", "category":"personal",
				"title":"%s · %s" % [definition.get("name", hero_id), entry.get("title", id)],
				"objective":str(entry.get("synopsis", "")), "status":chapter_status(state, id),
				"hero_id":hero_id
			})
	for raw_cross in data.get("cross_quests", []) as Array:
		var cross: Dictionary = raw_cross
		var cross_id := str(cross.get("id", ""))
		var status := "completed" if cross_id in (state.get("completed_cross_quests", []) as Array) else "available" if cross_id in (state.get("unlocked_cross_quests", []) as Array) else "locked"
		result.append({"id":cross_id, "entry_type":"cross_quest", "category":"cross", "title":cross.get("title", cross_id), "objective":cross.get("summary", ""), "status":status})
	var finale: Dictionary = data.get("finale", {}) as Dictionary
	result.append({"id":finale.get("id", "common_finale"), "entry_type":"hero_finale", "category":"final", "title":finale.get("title", "Final común"), "objective":finale.get("summary", ""), "status":state.get("finale_status", "locked")})
	return result

func cross_quest(cross_id: String) -> Dictionary:
	for raw_cross in data.get("cross_quests", []) as Array:
		if str((raw_cross as Dictionary).get("id", "")) == cross_id: return (raw_cross as Dictionary).duplicate(true)
	return {}

func cross_dialogue_lines(cross_id: String) -> Array:
	var cross := cross_quest(cross_id)
	if cross.is_empty(): return []
	var heroes: Array = cross.get("heroes", []) as Array
	var first_name := str(hero(str(heroes[0])).get("name", heroes[0]))
	var second_name := str(hero(str(heroes[1])).get("name", heroes[1])) if heroes.size() > 1 else "GRUPO"
	return [
		line("NARRADOR", str(cross["summary"]), "wide", "camp"),
		line(first_name, "Si contamos solo mi parte, volveremos a fabricar el mismo silencio.", "close_up", "thoughtful"),
		line(second_name, "Entonces contaremos también dónde chocan nuestras versiones.", "pan_right", "warm"),
		line("GRUPO", "Ningún camino se abrirá para uno a costa de cerrar el de otro.", "wide", "resolve")
	]

func complete_cross_quest(state: Dictionary, cross_id: String) -> Dictionary:
	if cross_id not in (state.get("unlocked_cross_quests", []) as Array): return {"success":false, "message":"Conversación cruzada bloqueada."}
	if cross_id not in (state.get("completed_cross_quests", []) as Array): (state["completed_cross_quests"] as Array).append(cross_id)
	for hero_id in (cross_quest(cross_id).get("heroes", []) as Array):
		for other_id in (cross_quest(cross_id).get("heroes", []) as Array):
			if str(hero_id) == str(other_id): continue
			var key := canonical_bond(str(hero_id), str(other_id))
			(state["bonds"] as Dictionary)[key] = int((state["bonds"] as Dictionary).get(key, 0)) + 2
	return {"success":true, "message":"Conversación cruzada completada."}

func refresh_cross_quests(state: Dictionary) -> void:
	for raw_cross in data.get("cross_quests", []) as Array:
		var cross: Dictionary = raw_cross
		var ready := true
		for hero_id in cross.get("heroes", []) as Array:
			if completed_for_hero(state, str(hero_id)) < 2: ready = false; break
		var cross_id := str(cross.get("id", ""))
		if ready and cross_id not in (state.get("unlocked_cross_quests", []) as Array): (state["unlocked_cross_quests"] as Array).append(cross_id)

func finale_dialogue_lines() -> Array:
	var finale: Dictionary = data.get("finale", {}) as Dictionary
	var result: Array = [line("NARRADOR", str(finale.get("summary", "")), "wide", "finale")]
	for hero_id in HERO_ORDER:
		var definition := hero(hero_id)
		result.append(line(str(definition["name"]), finale_vow(hero_id), "close_up", "resolve"))
	result.append(line(str(finale.get("antagonist", "La Primera Reina")), "Sin una única memoria, vuestro mundo se romperá en ocho verdades.", "pan_up", "ominous"))
	result.append(line("GRUPO", "Entonces aprenderemos a vivir sin obligarlas a ser una sola.", "wide", "triumph"))
	return result

func complete_finale(state: Dictionary, ending_choice: String = "shared") -> Dictionary:
	if str(state.get("finale_status", "locked")) not in ["available", "active"]: return {"success":false, "message":"El capítulo final aún está bloqueado."}
	var choice := ending_choice if ending_choice in ["shared", "guarded", "released"] else "shared"
	state["finale_status"] = "completed"
	state["ending_choice"] = choice
	var epilogues: Dictionary = {}
	for hero_id in HERO_ORDER:
		var bond_total := bond_total_for(state, hero_id)
		epilogues[hero_id] = epilogue_text(hero_id, choice, bond_total)
	state["epilogues"] = epilogues
	return {"success":true, "message":"La Corona Hueca ha sido vencida. Se han escrito ocho epílogos variables.", "epilogues":epilogues}

func validate_data() -> Array[String]:
	var errors: Array[String] = []
	var heroes: Dictionary = data.get("heroes", {}) as Dictionary
	if heroes.size() != 8: errors.append("La fase 10 requiere ocho protagonistas.")
	var chapter_ids: Array[String] = []
	for hero_id in HERO_ORDER:
		var definition: Dictionary = heroes.get(hero_id, {}) as Dictionary
		if definition.is_empty(): errors.append("Falta el protagonista %s." % hero_id); continue
		if (definition.get("chapters", []) as Array).size() != 4: errors.append("%s debe tener cuatro capítulos." % hero_id)
		for field in ["conflict", "antagonist", "boss", "ability"]:
			if str(definition.get(field, "")).is_empty(): errors.append("%s no define %s." % [hero_id, field])
		for raw_chapter in definition.get("chapters", []) as Array:
			var entry: Dictionary = raw_chapter
			var id := str(entry.get("id", ""))
			if id.is_empty() or id in chapter_ids: errors.append("Capítulo inválido o duplicado: %s." % id)
			else: chapter_ids.append(id)
			for field in ["title", "place", "synopsis", "revelation"]:
				if str(entry.get(field, "")).is_empty(): errors.append("%s no define %s." % [id, field])
	if chapter_ids.size() != 32: errors.append("Deben existir exactamente 32 capítulos personales.")
	if (data.get("cross_quests", []) as Array).size() < 4: errors.append("Faltan misiones que crucen varias historias.")
	if (data.get("finale", {}) as Dictionary).is_empty(): errors.append("Falta el capítulo final común.")
	return errors

func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for chapter_id in state.get("completed_chapters", []) as Array:
		if chapter(str(chapter_id)).is_empty(): errors.append("Capítulo guardado desconocido: %s." % chapter_id)
	for hero_id in state.get("unlocked_heroes", []) as Array:
		if str(hero_id) not in HERO_ORDER: errors.append("Protagonista guardado desconocido: %s." % hero_id)
	if str(state.get("finale_status", "locked")) not in ["locked", "available", "active", "completed"]: errors.append("Estado final inválido.")
	return errors

func completed_chapter_count(state: Dictionary) -> int:
	return (state.get("completed_chapters", []) as Array).size()

func completed_for_hero(state: Dictionary, hero_id: String) -> int:
	var result := 0
	for raw_chapter in hero(hero_id).get("chapters", []) as Array:
		if str((raw_chapter as Dictionary).get("id", "")) in (state.get("completed_chapters", []) as Array): result += 1
	return result

func next_available_chapter(state: Dictionary) -> String:
	for hero_id in HERO_ORDER:
		for raw_chapter in hero(hero_id).get("chapters", []) as Array:
			var chapter_id := str((raw_chapter as Dictionary).get("id", ""))
			if can_start_chapter(state, chapter_id): return chapter_id
	return ""

func dialogue_count() -> int:
	return 32 * 5 + (data.get("cross_quests", []) as Array).size() * 4 + HERO_ORDER.size() + 11

static func active_party(party: Array) -> Array:
	var result: Array = []
	for member in party:
		if member is Dictionary and bool(member.get("joined", false)) and bool(member.get("active", false)): result.append(member)
	return result

static func normalize_roster(party: Array) -> void:
	var active_count := 0
	for member in party:
		if not member is Dictionary: continue
		if not member.has("active"): member["active"] = false
		if bool(member.get("active", false)) and bool(member.get("joined", false)) and active_count < MAX_ACTIVE_PARTY: active_count += 1
		else: member["active"] = false
	if active_count == 0:
		for member in party:
			if member is Dictionary and bool(member.get("joined", false)) and active_count < MAX_ACTIVE_PARTY:
				member["active"] = true
				active_count += 1

static func toggle_active(party: Array, character_id: String) -> Dictionary:
	normalize_roster(party)
	var target: Dictionary = {}
	for member in party:
		if member is Dictionary and str(member.get("id", "")) == character_id: target = member; break
	if target.is_empty() or not bool(target.get("joined", false)): return {"success":false, "message":"Ese protagonista todavía no se ha unido."}
	var active := active_party(party)
	if bool(target.get("active", false)):
		if active.size() <= 1: return {"success":false, "message":"Debe quedar al menos un protagonista activo."}
		target["active"] = false
		return {"success":true, "message":"%s pasa a la reserva." % target["name"]}
	if active.size() >= MAX_ACTIVE_PARTY: return {"success":false, "message":"El grupo activo ya tiene cuatro miembros."}
	target["active"] = true
	return {"success":true, "message":"%s entra en el grupo activo." % target["name"]}

static func canonical_bond(first: String, second: String) -> String:
	var pair := [first, second]
	pair.sort()
	return "%s+%s" % pair

static func line(speaker: String, text: String, camera: String, expression: String) -> Dictionary:
	return {"speaker":speaker, "text":text, "camera":camera, "expression":expression, "movement":"talk", "music":"phase10_story"}

static func antagonist_line(index: int, hero_name: String) -> String:
	var lines := [
		"Llegas tarde, %s. El relato ya fue escrito antes de que aprendieras a leerlo.",
		"La libertad que prometes solo cambia quién sostiene la llave.",
		"Tus aliados te abandonarán cuando conozcan el precio completo de tu verdad.",
		"Inclínate y conservaré una versión de ti que el mundo pueda admirar."
	]
	var template: String = lines[clampi(index, 0, lines.size() - 1)]
	return template % hero_name if "%s" in template else template

static func closing_line(index: int, boss_name: String, hero_name: String) -> String:
	var actions := ["acepta caminar junto a los demás", "abre una ruta que otros podrán corregir", "nombra en público aquello que temía", "vence sin reclamar el lugar del vencido"]
	return "Ante %s, %s %s." % [boss_name, hero_name, actions[clampi(index, 0, actions.size() - 1)]]

static func finale_vow(hero_id: String) -> String:
	return {
		"aren":"Mi juramento no tendrá dueño.", "lyra":"Mi mapa mostrará futuros, no destinos.",
		"brom":"Mi fragua recordará todas las manos.", "seris":"Mi nombre no borrará el de nadie.",
		"naia":"Mi mar tendrá refugios, no fronteras.", "kael":"Mis secretos protegerán personas, nunca instituciones.",
		"mira":"Mi canción dejará espacio para otra voz.", "orin":"Mis hallazgos regresarán a quienes los recuerdan."
	}.get(hero_id, "Caminaré junto a los demás.")

func bond_total_for(state: Dictionary, hero_id: String) -> int:
	var result := 0
	for key in (state.get("bonds", {}) as Dictionary):
		if str(key).begins_with(hero_id + "+") or str(key).ends_with("+" + hero_id): result += int((state["bonds"] as Dictionary)[key])
	return result

func epilogue_text(hero_id: String, choice: String, bond_total: int) -> String:
	var definition := hero(hero_id)
	var paths := {
		"shared":"ayuda a fundar una mesa itinerante donde cada región custodia una parte del cristal",
		"guarded":"acepta proteger los fragmentos mientras una nueva generación aprende a decidir",
		"released":"se despide del poder del cristal y reconstruye con herramientas ordinarias"
	}
	var bond_suffix := " junto a los compañeros que se convirtieron en su familia." if bond_total >= 8 else " sin dejar de volver a las hogueras del grupo."
	return "%s, %s, %s%s" % [definition.get("name", hero_id.capitalize()), definition.get("role", "viajero"), paths[choice], bond_suffix]
