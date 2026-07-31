class_name SaveSystem
extends RefCounted

const CURRENT_VERSION := 5
const SAVE_DIR := "user://saves"
const LEGACY_PATH := "user://cronicas_del_cristal_save.json"

static func slot_path(slot: int, base_dir: String = SAVE_DIR) -> String:
	return base_dir.path_join("slot_%d.json" % slot)

static func autosave_path(base_dir: String = SAVE_DIR) -> String:
	return base_dir.path_join("autosave.json")

static func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= 3

static func has_slot(slot: int, base_dir: String = SAVE_DIR) -> bool:
	if not is_valid_slot(slot):
		return false
	var path := slot_path(slot, base_dir)
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		return true
	return slot == 1 and base_dir == SAVE_DIR and FileAccess.file_exists(LEGACY_PATH)

static func has_autosave(base_dir: String = SAVE_DIR) -> bool:
	var path := autosave_path(base_dir)
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")

static func save_to_slot(slot: int, data: Dictionary, base_dir: String = SAVE_DIR) -> bool:
	if not is_valid_slot(slot):
		GameLogger.error("save", "Invalid manual save slot", {"slot": slot})
		return false
	return write_atomic(slot_path(slot, base_dir), build_envelope(data, "manual", slot))

static func save_autosave(data: Dictionary, base_dir: String = SAVE_DIR) -> bool:
	return write_atomic(autosave_path(base_dir), build_envelope(data, "auto", 0))

static func load_slot(slot: int, base_dir: String = SAVE_DIR) -> Dictionary:
	if not is_valid_slot(slot):
		return {}
	var path := slot_path(slot, base_dir)
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		return load_path(path)
	if slot == 1 and base_dir == SAVE_DIR and FileAccess.file_exists(LEGACY_PATH):
		var migrated := load_legacy_path(LEGACY_PATH)
		if not migrated.is_empty():
			save_to_slot(1, migrated)
		return migrated
	return {}

static func load_autosave(base_dir: String = SAVE_DIR) -> Dictionary:
	return load_path(autosave_path(base_dir))

static func slot_metadata(slot: int, base_dir: String = SAVE_DIR) -> Dictionary:
	if not has_slot(slot, base_dir):
		return {}
	var path := slot_path(slot, base_dir)
	var envelope := read_json(path)
	if envelope.is_empty() and FileAccess.file_exists(path + ".bak"):
		envelope = read_json(path + ".bak")
	if envelope.is_empty() and slot == 1 and base_dir == SAVE_DIR:
		var legacy := load_legacy_path(LEGACY_PATH)
		return metadata_from_payload(legacy, "legacy", 1) if not legacy.is_empty() else {}
	return envelope.get("metadata", {}) as Dictionary

static func autosave_metadata(base_dir: String = SAVE_DIR) -> Dictionary:
	if not has_autosave(base_dir):
		return {}
	var path := autosave_path(base_dir)
	var envelope := read_json(path)
	if envelope.is_empty() and FileAccess.file_exists(path + ".bak"):
		envelope = read_json(path + ".bak")
	return envelope.get("metadata", {}) as Dictionary

static func build_envelope(data: Dictionary, kind: String, slot: int) -> Dictionary:
	var migrated_payload := migrate_payload(data.duplicate(true))
	var normalized_variant: Variant = JSON.parse_string(JSON.stringify(migrated_payload))
	var payload: Dictionary = normalized_variant as Dictionary
	return {
		"format": "chronicles-save",
		"version": CURRENT_VERSION,
		"checksum": checksum_for_payload(payload),
		"metadata": metadata_from_payload(payload, kind, slot),
		"payload": payload
	}

static func metadata_from_payload(payload: Dictionary, kind: String, slot: int) -> Dictionary:
	var hero_name := "Aren"
	var party: Variant = payload.get("party", [])
	if party is Array and not (party as Array).is_empty():
		hero_name = str((party as Array)[0].get("name", hero_name))
	return {
		"kind": kind,
		"slot": slot,
		"chapter": int(payload.get("chapter", 0)),
		"location": str(payload.get("current_location", "valdoria")),
		"play_seconds": float(payload.get("play_seconds", 0.0)),
		"hero": hero_name,
		"saved_at": Time.get_datetime_string_from_system()
	}

static func write_atomic(path: String, envelope: Dictionary) -> bool:
	var absolute_dir := ProjectSettings.globalize_path(path.get_base_dir())
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		GameLogger.error("save", "Unable to create save directory", {"error": directory_error})
		return false
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		GameLogger.error("save", "Unable to open temporary save file", {"path": temporary_path})
		return false
	file.store_string(JSON.stringify(envelope, "\t"))
	file.flush()
	file.close()
	var absolute_target := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var backup_path := absolute_target + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(backup_path)
		var backup_error := DirAccess.rename_absolute(absolute_target, backup_path)
		if backup_error != OK:
			GameLogger.error("save", "Unable to rotate save backup", {"error": backup_error, "path": path})
			return false
	var rename_error := DirAccess.rename_absolute(absolute_temporary, absolute_target)
	if rename_error != OK:
		GameLogger.error("save", "Atomic save rename failed", {"error": rename_error, "path": path})
		if FileAccess.file_exists(path + ".bak") and not FileAccess.file_exists(path):
			DirAccess.rename_absolute(backup_path, absolute_target)
		return false
	GameLogger.info("save", "Save written", {"path": path})
	return true

