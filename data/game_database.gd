class_name GameDatabase
extends RefCounted

const CHARACTERS: Array[CharacterDefinition] = [
	preload("res://data/resources/characters/aren.tres"),
	preload("res://data/resources/characters/lyra.tres"),
	preload("res://data/resources/characters/brom.tres"),
	preload("res://data/resources/characters/seris.tres")
]
const ITEMS: Array[ItemDefinition] = [
	preload("res://data/resources/items/potion.tres"),
	preload("res://data/resources/items/ether.tres"),
	preload("res://data/resources/items/travel_bread.tres"),
	preload("res://data/resources/items/eira_crystal.tres")
]
const ENEMIES: Array[EnemyDefinition] = [
	preload("res://data/resources/enemies/lunar_wolf.tres"),
	preload("res://data/resources/enemies/shadow_ent.tres"),
	preload("res://data/resources/enemies/moss_dragon.tres"),
	preload("res://data/resources/enemies/crypt_rat.tres"),
	preload("res://data/resources/enemies/hollow_sentinel.tres"),
	preload("res://data/resources/enemies/amber_wisp.tres"),
	preload("res://data/resources/enemies/ossuary_spider.tres"),
	preload("res://data/resources/enemies/veil_cultist.tres"),
	preload("res://data/resources/enemies/stone_gargoyle.tres"),
	preload("res://data/resources/enemies/oathbreaker_knight.tres"),
	preload("res://data/resources/enemies/hollow_lion.tres")
]
const LOCATIONS: Array[LocationDefinition] = [
	preload("res://data/resources/locations/valdoria.tres"),
	preload("res://data/resources/locations/brumaforja.tres"),
	preload("res://data/resources/locations/celestia.tres"),
	preload("res://data/resources/locations/sylvaran.tres"),
	preload("res://data/resources/locations/sanctuary.tres")
]
const QUESTS: Array[QuestDefinition] = [
	preload("res://data/resources/quests/prologue.tres"),
	preload("res://data/resources/quests/valdoria.tres"),
	preload("res://data/resources/quests/brumaforja.tres"),
	preload("res://data/resources/quests/celestia.tres"),
	preload("res://data/resources/quests/sylvaran.tres"),
	preload("res://data/resources/quests/sanctuary.tres"),
	preload("res://data/resources/quests/epilogue.tres")
]

static func create_party() -> Array:
	var result: Array = []
	for i in CHARACTERS.size():
		result.append(CHARACTERS[i].create_runtime(i == 0))
	return result

static func create_initial_inventory() -> Dictionary:
	return {
		ITEMS[0].display_name: ITEMS[0].create_stack(3),
		ITEMS[1].display_name: ITEMS[1].create_stack(1),
		ITEMS[2].display_name: ITEMS[2].create_stack(4),
		ITEMS[3].display_name: ITEMS[3].create_stack(1)
	}

static func item_by_name(item_name: String) -> ItemDefinition:
	for definition in ITEMS:
		if definition.display_name == item_name:
			return definition
	return null

static func item_or_fallback(item_name: String, description: String) -> ItemDefinition:
	var definition := item_by_name(item_name)
	if definition != null:
		return definition
	var fallback := ItemDefinition.new()
	fallback.id = item_name.to_snake_case()
	fallback.display_name = item_name
	fallback.description = description
	fallback.kind = ItemDefinition.ItemKind.KEY_ITEM
	return fallback

static func enemy(index: int) -> Dictionary:
	return ENEMIES[clampi(index, 0, ENEMIES.size() - 1)].create_runtime()

static func enemy_by_id(enemy_id: String) -> Dictionary:
	for definition in ENEMIES:
		if definition.id == enemy_id:
			return definition.create_runtime()
	return {}

static func locations() -> Array:
	var result: Array = []
	for definition in LOCATIONS:
		result.append(definition.to_runtime())
	return result

static func quest(chapter: int) -> QuestDefinition:
	return QUESTS[clampi(chapter, 0, QUESTS.size() - 1)]

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var ids: Array[String] = []
	for definition in CHARACTERS + ITEMS + ENEMIES + LOCATIONS + QUESTS:
		if definition.id.is_empty():
			errors.append("Recurso sin identificador: %s" % definition.resource_path)
		elif definition.id in ids:
			errors.append("Identificador duplicado: %s" % definition.id)
		else:
			ids.append(definition.id)
	return errors
