extends CanvasLayer

@onready var title_label: Label = $Root/Objective/Content/Title
@onready var objective_label: Label = $Root/Objective/Content/Objective
@onready var prompt_backdrop: ColorRect = $Root/PromptBackdrop
@onready var prompt: Label = $Root/Prompt
@onready var notification_backdrop: ColorRect = $Root/NotificationBackdrop
@onready var notification_label: Label = $Root/Notification
@onready var route_title: Label = $Root/Route/Content/Title
@onready var route_next: Label = $Root/Route/Content/Next
@onready var route_progress: ProgressBar = $Root/Route/Content/Progress

func configure(title: String, objective: String, interaction: String, notification: String, completion: float, next_label: String) -> void:
	title_label.text = title
	objective_label.text = objective
	prompt_backdrop.visible = not interaction.is_empty()
	prompt.visible = not interaction.is_empty()
	prompt.text = "E / ESPACIO · %s" % interaction
	notification_backdrop.visible = not notification.is_empty()
	notification_label.visible = not notification.is_empty()
	notification_label.text = notification
	route_title.text = "RUTA VERTICAL %.0f%%" % completion
	route_next.text = next_label
	route_progress.value = completion
