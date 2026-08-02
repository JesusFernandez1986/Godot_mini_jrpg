class_name CinematicOverlay
extends CanvasLayer

@onready var top_bar: ColorRect = $Root/TopBar
@onready var bottom_bar: ColorRect = $Root/BottomBar
@onready var title_label: Label = $Root/TitleBlock/Title
@onready var subtitle_label: Label = $Root/TitleBlock/Subtitle
@onready var shot_label: Label = $Root/Shot

func configure(snapshot: Dictionary) -> void:
	var bar_height := clampf(float(snapshot.get("letterbox", 0.0)), 0.0, 64.0)
	top_bar.offset_bottom = bar_height
	bottom_bar.offset_top = -bar_height
	title_label.text = str(snapshot.get("title", ""))
	subtitle_label.text = str(snapshot.get("subtitle", ""))
	title_label.visible = not title_label.text.is_empty()
	subtitle_label.visible = not subtitle_label.text.is_empty()
	shot_label.text = str(snapshot.get("shot", ""))
	shot_label.visible = not shot_label.text.is_empty()
