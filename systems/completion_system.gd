class_name CompletionSystem
extends RefCounted

const ACCESSIBILITY_DEFAULTS := {"high_contrast":false, "reduced_motion":false, "text_scale":1.0, "colorblind":"none", "auto_advance":false, "battle_speed":1.0, "screen_shake":1.0}
const TRANSLATIONS := {
	"es":{"new_game":"Nueva partida", "load_game":"Cargar partida", "bestiary":"Bestiario", "market":"Mercado", "factions":"Facciones", "arena":"Arena", "achievements":"Logros", "accessibility":"Accesibilidad"},
	"en":{"new_game":"New game", "load_game":"Load game", "bestiary":"Bestiary", "market":"Market", "factions":"Factions", "arena":"Arena", "achievements":"Achievements", "accessibility":"Accessibility"}
}

static func achievements() -> Array:
	var result: Array = []
	var groups := {
		"story":["first_oath", "four_cities", "all_heroes", "personal_tales", "common_finale"],
		"combat":["first_victory", "hunter_25", "hunter_100", "elite_10", "break_master"],
		"exploration":["first_dungeon", "six_dungeons", "all_secrets", "world_cartographer", "gatherer"],
		"collection":["bestiary_10", "bestiary_all", "rich_1000", "master_smith", "full_inventory"],
		"factions":["first_faction", "faction_12", "faction_all", "four_allies", "concord"],
		"endgame":["arena_5", "arena_15", "arena_25", "superboss_one", "superboss_all"],
		"mastery":["level_10", "level_25", "eight_jobs", "all_talents", "combo_master"],
		"legacy":["ng_plus", "legacy_25", "nightmare_win", "all_challenges", "platinum_memory"]
	}
	for category in groups:
		for index in (groups[category] as Array).size():
			var achievement_id := str((groups[category] as Array)[index])
			result.append({"id":achievement_id, "category":category, "name":achievement_id.replace("_", " ").capitalize(), "target":_target_for(achievement_id), "hidden":category == "legacy"})
	return result

static func _target_for(achievement_id: String) -> int:
	var explicit := {"hunter_25":25, "hunter_100":100, "elite_10":10, "bestiary_10":10, "bestiary_all":32, "rich_1000":1000, "faction_12":12, "faction_all":24, "arena_5":5, "arena_15":15, "arena_25":25, "superboss_all":8, "level_10":10, "level_25":25, "legacy_25":25, "all_challenges":20}
	return int(explicit.get(achievement_id, 1))

static func create_state() -> Dictionary:
	return {"unlocked":[], "progress":{}, "accessibility":ACCESSIBILITY_DEFAULTS.duplicate(true), "language":"es", "credits_seen":false, "release_version":"1.0.0", "play_metrics":{"battles":0, "steps":0, "combos":0}}

static func set_progress(state: Dictionary, achievement_id: String, value: int) -> bool:
	var definition := achievement(achievement_id)
	if definition.is_empty(): return false
	var progress: Dictionary = state["progress"]
	progress[achievement_id] = maxi(int(progress.get(achievement_id, 0)), value)
	if int(progress[achievement_id]) >= int(definition["target"]) and achievement_id not in (state["unlocked"] as Array):
		(state["unlocked"] as Array).append(achievement_id)
		return true
	return false

static func achievement(achievement_id: String) -> Dictionary:
	for definition in achievements():
		if str(definition["id"]) == achievement_id: return definition
	return {}

static func synchronize(state: Dictionary, snapshot: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	var values := {
		"first_victory":int(snapshot.get("defeated", 0)), "hunter_25":int(snapshot.get("defeated", 0)), "hunter_100":int(snapshot.get("defeated", 0)), "elite_10":int(snapshot.get("elite", 0)),
		"bestiary_10":int(snapshot.get("bestiary", 0)), "bestiary_all":int(snapshot.get("bestiary", 0)), "rich_1000":int(snapshot.get("gold", 0)),
		"first_faction":int(snapshot.get("factions", 0)), "faction_12":int(snapshot.get("factions", 0)), "faction_all":int(snapshot.get("factions", 0)),
		"arena_5":int(snapshot.get("arena", 0)), "arena_15":int(snapshot.get("arena", 0)), "arena_25":int(snapshot.get("arena", 0)),
		"superboss_one":int(snapshot.get("superbosses", 0)), "superboss_all":int(snapshot.get("superbosses", 0)), "ng_plus":int(snapshot.get("ng_plus", 0)), "legacy_25":int(snapshot.get("legacy", 0)),
		"four_cities":int(snapshot.get("cities", 0)) / 4, "all_heroes":int(snapshot.get("heroes", 0)) / 8, "personal_tales":int(snapshot.get("hero_chapters", 0)) / 32,
		"common_finale":int(snapshot.get("finale", 0)), "first_dungeon":int(snapshot.get("dungeons", 0)), "six_dungeons":int(snapshot.get("dungeons", 0)) / 6,
		"level_10":int(snapshot.get("max_level", 0)), "level_25":int(snapshot.get("max_level", 0))
	}
	for achievement_id in values:
		if set_progress(state, achievement_id, int(values[achievement_id])): newly_unlocked.append(achievement_id)
	return newly_unlocked

static func toggle_accessibility(state: Dictionary, option_id: String) -> Dictionary:
	var accessibility: Dictionary = state.get("accessibility", {})
	if option_id not in ["high_contrast", "reduced_motion", "auto_advance"]: return {"success":false, "message":"Opcion no conmutable."}
	accessibility[option_id] = not bool(accessibility.get(option_id, false))
	return {"success":true, "message":"%s: %s." % [option_id.replace("_", " "), "SI" if accessibility[option_id] else "NO"]}

static func cycle_language(state: Dictionary) -> String:
	state["language"] = "en" if str(state.get("language", "es")) == "es" else "es"
	return str(state["language"])

static func translate(state: Dictionary, key: String) -> String:
	var language := str(state.get("language", "es"))
	return str((TRANSLATIONS.get(language, TRANSLATIONS["es"]) as Dictionary).get(key, key))

static func credits() -> Array[String]:
	return ["Direccion: Cronistas de Eryndor", "Diseno narrativo: Archivo del Cristal", "Programacion: Taller de Valdoria", "Arte: Pintores del Velo", "Musica: Coro Astral", "Pruebas: Guardianes de la Brasa", "Gracias por recordar Eryndor."]

static func release_audit(states: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not states.has("bestiary") or not BestiarySystem.validate_state(states["bestiary"]).is_empty(): errors.append("Bestiario no preparado.")
	if not states.has("commerce") or not CommerceSystem.validate_state(states["commerce"]).is_empty(): errors.append("Economia no preparada.")
	if not states.has("factions") or not FactionSystem.validate_state(states["factions"]).is_empty(): errors.append("Facciones no preparadas.")
	if not states.has("endgame") or not EndgameSystem.validate_state(states["endgame"]).is_empty(): errors.append("Endgame no preparado.")
	return errors

static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	if achievements().size() != 40: errors.append("Deben existir cuarenta logros.")
	for language in ["es", "en"]:
		if not TRANSLATIONS.has(language) or (TRANSLATIONS[language] as Dictionary).size() != 8: errors.append("Traduccion incompleta: %s." % language)
	return errors

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(state.get("language", "")) not in ["es", "en"]: errors.append("Idioma invalido.")
	if not state.get("accessibility", {}) is Dictionary: errors.append("Opciones de accesibilidad invalidas.")
	for achievement_id in state.get("unlocked", []) as Array:
		if achievement(str(achievement_id)).is_empty(): errors.append("Logro desconocido: %s." % achievement_id)
	return errors
