extends Node2D

const VIEWPORT_SIZE := Vector2(960, 540)

var profile: Dictionary = {}
var elapsed := 0.0
var reduced_motion := false

func configure(new_profile: Dictionary, new_elapsed: float, new_reduced_motion: bool) -> void:
	profile = new_profile
	elapsed = new_elapsed
	reduced_motion = new_reduced_motion
	queue_redraw()

func _draw() -> void:
	if profile.is_empty():
		return
	var theme_id := str(profile.get("id", ""))
	var foreground: Color = profile.get("foreground", Color(0.02, 0.03, 0.06, 0.65)) as Color
	var sway := 0.0 if reduced_motion else sin(elapsed * 0.7) * 3.0
	match theme_id:
		"valdoria":
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, 510), Vector2(92, 495 + sway), Vector2(170, 514),
				Vector2(812, 514), Vector2(887, 494 - sway), Vector2(960, 508),
				Vector2(960, 540), Vector2(0, 540)
			]), foreground)
			for x in range(18, 960, 94):
				draw_rect(Rect2(x, 506 + sin(x) * 3.0, 38, 34), Color(foreground, foreground.a * 0.78), true)
		"catacombs":
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, 482), Vector2(46, 466), Vector2(103, 505), Vector2(178, 487),
				Vector2(786, 495), Vector2(842, 468), Vector2(910, 487), Vector2(960, 470),
				Vector2(960, 540), Vector2(0, 540)
			]), foreground)
			draw_rect(Rect2(0, 0, 22, 540), Color(foreground, foreground.a * 0.72), true)
			draw_rect(Rect2(938, 0, 22, 540), Color(foreground, foreground.a * 0.72), true)
		"eira":
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, 514), Vector2(90, 492), Vector2(154, 519), Vector2(806, 519),
				Vector2(872, 488), Vector2(960, 510), Vector2(960, 540), Vector2(0, 540)
			]), foreground)
			var crystal_color: Color = profile.get("accent", Color("7cf7ff")) as Color
			for x in [52.0, 112.0, 846.0, 906.0]:
				var height := 22.0 + fmod(x, 31.0)
				var crystal := PackedVector2Array([
					Vector2(x - 8, 526), Vector2(x, 526 - height), Vector2(x + 9, 526)
				])
				draw_colored_polygon(crystal, Color(crystal_color, 0.38))
				draw_polyline(PackedVector2Array([crystal[0], crystal[1], crystal[2]]), Color(crystal_color, 0.8), 1.5)

