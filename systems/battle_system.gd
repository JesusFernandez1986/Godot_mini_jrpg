class_name BattleSystem
extends RefCounted

static func physical_damage(attacker: Dictionary, defender: Dictionary, rng: RandomNumberGenerator) -> int:
	var raw: int = rng.randi_range(7, 12) + int(attacker.get("attack", 1)) - int(defender.get("defense", 0)) / 3
	return maxi(1, raw)

static func crystal_damage(attacker: Dictionary, defender: Dictionary, rng: RandomNumberGenerator) -> int:
	var raw: int = rng.randi_range(17, 24) + int(attacker.get("magic", 1)) * 2 - int(defender.get("defense", 0)) / 4
	return maxi(1, raw)

static func enemy_damage(enemy: Dictionary, defender: Dictionary, rng: RandomNumberGenerator) -> int:
	var raw: int = rng.randi_range(3, 7) + int(enemy.get("attack", 1)) - int(defender.get("defense", 0)) / 3
	return maxi(1, raw)

static func heal_amount(caster: Dictionary) -> int:
	return maxi(1, 15 + int(caster.get("magic", 0)))

static func validate_combatant(combatant: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in ["hp", "max_hp", "attack", "defense"]:
		if not combatant.has(field):
			errors.append("Combatiente sin campo %s." % field)
	return errors
