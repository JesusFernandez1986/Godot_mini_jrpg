class_name GameLogger
extends RefCounted

enum Level { DEBUG, INFO, WARNING, ERROR }

const MAX_ENTRIES := 250
static var minimum_level := Level.INFO
static var entries: Array[Dictionary] = []

static func debug(category: String, message: String, context: Dictionary = {}) -> void:
	write(Level.DEBUG, category, message, context)

static func info(category: String, message: String, context: Dictionary = {}) -> void:
	write(Level.INFO, category, message, context)

static func warning(category: String, message: String, context: Dictionary = {}) -> void:
	write(Level.WARNING, category, message, context)

static func error(category: String, message: String, context: Dictionary = {}) -> void:
	write(Level.ERROR, category, message, context)

static func write(level: Level, category: String, message: String, context: Dictionary = {}) -> void:
	if level < minimum_level:
		return
	var entry := {
		"timestamp": Time.get_datetime_string_from_system(),
		"level": Level.keys()[level],
		"category": category,
		"message": message,
		"context": context.duplicate(true)
	}
	entries.append(entry)
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()
	var rendered := "[%s][%s] %s" % [entry["level"], category, message]
	if not context.is_empty():
		rendered += " " + JSON.stringify(context)
	if level == Level.ERROR:
		push_error(rendered)
	elif level == Level.WARNING:
		push_warning(rendered)
	else:
		print(rendered)

static func recent(limit: int = 20) -> Array[Dictionary]:
	var start: int = maxi(0, entries.size() - maxi(0, limit))
	var result: Array[Dictionary] = []
	for i in range(start, entries.size()):
		result.append(entries[i].duplicate(true))
	return result

static func clear() -> void:
	entries.clear()
