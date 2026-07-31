class_name CameraSystem
extends RefCounted

const VIEWPORT_SIZE := Vector2(960, 540)
const WORLD_RECT := Rect2(0, 0, 960, 540)

var position := WORLD_RECT.get_center()
var zoom := 1.10
var target_zoom := 1.10
var follow_speed := 7.5
var zoom_speed := 5.0

func snap(target: Vector2, desired_zoom: float = 1.10) -> void:
	zoom = clampf(desired_zoom, 1.0, 1.24)
	target_zoom = zoom
	position = clamp_position(target, zoom)

func update(delta: float, target: Vector2, is_running: bool, interaction_focus: bool = false) -> void:
	target_zoom = 1.18 if interaction_focus else (1.04 if is_running else 1.10)
	var follow_weight := 1.0 - exp(-follow_speed * maxf(delta, 0.0))
	var zoom_weight := 1.0 - exp(-zoom_speed * maxf(delta, 0.0))
	zoom = lerpf(zoom, target_zoom, zoom_weight)
	position = position.lerp(clamp_position(target, zoom), follow_weight)
	position = clamp_position(position, zoom)

func clamp_position(target: Vector2, at_zoom: float) -> Vector2:
	var half_view := VIEWPORT_SIZE * 0.5 / maxf(at_zoom, 1.0)
	return Vector2(
		clampf(target.x, WORLD_RECT.position.x + half_view.x, WORLD_RECT.end.x - half_view.x),
		clampf(target.y, WORLD_RECT.position.y + half_view.y, WORLD_RECT.end.y - half_view.y)
	)

func canvas_origin() -> Vector2:
	return VIEWPORT_SIZE * 0.5 - position * zoom

func world_to_screen(world_position: Vector2) -> Vector2:
	return canvas_origin() + world_position * zoom
