class_name NarrativeSystem
extends RefCounted

const DEFAULT_PATH := "res://data/dialogues/phase6_dialogues.json"
var data: Dictionary = {}

func _init(path: String = DEFAULT_PATH) -> void:
	load_database(path)

func load_database(path: String = DEFAULT_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		data = {}
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	data = parsed as Dictionary if parsed is Dictionary else {}
	return not data.is_empty()

func create_state() -> Dictionary:
	var quest_states: Dictionary = {}
	for quest_id in data.get("quests", {}) as Dictionary:
		quest_states[quest_id] = {"status":"available" if str((data["quests"][quest_id] as Dictionary).get("category", "")) == "personal" else "locked"}
	return {
		"variables": (data.get("variables", {}) as Dictionary).duplicate(true),
		"quests": quest_states,
		"codex_unlocked": [],
		"completed_scenes": [],
		"seen_banter": [],
		"choice_history": [],
		"applied_nodes": [],
		"active_scene": "",
		"active_node": ""
	}

func scene(scene_id: String) -> Dictionary:
	return (data.get("scenes", {}) as Dictionary).get(scene_id, {}) as Dictionary

func start_scene(state: Dictionary, scene_id: String) -> Dictionary:
	var definition := scene(scene_id)
	if definition.is_empty(): return {"success":false,"message":"Escena narrativa desconocida."}
	state["active_scene"] = scene_id
	state["active_node"] = str(definition.get("start", ""))
	var starts_quest := str(definition.get("starts_quest", ""))
	if not starts_quest.is_empty(): set_quest_status(state, starts_quest, "active")
	resolve_conditional_node(state)
	return {"success":true,"message":str(definition.get("title", scene_id))}

func current_node(state: Dictionary) -> Dictionary:
	var definition := scene(str(state.get("active_scene", "")))
	return (definition.get("nodes", {}) as Dictionary).get(str(state.get("active_node", "")), {}) as Dictionary

func current_choices(state: Dictionary) -> Array:
	var result: Array = []
	for choice in current_node(state).get("choices", []) as Array:
		if conditions_met(state, choice.get("conditions", []) as Array): result.append(choice)
	return result

func advance(state: Dictionary, choice_index: int = -1) -> Dictionary:
	var node := current_node(state)
	if node.is_empty(): return finish_scene(state)
	if not state.has("applied_nodes"): state["applied_nodes"] = []
	var node_key := "%s/%s" % [state.get("active_scene", ""), state.get("active_node", "")]
	if node_key not in (state["applied_nodes"] as Array):
		apply_effects(state, node.get("effects", []) as Array)
		for codex_id in node.get("codex", []) as Array: unlock_codex(state, str(codex_id))
		(state["applied_nodes"] as Array).append(node_key)
	var next_id := str(node.get("next", ""))
	var choices := current_choices(state)
	if not choices.is_empty():
		if choice_index < 0 or choice_index >= choices.size(): return {"complete":false,"changed":false,"message":"Elige una respuesta."}
		var choice: Dictionary = choices[choice_index]
		apply_effects(state, choice.get("effects", []) as Array)
		next_id = str(choice.get("next", ""))
		(state["choice_history"] as Array).append({"scene":state["active_scene"],"node":state["active_node"],"choice":choice_index,"text":choice.get("text", "")})
	state["active_node"] = next_id
	if next_id.is_empty(): return finish_scene(state)
	resolve_conditional_node(state)
	if str(state.get("active_node", "")).is_empty(): return finish_scene(state)
	return {"complete":false,"changed":true,"node":current_node(state)}

func resolve_conditional_node(state: Dictionary) -> void:
	var visited: Array[String] = []
	while not str(state.get("active_node", "")).is_empty():
		var node_id := str(state["active_node"])
		if node_id in visited: return
		visited.append(node_id)
		var node := current_node(state)
		if node.is_empty():
			state["active_node"] = ""
			return
		if conditions_met(state, node.get("conditions", []) as Array): return
		state["active_node"] = str(node.get("else_next", ""))

func finish_scene(state: Dictionary) -> Dictionary:
	var scene_id := str(state.get("active_scene", ""))
	var definition := scene(scene_id)
	if not scene_id.is_empty() and scene_id not in (state["completed_scenes"] as Array): (state["completed_scenes"] as Array).append(scene_id)
	if str(definition.get("kind", "")).ends_with("banter") and scene_id not in (state["seen_banter"] as Array): (state["seen_banter"] as Array).append(scene_id)
	var completes_quest := str(definition.get("completes_quest", ""))
	if not completes_quest.is_empty(): set_quest_status(state, completes_quest, "completed")
	state["active_scene"] = ""
	state["active_node"] = ""
	return {"complete":true,"changed":true,"scene":scene_id}

func apply_effects(state: Dictionary, effects: Array) -> void:
	for raw_effect in effects:
		var effect: Dictionary = raw_effect
		match str(effect.get("op", "")):
			"set": (state["variables"] as Dictionary)[str(effect.get("key", ""))] = effect.get("value")
			"inc":
				var key := str(effect.get("key", ""))
				(state["variables"] as Dictionary)[key] = int((state["variables"] as Dictionary).get(key, 0)) + int(effect.get("value", 1))
			"codex": unlock_codex(state, str(effect.get("id", "")))
			"quest_start": set_quest_status(state, str(effect.get("id", "")), "active")
			"quest_complete": set_quest_status(state, str(effect.get("id", "")), "completed")

func conditions_met(state: Dictionary, conditions: Array) -> bool:
	for raw_condition in conditions:
		var condition: Dictionary = raw_condition
		if (state.get("variables", {}) as Dictionary).get(str(condition.get("key", ""))) != condition.get("equals"):
			return false
	return true

func unlock_codex(state: Dictionary, codex_id: String) -> bool:
	if not (data.get("codex", {}) as Dictionary).has(codex_id): return false
	if codex_id not in (state["codex_unlocked"] as Array): (state["codex_unlocked"] as Array).append(codex_id)
	return true

func set_quest_status(state: Dictionary, quest_id: String, status: String) -> bool:
	if not (data.get("quests", {}) as Dictionary).has(quest_id) or status not in ["locked", "available", "active", "completed"]: return false
	var quests: Dictionary = state["quests"]
	if not quests.has(quest_id): quests[quest_id] = {}
	(quests[quest_id] as Dictionary)["status"] = status
	return true

func quest_entries(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in data.get("quests", {}) as Dictionary:
		var entry: Dictionary = (data["quests"][quest_id] as Dictionary).duplicate(true)
		entry["id"] = quest_id
		entry["status"] = str((state.get("quests", {}) as Dictionary).get(quest_id, {}).get("status", "locked"))
		result.append(entry)
	return result

func codex_entries(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for codex_id in state.get("codex_unlocked", []) as Array:
		if (data.get("codex", {}) as Dictionary).has(codex_id):
			var entry: Dictionary = (data["codex"][codex_id] as Dictionary).duplicate(true)
			entry["id"] = codex_id
			result.append(entry)
	return result

func next_banter(state: Dictionary, kind: String) -> String:
	for scene_id in data.get("scenes", {}) as Dictionary:
		var definition: Dictionary = data["scenes"][scene_id]
		if str(definition.get("kind", "")) == kind and scene_id not in (state.get("seen_banter", []) as Array): return str(scene_id)
	return ""

func dialogue_line(state: Dictionary) -> Dictionary:
	return current_node(state).duplicate(true)

func validate_data() -> Array[String]:
	var errors: Array[String] = []
	for scene_id in data.get("scenes", {}) as Dictionary:
		var definition: Dictionary = data["scenes"][scene_id]
		var nodes: Dictionary = definition.get("nodes", {})
		var start := str(definition.get("start", ""))
		if start.is_empty() or not nodes.has(start): errors.append("Escena %s sin inicio válido." % scene_id)
		for node_id in nodes:
			var node: Dictionary = nodes[node_id]
			if str(node.get("speaker", "")).is_empty() or str(node.get("text", "")).is_empty(): errors.append("Nodo %s/%s incompleto." % [scene_id, node_id])
			var next_id := str(node.get("next", ""))
			if not next_id.is_empty() and not nodes.has(next_id): errors.append("Destino inexistente %s/%s -> %s" % [scene_id, node_id, next_id])
			for choice in node.get("choices", []) as Array:
				if not nodes.has(str(choice.get("next", ""))): errors.append("Elección sin destino en %s/%s" % [scene_id, node_id])
	return errors

func reachable_nodes(scene_id: String) -> Array[String]:
	var definition := scene(scene_id)
	var nodes: Dictionary = definition.get("nodes", {})
	var pending: Array[String] = [str(definition.get("start", ""))]
	var reached: Array[String] = []
	while not pending.is_empty():
		var node_id: String = pending.pop_front()
		if node_id.is_empty() or node_id in reached or not nodes.has(node_id): continue
		reached.append(node_id)
		var node: Dictionary = nodes[node_id]
		var next_id := str(node.get("next", ""))
		if not next_id.is_empty(): pending.append(next_id)
		for choice in node.get("choices", []) as Array: pending.append(str(choice.get("next", "")))
	# Los nodos alternativos condicionales se consideran alcanzables si su condición puede satisfacerse.
	for node_id in nodes:
		if not (nodes[node_id] as Dictionary).get("conditions", []).is_empty() and str(node_id) not in reached: reached.append(str(node_id))
	return reached

func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["variables", "quests", "codex_unlocked", "completed_scenes", "seen_banter", "choice_history"]:
		if not state.has(key): errors.append("Estado narrativo sin %s." % key)
	for codex_id in state.get("codex_unlocked", []) as Array:
		if not (data.get("codex", {}) as Dictionary).has(codex_id): errors.append("Códice desconocido: %s" % codex_id)
	return errors
