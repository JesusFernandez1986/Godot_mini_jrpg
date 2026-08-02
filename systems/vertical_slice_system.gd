class_name VerticalSliceSystem
extends RefCounted

const MILESTONES := [
	{"id":"oath", "label":"Aceptar el juramento de Elara"},
	{"id":"evidence", "label":"Recuperar registro y hoja lunar"},
	{"id":"seals", "label":"Activar los dos sellos"},
	{"id":"hunts", "label":"Vencer tres guardianes"},
	{"id":"miniboss", "label":"Derrotar al Caballero Perjuro"},
	{"id":"boss", "label":"Romper la Corona Hueca"},
	{"id":"return", "label":"Regresar con la capitana"},
	{"id":"decision", "label":"Elegir ante el Consejo Abierto"},
	{"id":"eira", "label":"Completar las Ruinas de Eira"}
]

static func completed_ids(phase3_state: Dictionary, dungeon_defeated: Array, dungeon_state: Dictionary, narrative_state: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	var main: Dictionary = phase3_state.get("main", {}) as Dictionary
	var flags: Dictionary = phase3_state.get("flags", {}) as Dictionary
	var side: Dictionary = phase3_state.get("side", {}) as Dictionary
	if str(main.get("status", "available")) != "available": result.append("oath")
	if bool(flags.get("ledger_found", false)) and bool(flags.get("herb_found", false)): result.append("evidence")
	if bool(flags.get("seal_west", false)) and bool(flags.get("seal_east", false)): result.append("seals")
	if int((side.get("sentry_oath", {}) as Dictionary).get("progress", 0)) >= 3: result.append("hunts")
	if "miniboss" in dungeon_defeated: result.append("miniboss")
	if "boss" in dungeon_defeated: result.append("boss")
	if str(main.get("status", "available")) == "completed": result.append("return")
	if str((narrative_state.get("variables", {}) as Dictionary).get("council_path", "undecided")) in ["truth", "mercy"]: result.append("decision")
	if "eira_ruins" in (dungeon_state.get("completed_dungeons", []) as Array): result.append("eira")
	return result

static func next_milestone(phase3_state: Dictionary, dungeon_defeated: Array, dungeon_state: Dictionary, narrative_state: Dictionary = {}) -> Dictionary:
	var completed := completed_ids(phase3_state, dungeon_defeated, dungeon_state, narrative_state)
	for milestone in MILESTONES:
		if str(milestone["id"]) not in completed: return (milestone as Dictionary).duplicate(true)
	return {"id":"complete", "label":"Vertical slice completada"}

static func completion_percent(phase3_state: Dictionary, dungeon_defeated: Array, dungeon_state: Dictionary, narrative_state: Dictionary = {}) -> float:
	return float(completed_ids(phase3_state, dungeon_defeated, dungeon_state, narrative_state).size()) * 100.0 / float(MILESTONES.size())

static func boss_directive(phase: int, shield: int) -> String:
	if shield <= 0: return "RUPTURA: concentra artes antes de que recomponga la corona."
	match phase:
		1: return "FASE I: alterna armas para descubrir las grietas del juramento."
		2: return "FASE II: protege al grupo de Miedo y guarda Resonancia."
		_: return "FASE III: rompe el escudo y ejecuta Convergencia del Cristal."

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var ids: Array[String] = []
	for milestone in MILESTONES:
		var id := str(milestone.get("id", ""))
		if id.is_empty() or id in ids: errors.append("Hito vertical duplicado o vacío: %s" % id)
		ids.append(id)
		if str(milestone.get("label", "")).is_empty(): errors.append("Hito %s sin descripción." % id)
	return errors
