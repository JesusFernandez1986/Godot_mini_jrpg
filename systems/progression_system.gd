class_name ProgressionSystem
extends RefCounted

static func required_xp(level: int) -> int:
	return maxi(20, level * 20)

static func grant_xp(member: Dictionary, amount: int) -> int:
	ensure_base_stats(member)
	member["xp"] = int(member.get("xp", 0)) + maxi(0, amount)
	var levels_gained := 0
	while int(member["xp"]) >= required_xp(int(member["level"])):
		member["xp"] = int(member["xp"]) - required_xp(int(member["level"]))
		member["level"] = int(member["level"]) + 1
		member["base_max_hp"] = int(member["base_max_hp"]) + 7
		member["base_max_mp"] = int(member["base_max_mp"]) + 2
		member["base_attack"] = int(member["base_attack"]) + 3
		member["base_defense"] = int(member["base_defense"]) + 2
		member["base_magic"] = int(member["base_magic"]) + 2
		member["base_speed"] = int(member["base_speed"]) + 1
		member["max_hp"] = int(member["max_hp"]) + 7
		member["max_mp"] = int(member["max_mp"]) + 2
		member["attack"] = int(member["attack"]) + 3
		member["defense"] = int(member["defense"]) + 2
		member["magic"] = int(member["magic"]) + 2
		member["speed"] = int(member["speed"]) + 1
		levels_gained += 1
	member["hp"] = mini(int(member["hp"]), int(member["max_hp"]))
	member["mp"] = mini(int(member["mp"]), int(member["max_mp"]))
	return levels_gained

static func ensure_base_stats(member: Dictionary) -> void:
	for stat in ["max_hp", "max_mp", "attack", "defense", "magic", "speed"]:
		var base_key := "base_%s" % stat
		if not member.has(base_key): member[base_key] = int(member.get(stat, 1))

static func restore_party(party: Array) -> void:
	for member in party:
		if member is Dictionary and bool(member.get("joined", false)):
			member["hp"] = member["max_hp"]
			member["mp"] = member["max_mp"]

static func joined_party(party: Array) -> Array:
	var result: Array = []
	for member in party:
		if member is Dictionary and bool(member.get("joined", false)):
			result.append(member)
	return result

static func validate_party(party: Array) -> Array[String]:
	var errors: Array[String] = []
	for member in party:
		if not member is Dictionary:
			errors.append("Entrada de grupo inválida.")
			continue
		for stat in ["level", "hp", "max_hp", "mp", "max_mp", "attack", "defense", "magic", "speed"]:
			if not member.has(stat):
				errors.append("%s no contiene %s." % [member.get("name", "Personaje"), stat])
		if int(member.get("hp", 0)) > int(member.get("max_hp", 0)):
			errors.append("%s tiene PV por encima del máximo." % member.get("name", "Personaje"))
	return errors