static func load_path(path: String) -> Dictionary:
	var envelope := read_json(path)
	if envelope.is_empty():
		return try_backup(path)
	if str(envelope.get("format", "")) != "chronicles-save":
		return migrate_payload(envelope)
	var payload: Variant = envelope.get("payload", {})
	if not payload is Dictionary:
		GameLogger.error("save", "Save payload is not a dictionary", {"path": path})
		return try_backup(path)
	var expected := str(envelope.get("checksum", ""))
	var actual := checksum_for_payload(payload as Dictionary)
	if expected != actual:
		GameLogger.warning("save", "Save checksum mismatch; attempting backup", {"path": path})
		return try_backup(path)
	return migrate_payload(payload as Dictionary)

static func try_backup(path: String) -> Dictionary:
	var backup_path := path + ".bak"
	if not FileAccess.file_exists(backup_path):
		return {}
	GameLogger.warning("save", "Attempting backup recovery", {"path": backup_path})
	var envelope := read_json(backup_path)
	if envelope.is_empty():
		return {}
	var payload: Variant = envelope.get("payload", envelope)
	if not payload is Dictionary:
		return {}
	if str(envelope.get("format", "")) == "chronicles-save":
		var expected := str(envelope.get("checksum", ""))
		if expected != checksum_for_payload(payload as Dictionary):
			GameLogger.error("save", "Backup checksum mismatch", {"path": backup_path})
			return {}
	return migrate_payload(payload as Dictionary)

static func checksum_for_payload(payload: Dictionary) -> String:
	return JSON.stringify(canonicalize(payload)).sha256_text()

static func canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		var keys := (value as Dictionary).keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		for key in keys:
			result[str(key)] = canonicalize((value as Dictionary)[key])
		return result
	if value is Array:
		var result: Array = []
		for entry in value as Array:
			result.append(canonicalize(entry))
		return result
	return value

static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}

static func load_legacy_path(path: String) -> Dictionary:
	return migrate_payload(read_json(path))

static func migrate_payload(input: Dictionary) -> Dictionary:
	var payload := input.duplicate(true)
	var version := int(payload.get("save_version", 1))
	while version < CURRENT_VERSION:
		if version == 1:
			payload = migrate_v1_to_v2(payload)
			version = 2
		elif version == 2:
			payload = migrate_v2_to_v3(payload)
			version = 3
		elif version == 3:
			payload = migrate_v3_to_v4(payload)
			version = 4
		elif version == 4:
			payload = migrate_v4_to_v5(payload)
			version = 5
		else:
			GameLogger.error("save", "No migration path", {"version": version})
			return {}
	payload["save_version"] = CURRENT_VERSION
	return payload

static func migrate_v1_to_v2(payload: Dictionary) -> Dictionary:
	if not payload.has("visited_cities"):
		payload["visited_cities"] = {}
	if not payload.has("city_dialogue_progress"):
		payload["city_dialogue_progress"] = {"valdoria": 0, "brumaforja": 0, "celestia": 0, "sylvaran": 0}
	if not payload.has("gold"):
		payload["gold"] = 0
	GameLogger.info("save", "Migrated save payload", {"from": 1, "to": 2})
	return payload

static func migrate_v2_to_v3(payload: Dictionary) -> Dictionary:
	if not payload.has("facing_direction"):
		payload["facing_direction"] = "south"
	if not payload.has("opened_interactions"):
		payload["opened_interactions"] = {"chest": false, "mechanism": false, "altar": false}
	GameLogger.info("save", "Migrated save payload", {"from": 2, "to": 3})
	return payload

static func migrate_v3_to_v4(payload: Dictionary) -> Dictionary:
	if not payload.has("phase3_state"):
		payload["phase3_state"] = QuestSystem.create_phase3_state()
	if not payload.has("valdoria_position"):
		payload["valdoria_position"] = [477.0, 438.0]
	if not payload.has("dungeon_position"):
		payload["dungeon_position"] = [112.0, 438.0]
	if not payload.has("dungeon_defeated"):
		payload["dungeon_defeated"] = []
	GameLogger.info("save", "Migrated save payload", {"from": 3, "to": 4})
	return payload

static func migrate_v4_to_v5(payload: Dictionary) -> Dictionary:
	if not payload.has("resonance_tutorial_seen"):
		payload["resonance_tutorial_seen"] = false
	for member in payload.get("party", []) as Array:
		if member is Dictionary:
			var definition := GameDatabase.CHARACTERS.filter(func(entry: CharacterDefinition): return entry.id == str(member.get("id", "")))
			if not definition.is_empty():
				var character: CharacterDefinition = definition[0]
				member["element"] = str(member.get("element", character.element))
				member["weapon"] = str(member.get("weapon", character.weapon))
				member["weaknesses"] = member.get("weaknesses", character.weaknesses.duplicate())
				member["resistances"] = member.get("resistances", character.resistances.duplicate())
	GameLogger.info("save", "Migrated save payload", {"from": 4, "to": 5})
	return payload

# Backward-compatible aliases for the previous prototype API.
static func has_save() -> bool:
	return has_slot(1)

static func save_game(data: Dictionary) -> bool:
	return save_to_slot(1, data)

static func load_game() -> Dictionary:
	return load_slot(1)

static func save_game_to_path(path: String, data: Dictionary) -> bool:
	return write_atomic(path, build_envelope(data, "test", 0))

static func load_game_from_path(path: String) -> Dictionary:
	return load_path(path)
