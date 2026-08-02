class_name EquipmentSystem
extends RefCounted

const SLOTS := ["weapon", "armor", "accessory"]
const STAT_KEYS := ["max_hp", "max_mp", "attack", "defense", "magic", "speed"]

static func create_state() -> Dictionary:
	return {
		"owned": {
			"iron_sword": {"quantity": 1, "upgrade": 0},
			"astral_staff": {"quantity": 1, "upgrade": 0},
			"runic_hammer": {"quantity": 1, "upgrade": 0},
			"moonbow": {"quantity": 1, "upgrade": 0},
			"traveler_garb": {"quantity": 4, "upgrade": 0},
			"amber_ring": {"quantity": 1, "upgrade": 0}
		},
		"equipped": {
			"aren": {"weapon": "iron_sword", "armor": "traveler_garb", "accessory": "amber_ring"},
			"lyra": {"weapon": "astral_staff", "armor": "traveler_garb", "accessory": ""},
			"brom": {"weapon": "runic_hammer", "armor": "traveler_garb", "accessory": ""},
			"seris": {"weapon": "moonbow", "armor": "traveler_garb", "accessory": ""}
		},
		"recipes_unlocked": ["lion_mail", "astral_robe", "ward_charm", "swift_feather", "emberbrand"]
	}

static func definition(equipment_id: String) -> EquipmentDefinition:
	return GameDatabase.equipment_by_id(equipment_id)

static func equipped_id(state: Dictionary, character_id: String, slot_id: String) -> String:
	return str((state.get("equipped", {}) as Dictionary).get(character_id, {}).get(slot_id, ""))

static func available_count(state: Dictionary, equipment_id: String, ignoring_character: String = "") -> int:
	var owned: Dictionary = state.get("owned", {})
	var total := int((owned.get(equipment_id, {}) as Dictionary).get("quantity", 0))
	for character_id in state.get("equipped", {}) as Dictionary:
		if str(character_id) == ignoring_character:
			continue
		for slot_id in SLOTS:
			if equipped_id(state, str(character_id), slot_id) == equipment_id:
				total -= 1
	return total

static func equip(state: Dictionary, character_id: String, slot_id: String, equipment_id: String) -> Dictionary:
	if slot_id not in SLOTS:
		return {"success": false, "message": "Ranura inválida."}
	var item := definition(equipment_id)
	if item == null or item.slot_id() != slot_id:
		return {"success": false, "message": "Ese objeto no corresponde a la ranura."}
	if not item.can_equip(character_id):
		return {"success": false, "message": "Este personaje no puede usar el equipo."}
	if available_count(state, equipment_id, character_id) <= 0 and equipped_id(state, character_id, slot_id) != equipment_id:
		return {"success": false, "message": "No queda ninguna copia disponible."}
	var equipped: Dictionary = state["equipped"]
	if not equipped.has(character_id):
		equipped[character_id] = {"weapon": "", "armor": "", "accessory": ""}
	(equipped[character_id] as Dictionary)[slot_id] = equipment_id
	return {"success": true, "message": "%s equipado." % item.display_name}

static func unequip(state: Dictionary, character_id: String, slot_id: String) -> bool:
	var equipped: Dictionary = state.get("equipped", {})
	if not equipped.has(character_id) or slot_id not in SLOTS:
		return false
	(equipped[character_id] as Dictionary)[slot_id] = ""
	return true

static func compatible_available(state: Dictionary, character_id: String, slot_id: String) -> Array[String]:
	var result: Array[String] = []
	for item in GameDatabase.EQUIPMENT:
		if item.slot_id() == slot_id and item.can_equip(character_id) and (available_count(state, item.id, character_id) > 0 or equipped_id(state, character_id, slot_id) == item.id):
			result.append(item.id)
	return result

static func cycle_equipment(state: Dictionary, character_id: String, slot_id: String, direction: int = 1) -> Dictionary:
	var options := compatible_available(state, character_id, slot_id)
	if options.is_empty():
		return {"success": false, "message": "No hay equipo compatible."}
	var current := equipped_id(state, character_id, slot_id)
	var index := options.find(current)
	index = wrapi(index + direction, 0, options.size())
	return equip(state, character_id, slot_id, options[index])

