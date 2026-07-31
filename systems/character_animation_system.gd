class_name CharacterAnimationSystem
extends RefCounted

const DIRECTIONS := ["south", "southwest", "west", "northwest", "north", "northeast", "east", "southeast"]
const STATES := [
	"idle", "walk", "run", "talk", "attack", "defend", "hurt", "fall",
	"open_chest", "mechanism", "use_item", "heal", "special", "rest",
	"celebrate", "travel"
]
const CHARACTER_COLUMNS := [3, 2, 2, 2]
const CHARACTER_BLOCK_WIDTH := 384.0
const ROW_HEIGHT := 128.0
const FRAME_DURATIONS := {
	"idle": 0.55,
	"walk": 0.16,
	"run": 0.09,
	"talk": 0.24,
	"attack": 0.11,
	"defend": 0.18,
	"hurt": 0.10,
	"fall": 0.20,
	"open_chest": 0.16,
	"mechanism": 0.14,
	"use_item": 0.14,
	"heal": 0.16,
	"special": 0.10,
	"rest": 0.62,
	"celebrate": 0.13,
	"travel": 0.10
}

static func validate_state(state: String) -> bool:
	return state in STATES

static func direction_from_vector(vector: Vector2, fallback: String = "south") -> String:
	if vector.length_squared() < 0.0001:
		return fallback if fallback in DIRECTIONS else "south"
	var angle := rad_to_deg(atan2(vector.y, vector.x))
	if angle >= -22.5 and angle < 22.5:
		return "east"
	if angle >= 22.5 and angle < 67.5:
		return "southeast"
	if angle >= 67.5 and angle < 112.5:
		return "south"
	if angle >= 112.5 and angle < 157.5:
		return "southwest"
	if angle >= 157.5 or angle < -157.5:
		return "west"
	if angle >= -157.5 and angle < -112.5:
		return "northwest"
	if angle >= -112.5 and angle < -67.5:
		return "north"
	return "northeast"

static func direction_index(direction: String) -> int:
	var index := DIRECTIONS.find(direction)
	return index if index >= 0 else 0

static func frame_count(character_index: int) -> int:
	return CHARACTER_COLUMNS[clampi(character_index, 0, CHARACTER_COLUMNS.size() - 1)]

static func frame_sequence(state: String, available_frames: int) -> Array:
	var last := maxi(0, available_frames - 1)
	var middle := mini(1, last)
	match state:
		"idle":
			return [middle]
		"walk", "travel":
			return [0, middle, last, middle] if available_frames >= 3 else [0, last]
		"run":
			return [0, last, middle, last] if available_frames >= 3 else [0, last]
		"talk", "rest", "defend":
			return [middle, 0]
		"attack", "special":
			return [0, middle, last, middle]
		"hurt", "fall":
			return [last, 0]
		"open_chest", "mechanism", "use_item", "heal":
			return [0, middle, last]
		"celebrate":
			return [middle, last, 0, last]
	return [middle]

static func sequence_index(state: String, elapsed: float, available_frames: int) -> int:
	var safe_state := state if validate_state(state) else "idle"
	var sequence := frame_sequence(safe_state, available_frames)
	var duration := float(FRAME_DURATIONS.get(safe_state, 0.16))
	return int(floor(maxf(0.0, elapsed) / duration)) % sequence.size()

static func frame_index(state: String, elapsed: float, character_index: int) -> int:
	var count := frame_count(character_index)
	var sequence := frame_sequence(state if validate_state(state) else "idle", count)
	return sequence[sequence_index(state, elapsed, count)]

static func atlas_region(character_index: int, direction: String, state: String, elapsed: float) -> Rect2:
	var safe_character := clampi(character_index, 0, CHARACTER_COLUMNS.size() - 1)
	var columns := frame_count(safe_character)
	var cell_width := CHARACTER_BLOCK_WIDTH / float(columns)
	var column := frame_index(state, elapsed, safe_character)
	return Rect2(
		CHARACTER_BLOCK_WIDTH * safe_character + cell_width * column,
		ROW_HEIGHT * direction_index(direction),
		cell_width,
		ROW_HEIGHT
	)

static func keyframe_offset(state: String, elapsed: float, character_index: int, direction: String) -> Vector2:
	var sequence_position := sequence_index(state, elapsed, frame_count(character_index))
	var forward := direction_vector(direction)
	match state:
		"attack":
			return forward * [0.0, 18.0, 42.0, 16.0][sequence_position]
		"special":
			return forward * [0.0, 12.0, 26.0, 8.0][sequence_position] + Vector2(0, [0.0, -8.0, -18.0, -6.0][sequence_position])
		"hurt":
			return -forward * [8.0, 18.0][sequence_position]
		"fall":
			return Vector2(0, [4.0, 13.0][sequence_position])
		"open_chest", "mechanism", "use_item", "heal":
			return Vector2(0, [0.0, -7.0, 0.0][sequence_position])
		"celebrate":
			return Vector2(0, [0.0, -12.0, -22.0, -8.0][sequence_position])
	return Vector2.ZERO

static func direction_vector(direction: String) -> Vector2:
	match direction:
		"south": return Vector2.DOWN
		"southwest": return Vector2(-1, 1).normalized()
		"west": return Vector2.LEFT
		"northwest": return Vector2(-1, -1).normalized()
		"north": return Vector2.UP
		"northeast": return Vector2(1, -1).normalized()
		"east": return Vector2.RIGHT
		"southeast": return Vector2(1, 1).normalized()
	return Vector2.DOWN
