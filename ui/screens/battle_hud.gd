class_name BattleHUD
extends CanvasLayer

@onready var turns_box: HBoxContainer = $Root/Turns/Layout/Entries
@onready var enemy_title: Label = $Root/Enemy/Layout/Title
@onready var enemy_hp: ProgressBar = $Root/Enemy/Layout/HP
@onready var enemy_info: Label = $Root/Enemy/Layout/Info
@onready var party_box: HBoxContainer = $Root/Party
@onready var log_label: Label = $Root/Commands/Layout/Top/Log
@onready var resonance_label: Label = $Root/Commands/Layout/Top/Resonance
@onready var command_grid: GridContainer = $Root/Commands/Layout/Grid
@onready var hint_label: Label = $Root/Commands/Layout/Hint

func configure(turns: Array, party_members: Array, enemy: Dictionary, log_text: String, resonance: int, commands: Array, selected_command: int, target_name: String, active_name: String) -> void:
	rebuild_turns(turns)
	rebuild_party(party_members)
	enemy_title.text = "%s · FASE %d" % [str(enemy.get("name", "RIVAL")).to_upper(), int(enemy.get("phase", 1))]
	enemy_hp.max_value = maxf(1.0, float(enemy.get("max_hp", 1)))
	enemy_hp.value = float(enemy.get("hp", 0))
	enemy_info.text = "RUPTURA %d/%d · %s\nDébil: %s · Resiste: %s" % [int(enemy.get("shield", 0)), int(enemy.get("shield_max", 0)), str(enemy.get("intent", "—")).to_upper(), str(enemy.get("weaknesses", "—")), str(enemy.get("resistances", "—"))]
	log_label.text = log_text
	resonance_label.text = "RESONANCIA  %s" % ("◆".repeat(resonance) + "◇".repeat(PartyBattleSystem.MAX_RESONANCE - resonance))
	rebuild_commands(commands, selected_command, resonance)
	hint_label.text = "↑/↓ comando · ←/→ objetivo: %s · Actúa: %s" % [target_name, active_name]

func rebuild_turns(turns: Array) -> void:
	clear_children(turns_box)
	for entry in turns:
		var label := Label.new()
		label.custom_minimum_size = Vector2(103, 22)
		label.text = ("◆ " if bool(entry.get("current", false)) else "") + str(entry.get("name", "—"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("ffe5a3") if bool(entry.get("current", false)) else Color("ffb3b3") if bool(entry.get("enemy", false)) else Color.WHITE)
		label.add_theme_font_size_override("font_size", 11)
		turns_box.add_child(label)

func rebuild_party(party_members: Array) -> void:
	clear_children(party_box)
	for member in party_members:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(105, 63)
		var label := Label.new()
		label.text = "%s%s\nPV %d/%d · PM %d/%d\n%s" % ["◆ " if bool(member.get("active", false)) else "", str(member.get("name", "—")).to_upper(), int(member.get("hp", 0)), int(member.get("max_hp", 1)), int(member.get("mp", 0)), int(member.get("max_mp", 1)), str(member.get("status", "SIN ESTADOS"))]
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color("ffe5a3") if bool(member.get("active", false)) else Color.WHITE)
		panel.add_child(label)
		party_box.add_child(panel)

func rebuild_commands(commands: Array, selected: int, resonance: int) -> void:
	clear_children(command_grid)
	for command_index in commands.size():
		var label := Label.new()
		var enabled := command_index != 6 or resonance >= PartyBattleSystem.COMBO_COST
		label.custom_minimum_size = Vector2(214, 23)
		label.text = ("◆ " if command_index == selected else "   ") + "%d · %s" % [command_index + 1, str(commands[command_index])]
		label.add_theme_color_override("font_color", Color("ffe5a3") if command_index == selected and enabled else Color.WHITE if enabled else Color("596873"))
		label.add_theme_font_size_override("font_size", 12)
		command_grid.add_child(label)

func clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func command_count() -> int:
	return command_grid.get_child_count()
