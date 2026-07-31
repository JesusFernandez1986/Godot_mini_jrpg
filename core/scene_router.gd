class_name SceneRouter
extends RefCounted

const VALID_STATES := [
	"title", "settings", "save_menu", "load_menu", "dialogue", "world_map",
	"city", "valdoria_explore", "dungeon", "explore", "battle", "game_menu", "victory"
]

var current_state := "title"
var previous_state := "title"
var transition_alpha := 0.0
var transition_duration := 0.22
var transition_elapsed := 0.0
var is_transitioning := false

func change_state(next_state: String, duration: float = 0.22) -> bool:
	if next_state not in VALID_STATES:
		GameLogger.error("scene", "Rejected unknown game state", {"state": next_state})
		return false
	if next_state == current_state:
		return true
	previous_state = current_state
	current_state = next_state
	transition_duration = maxf(0.01, duration)
	transition_elapsed = 0.0
	transition_alpha = 1.0
	is_transitioning = true
	GameLogger.info("scene", "State changed", {"from": previous_state, "to": current_state})
	return true

func update(delta: float) -> void:
	if not is_transitioning:
		return
	transition_elapsed += delta
	transition_alpha = 1.0 - clampf(transition_elapsed / transition_duration, 0.0, 1.0)
	if transition_elapsed >= transition_duration:
		transition_alpha = 0.0
		is_transitioning = false

func reset(initial_state: String = "title") -> void:
	current_state = initial_state if initial_state in VALID_STATES else "title"
	previous_state = current_state
	transition_alpha = 0.0
	transition_elapsed = 0.0
	is_transitioning = false
