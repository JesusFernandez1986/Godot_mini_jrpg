class_name PerformanceBudgetSystem
extends Node

const TARGET_FPS := 60
const FRAME_BUDGET_MS := 1000.0 / TARGET_FPS
const MAX_P95_FRAME_MS := 20.0
const MAX_SCENE_NODES := 700
const MAX_DRAW_CALLS_2D := 800
const MAX_RENDER_OBJECTS := 4500
const MAX_TEXTURE_MEMORY_MB := 512.0
const SUPPORTED_RESOLUTIONS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var frame_samples: Array[float] = []
var over_budget_frames := 0
var total_frames := 0

func record_frame(delta: float) -> void:
	var milliseconds := delta * 1000.0
	total_frames += 1
	if total_frames <= 30:
		return
	frame_samples.append(milliseconds)
	if milliseconds > MAX_P95_FRAME_MS:
		over_budget_frames += 1
	if frame_samples.size() > 600:
		frame_samples.pop_front()

func percentile_frame_time(percentile: float = 0.95) -> float:
	if frame_samples.is_empty():
		return 0.0
	var ordered := frame_samples.duplicate()
	ordered.sort()
	return float(ordered[clampi(int(ceil(percentile * ordered.size())) - 1, 0, ordered.size() - 1)])

func snapshot(scene_root: Node) -> Dictionary:
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"p95_frame_ms": percentile_frame_time(),
		"scene_nodes": count_nodes(scene_root),
		"draw_calls_2d": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"render_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"texture_memory_mb": float(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)) / 1048576.0,
		"over_budget_frames": over_budget_frames,
	}

static func count_nodes(root: Node) -> int:
	var total := 1
	for child in root.get_children():
		total += count_nodes(child)
	return total

static func evaluate(snapshot_data: Dictionary, require_frame_time: bool = true) -> Array[String]:
	var errors: Array[String] = []
	if require_frame_time and float(snapshot_data.get("p95_frame_ms", 0.0)) > MAX_P95_FRAME_MS:
		errors.append("P95 de frame supera %.1f ms." % MAX_P95_FRAME_MS)
	if int(snapshot_data.get("scene_nodes", 0)) > MAX_SCENE_NODES:
		errors.append("La escena supera %d nodos." % MAX_SCENE_NODES)
	if int(snapshot_data.get("draw_calls_2d", 0)) > MAX_DRAW_CALLS_2D:
		errors.append("El render supera %d draw calls 2D." % MAX_DRAW_CALLS_2D)
	if int(snapshot_data.get("render_objects", 0)) > MAX_RENDER_OBJECTS:
		errors.append("El render supera %d objetos." % MAX_RENDER_OBJECTS)
	if float(snapshot_data.get("texture_memory_mb", 0.0)) > MAX_TEXTURE_MEMORY_MB:
		errors.append("Las texturas superan %.0f MB." % MAX_TEXTURE_MEMORY_MB)
	return errors

static func resolution_scale(resolution: Vector2i) -> Vector2:
	return Vector2(float(resolution.x) / 960.0, float(resolution.y) / 540.0)

static func validate() -> Array[String]:
	var errors: Array[String] = []
	if TARGET_FPS < 60 or MAX_P95_FRAME_MS > 25.0:
		errors.append("El objetivo de fluidez no alcanza el estándar de 60 FPS.")
	for resolution in SUPPORTED_RESOLUTIONS:
		if not is_equal_approx(float(resolution.x) / float(resolution.y), 16.0 / 9.0):
			errors.append("Resolución no compatible con 16:9: %s." % resolution)
	return errors
