class_name HD2DStage
extends Node

@onready var backdrop_layer: CanvasLayer = $BackdropLayer
@onready var backdrop_renderer: Node2D = $BackdropLayer/Backdrop
@onready var foreground_layer: CanvasLayer = $ForegroundLayer
@onready var foreground_renderer: Node2D = $ForegroundLayer/Foreground

var active_theme := ""

func present(
	theme_id: String,
	texture: Texture2D,
	camera_origin: Vector2,
	camera_zoom: float,
	elapsed: float,
	reduced_motion: bool
) -> void:
	var profile := WorldPresentationSystem.hd2d_profile(theme_id)
	if texture == null or profile.is_empty():
		deactivate()
		return
	active_theme = theme_id
	backdrop_layer.visible = true
	foreground_layer.visible = true
	backdrop_renderer.configure(texture, profile, camera_origin, camera_zoom, elapsed, reduced_motion)
	foreground_renderer.configure(profile, elapsed, reduced_motion)

func deactivate() -> void:
	active_theme = ""
	backdrop_layer.visible = false
	foreground_layer.visible = false

func is_active() -> bool:
	return not active_theme.is_empty()

