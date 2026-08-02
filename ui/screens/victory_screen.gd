extends CanvasLayer

@onready var heading: Label = $Root/Panel/Margin/Copy/Heading
@onready var body: Label = $Root/Panel/Margin/Copy/Body

func configure(vertical_complete: bool) -> void:
	heading.text = "DEMO VERTICAL COMPLETADA" if vertical_complete else "EL JURAMENTO RESTAURADO"
	body.text = "Valdoria recuerda sus nombres y Eira vuelve a escuchar. El camino hacia la Corona Hueca queda abierto." if vertical_complete else "Eryndor conserva sus recuerdos. La corona deja de pertenecer a un rey y vuelve a ser la promesa de todos sus pueblos."