static func equipment_bonuses(state: Dictionary, character_id: String) -> Dictionary:
	var result := zero_bonuses()
	for slot_id in SLOTS:
		var equipment_id := equipped_id(state, character_id, slot_id)
		var item := definition(equipment_id)
		if item == null:
			continue
		var upgrade := int((state.get("owned", {}) as Dictionary).get(equipment_id, {}).get("upgrade", 0))
		for stat in item.bonuses_at_upgrade(upgrade):
			if stat in STAT_KEYS:
				result[stat] = int(result[stat]) + int(item.bonuses_at_upgrade(upgrade)[stat])
	return result

static func preview(state: Dictionary, character: Dictionary, equipment_id: String) -> Dictionary:
	var item := definition(equipment_id)
	if item == null:
		return {}
	var current := equipment_bonuses(state, str(character.get("id", "")))
	var simulated := state.duplicate(true)
	var result := equip(simulated, str(character.get("id", "")), item.slot_id(), equipment_id)
	if not bool(result.get("success", false)):
		return {}
	var proposed := equipment_bonuses(simulated, str(character.get("id", "")))
	var delta := zero_bonuses()
	for stat in STAT_KEYS:
		delta[stat] = int(proposed[stat]) - int(current[stat])
	return {"current": current, "proposed": proposed, "delta": delta}

static func craft(state: Dictionary, inventory: Dictionary, equipment_id: String, gold: int) -> Dictionary:
	var item := definition(equipment_id)
	if item == null or equipment_id not in (state.get("recipes_unlocked", []) as Array):
		return {"success": false, "message": "Receta no disponible.", "gold": gold}
	if gold < item.craft_gold:
		return {"success": false, "message": "Oro insuficiente.", "gold": gold}
	for material_name in item.recipe:
		if int((inventory.get(material_name, {}) as Dictionary).get("quantity", 0)) < int(item.recipe[material_name]):
			return {"success": false, "message": "Falta %s." % material_name, "gold": gold}
	for material_name in item.recipe:
		(inventory[material_name] as Dictionary)["quantity"] = int((inventory[material_name] as Dictionary)["quantity"]) - int(item.recipe[material_name])
		if int((inventory[material_name] as Dictionary)["quantity"]) <= 0:
			inventory.erase(material_name)
	var owned: Dictionary = state["owned"]
	if not owned.has(equipment_id):
		owned[equipment_id] = {"quantity": 0, "upgrade": 0}
	(owned[equipment_id] as Dictionary)["quantity"] = int((owned[equipment_id] as Dictionary)["quantity"]) + 1
	return {"success": true, "message": "%s fabricado." % item.display_name, "gold": gold - item.craft_gold}

static func upgrade(state: Dictionary, inventory: Dictionary, equipment_id: String, gold: int) -> Dictionary:
	var item := definition(equipment_id)
	var owned: Dictionary = state.get("owned", {})
	if item == null or not owned.has(equipment_id):
		return {"success": false, "message": "No posees ese equipo.", "gold": gold}
	var entry: Dictionary = owned[equipment_id]
	var level := int(entry.get("upgrade", 0))
	if level >= item.max_upgrade:
		return {"success": false, "message": "La mejora ya está al máximo.", "gold": gold}
	var cost := 20 * (level + 1) * (item.rarity + 1)
	var material := "Hierro resonante"
	var required := level + 1
	if gold < cost or int((inventory.get(material, {}) as Dictionary).get("quantity", 0)) < required:
		return {"success": false, "message": "Faltan oro o materiales de mejora.", "gold": gold}
	(inventory[material] as Dictionary)["quantity"] = int((inventory[material] as Dictionary)["quantity"]) - required
	if int((inventory[material] as Dictionary)["quantity"]) <= 0:
		inventory.erase(material)
	entry["upgrade"] = level + 1
	return {"success": true, "message": "%s mejora a +%d." % [item.display_name, level + 1], "gold": gold - cost}

