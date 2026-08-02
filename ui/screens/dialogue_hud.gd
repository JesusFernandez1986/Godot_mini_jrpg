class_name DialogueHUD
extends CanvasLayer

@onready var speaker_label: Label = $Root/Panel/Layout/Header/Speaker
@onready var direction_label: Label = $Root/Panel/Layout/Header/Direction
@onready var story_label: Label = $Root/Panel/Layout/Story
@onready var choices_box: VBoxContainer = $Root/Panel/Layout/Choices
@onready var prompt_label: Label = $Root/Panel/Layout/Footer/Prompt
@onready var progress_label: Label = $Root/Panel/Layout/Footer/Progress

func configure(speaker: String, text: String, expression: String, music_cue: String, line_index: int, line_count: int, revealed: bool, choices: Array, selected_choice: int) -> void:
	speaker_label.text = speaker.to_upper()
	speaker_label.modulate = NarrativeDirectionSystem.expression_color(expression)
	direction_label.text = "%s · %s" % [expression.to_upper(), music_cue.to_upper()] if not music_cue.is_empty() else expression.to_upper()
	direction_label.visible = not direction_label.text.strip_edges().is_empty()
	story_label.text = text
	for child in choices_box.get_children():
		child.queue_free()
	for choice_index in choices.size():
		var label := Label.new()
		label.text = ("◆  " if choice_index == selected_choice else "    ") + str(choices[choice_index])
		label.add_theme_color_override("font_color", Color("ffe5a3") if choice_index == selected_choice else Color.WHITE)
		label.add_theme_font_size_override("font_size", 12)
		choices_box.add_child(label)
	choices_box.visible = revealed and not choices.is_empty()
	prompt_label.text = "↑/↓ elegir · Confirmar" if not choices.is_empty() else "Confirmar · mostrar texto" if not revealed else "Confirmar · continuar"
	progress_label.text = "%d / %d" % [line_index + 1, maxi(1, line_count)]

func choice_count() -> int:
	return choices_box.get_child_count()

