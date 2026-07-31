class_name ItemDefinition
extends Resource

enum ItemKind { CONSUMABLE, KEY_ITEM, MATERIAL }

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var kind := ItemKind.CONSUMABLE
@export var power := 0
@export var price := 0
@export var restores := "none"

func create_stack(quantity: int) -> Dictionary:
	return {
		"id": id,
		"quantity": maxi(0, quantity),
		"description": description,
		"kind": kind,
		"power": power,
		"price": price,
		"restores": restores
	}