static func add_owned(state: Dictionary, equipment_id: String, amount: int = 1) -> bool:
	if definition(equipment_id) == null or amount <= 0:
		return false
	var owned: Dictionary = state["owned"]
	if not owned.has(equipment_id):
		owned[equipment_id] = {"quantity": 0, "upgrade": 0}
	(owned[equipment_id] as Dictionary)["quantity"] = int((owned[equipment_id] as Dictionary)["quantity"]) + amount
	return true

static func refresh_party_stats(party: Array, equipment_state: Dictionary, advancement_state: Dictionary = {}) -> void:
	for member in party:
		if not member is Dictionary:
			continue
		ProgressionSystem.ensure_base_stats(member)
		var character_id := str(member.get("id", ""))
		var bonuses := equipment_bonuses(equipment_state, character_id)
		if not advancement_state.is_empty():
			var advancement_bonuses := AdvancementSystem.stat_bonuses(advancement_state, character_id)
			for stat in STAT_KEYS:
				bonuses[stat] = int(bonuses[stat]) + int(advancement_bonuses.get(stat, 0))
		for stat in STAT_KEYS:
			var base_key := "base_%s" % stat
			var maximum := 9999 if stat == "max_hp" else 999
			member[stat] = clampi(int(member.get(base_key, member.get(stat, 1))) + int(bonuses[stat]), 1, maximum)
		member["hp"] = clampi(int(member.get("hp", member["max_hp"])), 0, int(member["max_hp"]))
		member["mp"] = clampi(int(member.get("mp", member["max_mp"])), 0, int(member["max_mp"]))
		var weapon := definition(equipped_id(equipment_state, character_id, "weapon"))
		if weapon != null:
			if not weapon.weapon_type.is_empty(): member["weapon"] = weapon.weapon_type
			if not weapon.element.is_empty(): member["element"] = weapon.element
		if not advancement_state.is_empty():
			member["selected_skill"] = AdvancementSystem.selected_skill(advancement_state, character_id)
			var passives := AdvancementSystem.active_passives(advancement_state, character_id)
			for slot_id in SLOTS:
				var equipped_item := definition(equipped_id(equipment_state, character_id, slot_id))
				if equipped_item != null and not equipped_item.passive_id.is_empty() and equipped_item.passive_id not in passives:
					passives.append(equipped_item.passive_id)
			member["passives"] = passives

static func zero_bonuses() -> Dictionary:
	return {"max_hp": 0, "max_mp": 0, "attack": 0, "defense": 0, "magic": 0, "speed": 0}

static func validate(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not state.get("owned", {}) is Dictionary or not state.get("equipped", {}) is Dictionary:
		return ["Estado de equipo incompleto."]
	for equipment_id in state["owned"] as Dictionary:
		if definition(str(equipment_id)) == null: errors.append("Equipo desconocido: %s" % equipment_id)
		var entry: Dictionary = (state["owned"] as Dictionary)[equipment_id]
		var item := definition(str(equipment_id))
		if int(entry.get("quantity", 0)) < 0 or int(entry.get("upgrade", 0)) < 0 or (item != null and int(entry.get("upgrade", 0)) > item.max_upgrade): errors.append("Cantidad o mejora inválida: %s" % equipment_id)
	for character_id in state["equipped"] as Dictionary:
		for slot_id in SLOTS:
			var equipment_id := equipped_id(state, str(character_id), slot_id)
			if equipment_id.is_empty(): continue
			var item := definition(equipment_id)
			if item == null or item.slot_id() != slot_id or not item.can_equip(str(character_id)):
				errors.append("Equipo incompatible en %s/%s" % [character_id, slot_id])
	for equipment_id in state["owned"] as Dictionary:
		if available_count(state, str(equipment_id)) < 0: errors.append("Hay más copias equipadas que poseídas: %s" % equipment_id)
	return errors
