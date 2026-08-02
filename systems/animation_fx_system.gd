class_name AnimationFXSystem
extends RefCounted

const PROFILE_PHASES := [0.0, 0.8, 1.6, 2.4, 0.35, 1.15, 1.95, 2.75]
const PROFILE_BOUNCE := [1.0, 0.82, 0.62, 1.12, 1.18, 0.72, 0.9, 0.58]
const ONE_SHOT_STATES := ["attack", "special", "hurt", "fall", "open_chest", "mechanism", "use_item", "heal", "celebrate"]

static func state_duration(state: String) -> float:
	return float(CharacterAnimationSystem.ONE_SHOT_DURATIONS.get(state, 0.65))

static func progress(state: String, elapsed: float) -> float:
	return clampf(elapsed / maxf(0.01, state_duration(state)), 0.0, 1.0)

static func pose_scale(state: String, elapsed: float, character_index: int) -> Vector2:
	var profile := posmod(character_index, PROFILE_PHASES.size())
	var phase := float(PROFILE_PHASES[profile])
	var bounce := float(PROFILE_BOUNCE[profile])
	if state in ["walk", "travel"]:
		var step := sin(elapsed * 11.0 + phase)
		return Vector2(1.0 - absf(step) * 0.025 * bounce, 1.0 + absf(step) * 0.045 * bounce)
	if state == "run":
		var stride := sin(elapsed * 17.0 + phase)
		return Vector2(1.0 + absf(stride) * 0.045, 1.0 - absf(stride) * 0.035)
	if state in ["attack", "special"]:
		var anticipation := sin(progress(state, elapsed) * PI)
		return Vector2(1.0 + anticipation * 0.09, 1.0 - anticipation * 0.055)
	if state == "hurt":
		return Vector2(1.0 + sin(progress(state, elapsed) * PI) * 0.08, 1.0 - sin(progress(state, elapsed) * PI) * 0.07)
	if state == "fall":
		return Vector2(1.0 + progress(state, elapsed) * 0.16, 1.0 - progress(state, elapsed) * 0.22)
	if state in ["heal", "celebrate"]:
		var lift := sin(progress(state, elapsed) * PI)
		return Vector2.ONE * (1.0 + lift * 0.07)
	return Vector2.ONE

static func pose_rotation(state: String, elapsed: float, character_index: int, direction: String) -> float:
	var side := -1.0 if direction in ["west", "northwest", "southwest"] else 1.0
	var phase := float(PROFILE_PHASES[posmod(character_index, PROFILE_PHASES.size())])
	if state in ["walk", "travel"]:
		return sin(elapsed * 11.0 + phase) * 0.018 * side
	if state == "run":
		return sin(elapsed * 17.0 + phase) * 0.028 * side
	if state in ["attack", "special"]:
		return sin(progress(state, elapsed) * PI) * 0.075 * side
	if state == "hurt":
		return sin(progress(state, elapsed) * PI) * -0.09 * side
	if state == "fall":
		return progress(state, elapsed) * 0.16 * side
	return 0.0

static func interaction_spark_positions(origin: Vector2, state: String, elapsed: float, character_index: int) -> Array[Vector2]:
	if state not in ["special", "heal", "open_chest", "mechanism", "use_item", "celebrate"]:
		return []
	var result: Array[Vector2] = []
	var amount := 8 if state in ["special", "heal"] else 5
	var expansion := 18.0 + progress(state, elapsed) * 30.0
	for index in amount:
		var angle := TAU * float(index) / float(amount) + elapsed * (1.8 if index % 2 == 0 else -1.2) + character_index * 0.31
		result.append(origin + Vector2(cos(angle), sin(angle) * 0.65) * expansion - Vector2(0, 45))
	return result

static func validate() -> Array[String]:
	var errors: Array[String] = []
	if PROFILE_PHASES.size() != 8 or PROFILE_BOUNCE.size() != 8:
		errors.append("Cada protagonista necesita un perfil de movimiento propio.")
	for state in ONE_SHOT_STATES:
		if state_duration(state) <= 0.0:
			errors.append("Duración inválida para %s." % state)
	return errors
