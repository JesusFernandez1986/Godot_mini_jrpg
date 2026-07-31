class_name TravelSystem
extends RefCounted

static func unlock(unlocked: Array, location_id: String) -> bool:
	if location_id in unlocked:
		return false
	unlocked.append(location_id)
	return true

static func can_travel(unlocked: Array, location_id: String) -> bool:
	return location_id in unlocked

static func location_by_id(locations: Array, location_id: String) -> Dictionary:
	for location in locations:
		if str(location.get("id", "")) == location_id:
			return location as Dictionary
	return {}

static func validate_route(locations: Array, unlocked: Array) -> Array[String]:
	var errors: Array[String] = []
	var ids: Array[String] = []
	for location in locations:
		var location_id := str(location.get("id", ""))
		if location_id.is_empty():
			errors.append("Existe una localización sin identificador.")
		elif location_id in ids:
			errors.append("Localización duplicada: %s" % location_id)
		else:
			ids.append(location_id)
	for unlocked_id in unlocked:
		if str(unlocked_id) not in ids:
			errors.append("Destino desbloqueado desconocido: %s" % unlocked_id)
	return errors
