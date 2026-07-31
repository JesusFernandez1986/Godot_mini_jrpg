class_name DialogueSystem
extends RefCounted

var lines: Array = []
var index := 0
var return_state := "world_map"
var completion := ""
var backdrop := "world"
var visible_characters := 0.0

func begin(new_lines: Array, next_state: String, completion_id: String, background_id: String) -> void:
	lines = new_lines.duplicate(true)
	index = 0
	return_state = next_state
	completion = completion_id
	backdrop = background_id
	visible_characters = 0.0

func update(delta: float, characters_per_second: float) -> void:
	if is_complete() or lines.is_empty():
		return
	visible_characters += delta * maxf(1.0, characters_per_second)

func current_pair() -> Array:
	if lines.is_empty():
		return ["", ""]
	return lines[clampi(index, 0, lines.size() - 1)] as Array

func current_text() -> String:
	return str(current_pair()[1])

func is_line_revealed() -> bool:
	return visible_characters >= current_text().length()

func reveal_line() -> void:
	visible_characters = float(current_text().length())

func advance() -> bool:
	if not is_line_revealed():
		reveal_line()
		return false
	index += 1
	visible_characters = 0.0
	return is_complete()

func is_complete() -> bool:
	return index >= lines.size()

func visible_text() -> String:
	var text := current_text()
	return text.substr(0, mini(text.length(), int(visible_characters)))

static func city_chunk(all_lines: Array, start: int, size: int = 4) -> Dictionary:
	var chunk: Array = []
	if all_lines.is_empty():
		return {"lines": chunk, "next": 0}
	for offset in size:
		chunk.append(all_lines[(start + offset) % all_lines.size()])
	return {"lines": chunk, "next": (start + size) % all_lines.size()}
