extends Node2D

const VIEWPORT_SIZE := Vector2(960, 540)

var backdrop: Texture2D
var profile: Dictionary = {}
var camera_origin := Vector2.ZERO
var camera_zoom := 1.0
var elapsed := 0.0
var reduced_motion := false

func configure(
	new_backdrop: Texture2D,
	new_profile: Dictionary,
	new_camera_origin: Vector2,
	new_camera_zoom: float,
	new_elapsed: float,
	new_reduced_motion: bool
) -> void:
	backdrop = new_backdrop
	profile = new_profile
	camera_origin = new_camera_origin
	camera_zoom = new_camera_zoom
	elapsed = new_elapsed
	reduced_motion = new_reduced_motion
	queue_redraw()

func _draw() -> void:
	if backdrop == null or profile.is_empty():
		return
	var screen := Rect2(Vector2.ZERO, VIEWPORT_SIZE)
	var background_rect := Rect2(camera_origin, VIEWPORT_SIZE * camera_zoom)
	draw_texture_rect(backdrop, background_rect, false)
	draw_rect(screen, profile.get("grade", Color.TRANSPARENT), true)
	var drift := 0.0 if reduced_motion else sin(elapsed * 0.23) * 14.0
	var light_anchor: Vector2 = profile.get("light_anchor", Vector2(160, 20)) as Vector2
	var light_color: Color = profile.get("light", Color(1, 0.8, 0.45, 0.08)) as Color
	for index in int(profile.get("shafts", 3)):
		var offset := float(index - 1) * 118.0 + drift * (0.6 + index * 0.17)
		var width := 58.0 + index * 22.0
		var shaft := PackedVector2Array([
			light_anchor + Vector2(offset - width * 0.24, 0),
			light_anchor + Vector2(offset + width * 0.24, 0),
			Vector2(light_anchor.x + offset + width, 468),
			Vector2(light_anchor.x + offset - width, 468)
		])
		draw_colored_polygon(shaft, Color(light_color, light_color.a * (1.0 - index * 0.13)))
	var fog_color: Color = profile.get("fog", Color(0.7, 0.8, 0.9, 0.04)) as Color
	var fog_speed := 0.0 if reduced_motion else elapsed * float(profile.get("fog_speed", 7.0))
	for index in int(profile.get("fog_banks", 5)):
		var fog_x := fposmod(float(index * 227) + fog_speed, 1240.0) - 150.0
		var fog_y := 330.0 + float(index % 3) * 54.0
		draw_set_transform(Vector2(fog_x, fog_y), 0.0, Vector2(2.2, 0.42))
		draw_circle(Vector2.ZERO, 96.0 + index * 9.0, Color(fog_color, fog_color.a * (0.82 + index * 0.04)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mote_color: Color = profile.get("mote", Color(0.8, 0.9, 1.0, 0.5)) as Color
	var mote_velocity: Vector2 = profile.get("mote_velocity", Vector2(7, -11)) as Vector2
	for index in int(profile.get("motes", 24)):
		var mote_elapsed := 0.0 if reduced_motion else elapsed
		var mote := WorldPresentationSystem.atmospheric_point(index, mote_elapsed, mote_velocity, VIEWPORT_SIZE)
		var radius := 0.8 + float(index % 4) * 0.45
		draw_circle(mote, radius, Color(mote_color, mote_color.a * (0.55 + float(index % 3) * 0.18)))
	var vignette: Color = profile.get("vignette", Color(0.01, 0.02, 0.05, 0.3)) as Color
	draw_rect(Rect2(0, 0, 960, 34), vignette, true)
	draw_rect(Rect2(0, 506, 960, 34), vignette, true)
	draw_rect(Rect2(0, 0, 28, 540), vignette, true)
	draw_rect(Rect2(932, 0, 28, 540), vignette, true)
