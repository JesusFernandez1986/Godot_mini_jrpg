class_name CombatPresentationSystem
extends RefCounted

const ELEMENT_COLORS := {
	"fire": Color("ff7a3d"), "ice": Color("72ddff"), "water": Color("55baff"),
	"lightning": Color("fff06a"), "earth": Color("d3a05f"), "wind": Color("b9ffe0"),
	"light": Color("fff2b0"), "dark": Color("b77aff"), "physical": Color("ffffff")
}

static func normalized_element(element: String) -> String:
	return element if element in ELEMENT_COLORS else "physical"

static func color(element: String) -> Color:
	return ELEMENT_COLORS[normalized_element(element)] as Color

static func effect_frame(element: String, progress: float) -> int:
	var stage := clampi(int(floor(clampf(progress, 0.0, 0.999) * 4.0)), 0, 3)
	match normalized_element(element):
		"fire": return stage
		"ice", "water": return 4 + stage
		"lightning": return 8 if stage == 0 else 9
		"wind": return 10 if stage < 2 else 11
		"light": return [12, 13, 14, 14][stage]
		"dark": return 15
		"earth": return [12, 13, 14, 14][stage]
	return 12 if stage < 2 else 13

static func hit_stop_seconds(damage: int, weak: bool) -> float:
	if damage <= 0: return 0.0
	return 0.095 if weak else 0.055

static func shake_amplitude(damage: int, weak: bool, reduced_motion: bool) -> float:
	if reduced_motion or damage <= 0: return 0.0
	return clampf(2.5 + sqrt(float(damage)) * (0.95 if weak else 0.55), 0.0, 13.0)

static func shake_offset(elapsed: float, amplitude: float) -> Vector2:
	return Vector2(sin(elapsed * 91.0), cos(elapsed * 73.0)) * amplitude * maxf(0.0, 1.0 - elapsed / 0.55)

static func validate() -> Array[String]:
	var errors: Array[String] = []
	for element in ELEMENT_COLORS:
		var frame := effect_frame(element, 0.5)
		if frame < 0 or frame >= 16: errors.append("VFX fuera del atlas para %s." % element)
	return errors
