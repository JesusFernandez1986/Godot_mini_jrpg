class_name WorldPresentationSystem
extends RefCounted

const PERIOD_SPEED := {"amanecer":0.72, "día":1.0, "atardecer":0.86, "noche":0.55}
const HD2D_PROFILES := {
	"valdoria": {
		"id":"valdoria", "grade":Color("4d210412"), "light":Color("ffd98a16"),
		"light_anchor":Vector2(92, 8), "shafts":4, "fog":Color("ffd9a20d"),
		"fog_speed":5.5, "fog_banks":4, "mote":Color("ffe9ad8f"),
		"mote_velocity":Vector2(5, -9), "motes":26, "vignette":Color("130d1838"),
		"foreground":Color("211821b8"), "accent":Color("ffd98a")
	},
	"catacombs": {
		"id":"catacombs", "grade":Color("08193836"), "light":Color("7fc8ff16"),
		"light_anchor":Vector2(690, 18), "shafts":3, "fog":Color("759dcc12"),
		"fog_speed":8.0, "fog_banks":6, "mote":Color("aecbdf8c"),
		"mote_velocity":Vector2(3, -7), "motes":34, "vignette":Color("02071372"),
		"foreground":Color("030712d9"), "accent":Color("78caff")
	},
	"eira": {
		"id":"eira", "grade":Color("24113f42"), "light":Color("8cf8ff1c"),
		"light_anchor":Vector2(470, 4), "shafts":5, "fog":Color("8d7bdb16"),
		"fog_speed":10.0, "fog_banks":7, "mote":Color("a6fbffb2"),
		"mote_velocity":Vector2(2, -13), "motes":42, "vignette":Color("09041b78"),
		"foreground":Color("09051bd1"), "accent":Color("7cf7ff")
	}
}

static func depth_scale(y: float, minimum: float = 0.72, maximum: float = 1.08) -> float:
	return lerpf(minimum, maximum, clampf(inverse_lerp(90.0, 500.0, y), 0.0, 1.0))

static func npc_patrol_position(anchor: Vector2, npc_index: int, elapsed: float, period: String) -> Vector2:
	var speed := float(PERIOD_SPEED.get(period, 0.8))
	var phase := npc_index * 1.73
	var radius := Vector2(28.0 + (npc_index % 3) * 9.0, 9.0 + (npc_index % 2) * 5.0)
	return anchor + Vector2(sin(elapsed * speed + phase) * radius.x, cos(elapsed * speed * 0.73 + phase) * radius.y)

static func atmospheric_point(index: int, elapsed: float, velocity: Vector2, viewport_size: Vector2 = Vector2(960, 540)) -> Vector2:
	var origin := Vector2(float(posmod(index * 137, int(viewport_size.x))), float(posmod(index * 83, int(viewport_size.y))))
	return Vector2(fposmod(origin.x + velocity.x * elapsed, viewport_size.x), fposmod(origin.y + velocity.y * elapsed, viewport_size.y))

static func weather_density(weather: String) -> int:
	return {"temporal":64, "tormenta":58, "lluvia":40, "lluvia suave":26, "viento":24, "ceniza":34, "luceros":30, "aurora":24}.get(weather, 0)

static func hd2d_profile(profile_id: String) -> Dictionary:
	return (HD2D_PROFILES.get(profile_id, {}) as Dictionary).duplicate(true)

static func validate() -> Array[String]:
	var errors: Array[String] = []
	if depth_scale(90.0) >= depth_scale(500.0): errors.append("La profundidad isométrica debe crecer hacia primer plano.")
	for period in PERIOD_SPEED:
		if float(PERIOD_SPEED[period]) <= 0.0: errors.append("Velocidad ambiental inválida para %s." % period)
	for profile_id in HD2D_PROFILES:
		var profile: Dictionary = HD2D_PROFILES[profile_id] as Dictionary
		if int(profile.get("shafts", 0)) <= 0: errors.append("El perfil HD-2D %s necesita haces de luz." % profile_id)
		if int(profile.get("motes", 0)) <= 0: errors.append("El perfil HD-2D %s necesita partículas ambientales." % profile_id)
	return errors
