class_name GameUI
extends RefCounted

static func wrap_text(text: String, max_characters: int) -> Array[String]:
	var result: Array[String] = []
	var current_line := ""
	for word in text.split(" "):
		var candidate := word if current_line.is_empty() else current_line + " " + word
		if candidate.length() > max_characters and not current_line.is_empty():
			result.append(current_line)
			current_line = word
		else:
			current_line = candidate
	if not current_line.is_empty():
		result.append(current_line)
	return result

static func wrapped_text(canvas: Node2D, text: String, position: Vector2, max_characters: int, line_height: float, font_size: int, color: Color) -> void:
	var lines := wrap_text(text, max_characters)
	for i in lines.size():
		canvas.draw_string(ThemeDB.fallback_font, position + Vector2(0, line_height * i), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

static func panel(canvas: Node2D, rectangle: Rect2, fill: Color = Color("07101af2"), border: Color = Color("d5c47f"), border_width: float = 2.0) -> void:
	canvas.draw_rect(rectangle, fill, true)
	canvas.draw_rect(rectangle, border, false, border_width)

static func bar(canvas: Node2D, position: Vector2, size: Vector2, current: int, maximum: int, tint: Color) -> void:
	canvas.draw_rect(Rect2(position, size), Color("080d18"), true)
	var ratio: float = clamp(float(current) / float(maxi(1, maximum)), 0.0, 1.0)
	canvas.draw_rect(Rect2(position + Vector2(3, 3), Vector2((size.x - 6) * ratio, size.y - 6)), tint, true)
	canvas.draw_rect(Rect2(position, size), Color("d8c99b"), false, 2)

static func shadow(canvas: Node2D, position: Vector2, radius: float, opacity: float = 0.42) -> void:
	canvas.draw_set_transform(position, 0.0, Vector2(1.7, 0.42))
	canvas.draw_circle(Vector2.ZERO, radius, Color(0.02, 0.05, 0.08, opacity))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func dynamic_shadow(canvas: Node2D, position: Vector2, radius: float, world_time: float, depth: float = 1.0, opacity: float = 0.42) -> void:
	var light_angle := -0.72 + sin(world_time * 0.08) * 0.08
	var length := 7.0 + 8.0 * clampf(depth, 0.0, 1.0)
	var offset := Vector2(cos(light_angle), sin(light_angle)) * length
	canvas.draw_set_transform(position + offset, light_angle, Vector2(1.75 + depth * 0.25, 0.38))
	canvas.draw_circle(Vector2.ZERO, radius, Color(0.015, 0.025, 0.045, opacity))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func character_source(sheet: Texture2D, character_index: int) -> Rect2:
	var cell_width: float = float(sheet.get_width()) / 4.0
	return Rect2(cell_width * character_index, 0, cell_width, float(sheet.get_height()))

static func grid_source(sheet: Texture2D, sprite_index: int, columns: int, rows: int) -> Rect2:
	var safe_columns := maxi(columns, 1)
	var safe_rows := maxi(rows, 1)
	var cell := Vector2(float(sheet.get_width()) / safe_columns, float(sheet.get_height()) / safe_rows)
	var safe_index := clampi(sprite_index, 0, safe_columns * safe_rows - 1)
	return Rect2(Vector2(safe_index % safe_columns, safe_index / safe_columns) * cell, cell)

static func grid_sprite(canvas: Node2D, sheet: Texture2D, sprite_index: int, feet_position: Vector2, display_size: Vector2, animation: String, world_time: float, action_time: float, tint: Color = Color.WHITE, columns: int = 4, rows: int = 2) -> void:
	var offset := Vector2(0, sin(world_time * 3.0 + sprite_index) * 2.0)
	if animation == "hurt": offset.x = sin(action_time * 52.0) * 7.0
	elif animation == "attack_left": offset.x = -sin(clampf(action_time / 0.62, 0.0, 1.0) * PI) * 72.0
	var destination := Rect2(feet_position.x - display_size.x * 0.5 + offset.x, feet_position.y - display_size.y + offset.y, display_size.x, display_size.y)
	canvas.draw_texture_rect_region(sheet, destination, grid_source(sheet, sprite_index, columns, rows), tint)

static func character(canvas: Node2D, sheet: Texture2D, character_index: int, feet_position: Vector2, display_size: Vector2, animation: String, world_time: float, walk_time: float, action_time: float, tint: Color = Color.WHITE) -> void:
	var offset := Vector2.ZERO
	var animated_size := display_size
	match animation:
		"walk", "travel":
			offset.x = sin(walk_time) * 2.5
			offset.y = -abs(sin(walk_time)) * 5.0
			animated_size.y *= 1.0 + abs(sin(walk_time)) * 0.035
		"run":
			offset.x = sin(walk_time * 1.65) * 4.0
			offset.y = -abs(sin(walk_time * 1.65)) * 8.0
			animated_size.y *= 1.0 + abs(sin(walk_time * 1.65)) * 0.055
		"talk":
			offset.y = -abs(sin(world_time * 6.5 + character_index)) * 4.0
			animated_size.x *= 1.0 + sin(world_time * 6.5) * 0.018
		"attack":
			offset.x = sin(clampf(action_time / 0.65, 0.0, 1.0) * PI) * 82.0
			offset.y = -sin(clampf(action_time / 0.65, 0.0, 1.0) * PI) * 8.0
		"attack_left":
			offset.x = -sin(clampf(action_time / 0.62, 0.0, 1.0) * PI) * 82.0
			offset.y = -sin(clampf(action_time / 0.62, 0.0, 1.0) * PI) * 8.0
		"special":
			offset.y = -sin(clampf(action_time / 0.9, 0.0, 1.0) * PI) * 32.0
			animated_size *= 1.0 + sin(clampf(action_time / 0.9, 0.0, 1.0) * PI) * 0.14
		"heal":
			offset.y = -abs(sin(clampf(action_time / 0.85, 0.0, 1.0) * PI)) * 18.0
			animated_size *= 1.0 + sin(clampf(action_time / 0.85, 0.0, 1.0) * PI) * 0.08
		"hurt":
			offset.x = sin(action_time * 52.0) * 7.0
		"fall":
			offset.y = action_time * 18.0
			animated_size.y *= maxf(0.72, 1.0 - action_time * 0.24)
		"open_chest", "mechanism", "use_item":
			offset.y = -sin(clampf(action_time / 0.7, 0.0, 1.0) * PI) * 9.0
		"rest":
			offset.y = sin(world_time * 2.2 + character_index) * 2.0
			animated_size.y *= 0.98
		"celebrate":
			offset.y = -abs(sin(clampf(action_time / 0.8, 0.0, 1.0) * PI * 2.0)) * 18.0
		_:
			offset.y = sin(world_time * 2.0 + character_index) * 1.5
			animated_size.y *= 1.0 + sin(world_time * 2.0 + character_index) * 0.012
	var destination := Rect2(feet_position.x - animated_size.x * 0.5 + offset.x, feet_position.y - animated_size.y * 0.78 + offset.y, animated_size.x, animated_size.y)
	canvas.draw_texture_rect_region(sheet, destination, character_source(sheet, character_index), tint)

static func animated_party_character(canvas: Node2D, atlas: Texture2D, character_index: int, feet_position: Vector2, display_size: Vector2, animation: String, direction: String, elapsed: float, tint: Color = Color.WHITE) -> void:
	var safe_animation := animation if CharacterAnimationSystem.validate_state(animation) else "idle"
	var source := CharacterAnimationSystem.atlas_region(character_index, direction, safe_animation, elapsed)
	var offset := CharacterAnimationSystem.keyframe_offset(safe_animation, elapsed, character_index, direction)
	var pose_scale := AnimationFXSystem.pose_scale(safe_animation, elapsed, character_index)
	var pose_rotation := AnimationFXSystem.pose_rotation(safe_animation, elapsed, character_index, direction)
	var pivot := feet_position + offset
	var destination := Rect2(-display_size.x * 0.5, -display_size.y, display_size.x, display_size.y)
	canvas.draw_set_transform(pivot, pose_rotation, pose_scale)
	canvas.draw_texture_rect_region(atlas, destination, source, tint)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for spark_position in AnimationFXSystem.interaction_spark_positions(feet_position, safe_animation, elapsed, character_index):
		var sparkle := 2.0 + sin(elapsed * 19.0 + spark_position.x) * 1.1
		canvas.draw_circle(spark_position, sparkle, Color("a8f4ff") if safe_animation in ["heal", "special"] else Color("ffe68a"))
