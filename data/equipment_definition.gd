class_name EquipmentDefinition
extends Resource

enum Slot { WEAPON, ARMOR, ACCESSORY }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var slot := Slot.WEAPON
@export var rarity := Rarity.COMMON
@export var weapon_type := ""
@export var element := ""
@export var allowed_character_ids: Array[String] = []
@export var stat_bonuses: Dictionary = {}
@export var passive_id := ""
@export var recipe: Dictionary = {}
@export var craft_gold := 0
@export var max_upgrade := 3

func slot_id() -> String:
	return ["weapon", "armor", "accessory"][slot]

func rarity_name() -> String:
	return ["Común", "Poco común", "Raro", "Épico", "Legendario"][rarity]

func can_equip(character_id: String) -> bool:
	return allowed_character_ids.is_empty() or character_id in allowed_character_ids

func bonuses_at_upgrade(upgrade: int) -> Dictionary:
	var result: Dictionary = {}
	var multiplier := 1.0 + 0.25 * clampi(upgrade, 0, max_upgrade)
	for stat in stat_bonuses:
		result[stat] = int(round(float(stat_bonuses[stat]) * multiplier))
	return result
