class_name EnemyDefinition
extends Resource

@export var id := ""
@export var display_name := ""
@export var base_hp := 20
@export var attack := 8
@export var defense := 4
@export var intent := "Ataque"
@export var xp_reward := 10
@export var gold_reward := 10
@export var sprite_index := 1
@export_enum("guardian", "normal", "miniboss", "boss") var rank := "guardian"
@export var phase3_atlas := false
@export var speed := 8
@export var weaknesses: Array[String] = ["sword"]
@export var resistances: Array[String] = []
@export var break_shield := 2
@export var ai_phase_1: Array[String] = ["attack"]
@export var ai_phase_2: Array[String] = ["attack", "poison"]
@export var ai_phase_3: Array[String] = ["attack", "fear", "attack"]
@export var loot_item := ""
@export_range(0.0, 1.0) var loot_chance := 0.0
@export var loot_amount := 1

func create_runtime() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"hp": base_hp,
		"max_hp": base_hp,
		"attack": attack,
		"defense": defense,
		"intent": intent,
		"xp_reward": xp_reward,
		"gold_reward": gold_reward,
		"sprite_index": sprite_index,
		"rank": rank,
		"phase3_atlas": phase3_atlas,
		"speed": speed,
		"weaknesses": weaknesses.duplicate(),
		"resistances": resistances.duplicate(),
		"break_shield": break_shield,
		"ai_phase_1": ai_phase_1.duplicate(),
		"ai_phase_2": ai_phase_2.duplicate(),
		"ai_phase_3": ai_phase_3.duplicate(),
		"loot_item": loot_item,
		"loot_chance": loot_chance,
		"loot_amount": loot_amount
	}
