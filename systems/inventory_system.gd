class_name InventorySystem
extends RefCounted

static func add_item(inventory: Dictionary, item_name: String, definition: ItemDefinition, amount: int) -> Dictionary:
	if amount <= 0:
		return {"success": false, "message": "La cantidad debe ser positiva."}
	if inventory.has(item_name):
		var stack: Dictionary = inventory[item_name] as Dictionary
		stack["quantity"] = int(stack.get("quantity", 0)) + amount
	else:
		inventory[item_name] = definition.create_stack(amount)
	return {"success": true, "message": "Se añade %s ×%d." % [item_name, amount]}

static func use_item(inventory: Dictionary, item_name: String, target: Dictionary) -> Dictionary:
	if not inventory.has(item_name):
		return {"success": false, "message": "El objeto no está en el inventario."}
	var stack: Dictionary = inventory[item_name] as Dictionary
	if int(stack.get("quantity", 0)) <= 0:
		return {"success": false, "message": "No queda ninguna unidad."}
	var restores: String = str(stack.get("restores", "none"))
	var power: int = int(stack.get("power", 0))
	if restores == "hp":
		if int(target["hp"]) >= int(target["max_hp"]):
			return {"success": false, "message": "La vitalidad ya está al máximo."}
		target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + power)
	elif restores == "mp":
		if int(target["mp"]) >= int(target["max_mp"]):
			return {"success": false, "message": "Los PM ya están al máximo."}
		target["mp"] = mini(int(target["max_mp"]), int(target["mp"]) + power)
	else:
		return {"success": false, "message": "Este objeto no puede usarse desde el menú."}
	stack["quantity"] = int(stack["quantity"]) - 1
	return {"success": true, "message": "%s utiliza %s." % [str(target["name"]), item_name]}

static func validate(inventory: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for item_name in inventory:
		if not inventory[item_name] is Dictionary:
			errors.append("%s no contiene una pila válida." % item_name)
			continue
		var stack: Dictionary = inventory[item_name] as Dictionary
		if int(stack.get("quantity", -1)) < 0:
			errors.append("%s tiene cantidad negativa." % item_name)
	return errors
