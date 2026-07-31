class_name SettingsManager
extends RefCounted

const SETTINGS_PATH := "user://settings.json"
const RESOLUTIONS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const TEXT_SPEEDS := [24.0, 42.0, 70.0, 1000.0]
const TEXT_SPEED_NAMES := ["Lenta", "Normal", "Rápida", "Instantánea"]
const WINDOW_MODE_NAMES := ["Ventana", "Sin bordes", "Pantalla completa"]
const CONTROL_SCHEME_NAMES := ["Mixto", "WASD", "Flechas"]

var values: Dictionary = default_values()

static func default_values() -> Dictionary:
	return {
		"master_volume": 0.85,
		"music_volume": 0.70,
		"sfx_volume": 0.80,
		"text_speed_index": 1,
		"resolution_index": 0,
		"window_mode": 0,
		"control_scheme": 0
	}

func load_settings(path: String = SETTINGS_PATH) -> bool:
	if not FileAccess.file_exists(path):
		values = default_values()
		apply_all()
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		GameLogger.warning("settings", "Unable to open settings file", {"path": path})
		values = default_values()
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		GameLogger.warning("settings", "Invalid settings JSON; defaults restored")
		values = default_values()
		return false
	values = sanitize(parsed as Dictionary)
	apply_all()
	return true

func save_settings(path: String = SETTINGS_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		GameLogger.error("settings", "Unable to write settings", {"path": path})
		return false
	file.store_string(JSON.stringify(sanitize(values), "\t"))
	file.close()
	GameLogger.info("settings", "Settings saved")
	return true

func sanitize(input: Dictionary) -> Dictionary:
	var result := default_values()
	result["master_volume"] = clampf(float(input.get("master_volume", result["master_volume"])), 0.0, 1.0)
	result["music_volume"] = clampf(float(input.get("music_volume", result["music_volume"])), 0.0, 1.0)
	result["sfx_volume"] = clampf(float(input.get("sfx_volume", result["sfx_volume"])), 0.0, 1.0)
	result["text_speed_index"] = clampi(int(input.get("text_speed_index", result["text_speed_index"])), 0, TEXT_SPEEDS.size() - 1)
	result["resolution_index"] = clampi(int(input.get("resolution_index", result["resolution_index"])), 0, RESOLUTIONS.size() - 1)
	result["window_mode"] = clampi(int(input.get("window_mode", result["window_mode"])), 0, WINDOW_MODE_NAMES.size() - 1)
	result["control_scheme"] = clampi(int(input.get("control_scheme", result["control_scheme"])), 0, CONTROL_SCHEME_NAMES.size() - 1)
	return result

func adjust(setting: String, direction: int) -> void:
	match setting:
		"master_volume", "music_volume", "sfx_volume":
			values[setting] = clampf(float(values[setting]) + direction * 0.05, 0.0, 1.0)
		"text_speed_index":
			values[setting] = wrapi(int(values[setting]) + direction, 0, TEXT_SPEEDS.size())
		"resolution_index":
			values[setting] = wrapi(int(values[setting]) + direction, 0, RESOLUTIONS.size())
		"window_mode":
			values[setting] = wrapi(int(values[setting]) + direction, 0, WINDOW_MODE_NAMES.size())
		"control_scheme":
			values[setting] = wrapi(int(values[setting]) + direction, 0, CONTROL_SCHEME_NAMES.size())
	apply_all()

func reset_defaults() -> void:
	values = default_values()
	apply_all()

func text_characters_per_second() -> float:
	return TEXT_SPEEDS[int(values["text_speed_index"])]

func display_value(setting: String) -> String:
	match setting:
		"master_volume", "music_volume", "sfx_volume":
			return "%d%%" % int(round(float(values[setting]) * 100.0))
		"text_speed_index":
			return TEXT_SPEED_NAMES[int(values[setting])]
		"resolution_index":
			var resolution: Vector2i = RESOLUTIONS[int(values[setting])]
			return "%d × %d" % [resolution.x, resolution.y]
		"window_mode":
			return WINDOW_MODE_NAMES[int(values[setting])]
		"control_scheme":
			return CONTROL_SCHEME_NAMES[int(values[setting])]
	return ""

func apply_all() -> void:
	apply_audio()
	apply_controls()
	apply_window()

func apply_audio() -> void:
	set_bus_volume("Master", float(values["master_volume"]))
	ensure_audio_bus("Music")
	ensure_audio_bus("SFX")
	set_bus_volume("Music", float(values["music_volume"]))
	set_bus_volume("SFX", float(values["sfx_volume"]))

func ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, linear)))
		AudioServer.set_bus_mute(index, linear <= 0.001)

func apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: int = int(values["window_mode"])
	if mode == 2:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif mode == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		var screen: int = DisplayServer.window_get_current_screen()
		DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(RESOLUTIONS[int(values["resolution_index"])])

func apply_controls() -> void:
	var scheme: int = int(values["control_scheme"])
	var key_sets := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN]
	}
	for action in key_sets:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var keys: Array = key_sets[action]
		var selected_keys: Array = keys if scheme == 0 else [keys[0] if scheme == 1 else keys[1]]
		for key_code in selected_keys:
			var input_event := InputEventKey.new()
			input_event.physical_keycode = int(key_code)
			InputMap.action_add_event(action, input_event)
