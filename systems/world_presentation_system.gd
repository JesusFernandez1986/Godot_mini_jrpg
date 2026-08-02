class_name WorldPresentationSystem
extends RefCounted

const PERIOD_SPEED := {"amanecer":0.72, "día":1.0, "atardecer":0.86, "noche":0.55}

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

static func validate() -> Array[String]:
	var errors: Array[String] = []
	if depth_scale(90.0) >= depth_scale(500.0): errors.append("La profundidad isométrica debe crecer hacia primer plano.")
	for period in PERIOD_SPEED:
		if float(PERIOD_SPEED[period]) <= 0.0: errors.append("Velocidad ambiental inválida para %s." % period)
	return errors
