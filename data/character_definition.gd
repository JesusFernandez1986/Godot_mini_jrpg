class_name CharacterDefinition
extends Resource

@export var id := ""
@export var display_name := ""
@export var role := ""
@export var base_level := 1
@export var base_hp := 30
@export var base_mp := 8
@export var attack := 8
@export var defense := 8
@export var magic := 8
@export var speed := 8
@export var sprite_index := 0
@export var element := "fire"
@export var weapon := "sword"
@export var exploration_ability := "push"
@export var weaknesses: Array[String] = []
@export var resistances: Array[String] = []

func create_runtime(joined: bool = false) -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"role": role,
		"joined": joined,
		"active": joined,
		"level": base_level,
		"hp": base_hp,
		"max_hp": base_hp,
		"base_max_hp": base_hp,
		"mp": base_mp,
		"max_mp": base_mp,
		"base_max_mp": base_mp,
		"attack": attack,
		"base_attack": attack,
		"defense": defense,
		"base_defense": defense,
		"magic": magic,
		"base_magic": magic,
		"speed": speed,
		"base_speed": speed,
		"sprite_index": sprite_index,
		"element": element,
		"weapon": weapon,
		"exploration_ability": exploration_ability,
		"weaknesses": weaknesses.duplicate(),
		"resistances": resistances.duplicate(),
		"xp": 0,
		"selected_skill": ""
	}
