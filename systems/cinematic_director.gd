class_name CinematicDirector
extends RefCounted

const DATA_PATH := "res://data/cinematics/phase24_shots.json"
const CENTER := Vector2(480, 270)

var active := false
var sequence_id := ""
var elapsed := 0.0
var reduced_motion := false
var title := ""
var subtitle := ""
var shot_label := ""
var zoom := 1.0
var target_zoom := 1.0
var offset := Vector2.ZERO
var target_offset := Vector2.ZERO
var letterbox := 0.0
var target_letterbox := 0.0
var data: Dictionary = {}

func _init() -> void:
	data = load_data()

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}

func begin_sequence(requested_id: String, motion_reduced: bool = false) -> void:
	var sequences := data.get("sequences", {}) as Dictionary
	var resolved_id := requested_id if sequences.has(requested_id) else "directed_scene"
	var sequence := sequences.get(resolved_id, {}) as Dictionary
	active = true
	sequence_id = resolved_id
	elapsed = 0.0
	reduced_motion = motion_reduced
	title = str(sequence.get("title", ""))
	subtitle = str(sequence.get("subtitle", ""))
	apply_profile(str(sequence.get("opening", "wide")), true)

func cue(metadata: Dictionary) -> void:
	if not active:
		return
	var cue_id := str(metadata.get("camera", "wide"))
	if str(metadata.get("music", "")) in ["ominous", "finale"] and cue_id == "wide":
		cue_id = str(metadata.get("music"))
	apply_profile(cue_id)

func apply_profile(profile_id: String, snap: bool = false) -> void:
	var profiles := data.get("profiles", {}) as Dictionary
	var profile := profiles.get(profile_id, profiles.get("wide", {})) as Dictionary
	var raw_offset := profile.get("offset", [0, 0]) as Array
	target_zoom = float(profile.get("zoom", 1.0))
	target_offset = Vector2(float(raw_offset[0]), float(raw_offset[1])) if raw_offset.size() >= 2 else Vector2.ZERO
	target_letterbox = float(profile.get("letterbox", 0.0))
	shot_label = str(profile.get("label", profile_id)).to_upper()
	if snap or reduced_motion:
		zoom = target_zoom
		offset = target_offset
		letterbox = target_letterbox

func update(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if reduced_motion:
		return
	var weight := 1.0 - exp(-delta * 5.5)
	zoom = lerpf(zoom, target_zoom, weight)
	offset = offset.lerp(target_offset, weight)
	letterbox = lerpf(letterbox, target_letterbox, weight)

func end_sequence() -> void:
	active = false
	sequence_id = ""
	title = ""
	subtitle = ""
	shot_label = ""
	zoom = 1.0
	offset = Vector2.ZERO
	letterbox = 0.0

func canvas_transform() -> Dictionary:
	return {"origin": CENTER - CENTER * zoom + offset, "zoom": zoom}

func overlay_snapshot() -> Dictionary:
	return {
		"active": active,
		"letterbox": letterbox,
		"title": title if elapsed <= 3.0 else "",
		"subtitle": subtitle if elapsed <= 3.0 else "",
		"shot": shot_label
	}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var loaded := load_data()
	var profiles := loaded.get("profiles", {}) as Dictionary
	var sequences := loaded.get("sequences", {}) as Dictionary
	for required in ["wide", "close_up", "pan_left", "pan_right", "pan_up", "boss_intro", "finale"]:
		if not profiles.has(required):
			errors.append("Falta el encuadre %s." % required)
	for sequence_id in sequences:
		var sequence := sequences[sequence_id] as Dictionary
		if str(sequence.get("title", "")).is_empty() or not profiles.has(str(sequence.get("opening", ""))):
			errors.append("Secuencia cinematográfica inválida: %s." % sequence_id)
	return errors
