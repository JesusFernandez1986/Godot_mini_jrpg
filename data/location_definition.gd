class_name LocationDefinition
extends Resource

@export var id := ""
@export var display_name := ""
@export_enum("city", "dungeon") var location_type := "city"
@export var map_position := Vector2.ZERO
@export var required_chapter := 0

func to_runtime() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"type": location_type,
		"position": map_position,
		"required_chapter": required_chapter
	}
