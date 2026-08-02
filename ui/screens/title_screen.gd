extends CanvasLayer

signal option_activated(index: int)

@onready var buttons: Array[Button] = [
	$Root/MenuPanel/MenuMargin/Options/Demo,
	$Root/MenuPanel/MenuMargin/Options/NewGame,
	$Root/MenuPanel/MenuMargin/Options/LoadGame,
	$Root/MenuPanel/MenuMargin/Options/Settings,
	$Root/MenuPanel/MenuMargin/Options/Quit,
]
@onready var footer: Label = $Root/Footer

func _ready() -> void:
	for index in buttons.size():
		buttons[index].pressed.connect(_on_button_pressed.bind(index))

func configure(options: Array, selected_index: int, save_available: bool, dialogue_count: int) -> void:
	for index in mini(options.size(), buttons.size()):
		var selected := index == selected_index
		buttons[index].text = ("◆  " if selected else "    ") + str(options[index])
		buttons[index].disabled = index == 2 and not save_available
		buttons[index].add_theme_color_override("font_color", Color("ffe5a3") if selected else Color("c4d1dc"))
		buttons[index].add_theme_color_override("font_hover_color", Color("fff1bf"))
		buttons[index].add_theme_color_override("font_pressed_color", Color("9ee8d1"))
	footer.text = "%d diálogos · 8 héroes · 3 ranuras · autoguardado" % dialogue_count

func option_count() -> int:
	return buttons.size()

func _on_button_pressed(index: int) -> void:
	option_activated.emit(index)
