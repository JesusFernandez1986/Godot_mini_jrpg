class_name InputProfileSystem
extends RefCounted

const DEVICE_KEYBOARD := "keyboard"
const DEVICE_CONTROLLER := "controller"

static var active_device := DEVICE_KEYBOARD

static func configure_actions() -> void:
	add_key("open_menu", KEY_M)
	add_key("open_menu", KEY_TAB)
	add_button("open_menu", 6)
	add_key("vertical_demo", KEY_V)
	add_key("camp", KEY_C)
	add_key("fast_travel", KEY_F)
	for command_index in 8:
		add_key("battle_command_%d" % (command_index + 1), KEY_1 + command_index)
	add_button("interact", 0)
	add_button("run", 9)
	add_axis("move_left", 0, -1.0)
	add_axis("move_right", 0, 1.0)
	add_axis("move_up", 1, -1.0)
	add_axis("move_down", 1, 1.0)
	add_button("move_up", 11)
	add_button("move_down", 12)
	add_button("move_left", 13)
	add_button("move_right", 14)
	add_button("ui_accept", 0)
	add_button("ui_cancel", 1)
	add_button("ui_up", 11)
	add_button("ui_down", 12)
	add_button("ui_left", 13)
	add_button("ui_right", 14)

static func observe(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		active_device = DEVICE_CONTROLLER
	elif event is InputEventKey or event is InputEventMouse:
		active_device = DEVICE_KEYBOARD

static func prompt(action: String) -> String:
	if active_device == DEVICE_CONTROLLER:
		return {"interact":"A", "open_menu":"START", "run":"LB", "ui_accept":"A", "ui_cancel":"B"}.get(action, action.to_upper())
	return {"interact":"E / ESPACIO", "open_menu":"M / ESC", "run":"SHIFT", "ui_accept":"ENTER", "ui_cancel":"ESC"}.get(action, action.to_upper())

static func add_key(action: String, keycode: Key) -> void:
	ensure_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	add_unique_event(action, event)

static func add_button(action: String, button_index: int) -> void:
	ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	add_unique_event(action, event)

static func add_axis(action: String, axis_index: int, axis_value: float) -> void:
	ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis_index
	event.axis_value = axis_value
	add_unique_event(action, event)

static func ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)

static func add_unique_event(action: String, event: InputEvent) -> void:
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

static func validate() -> Array[String]:
	var errors: Array[String] = []
	for action in ["move_left", "move_right", "move_up", "move_down", "run", "interact", "open_menu", "vertical_demo", "camp", "fast_travel"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			errors.append("Falta la acción %s." % action)
	for command_index in 8:
		if not InputMap.has_action("battle_command_%d" % (command_index + 1)):
			errors.append("Falta el acceso directo de combate %d." % (command_index + 1))
	return errors
