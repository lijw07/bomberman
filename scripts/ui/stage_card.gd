extends CanvasLayer

signal finished
var label: Label
var content: Control


func _ready() -> void:
	visible = false
	content = Control.new()
	add_child(content)
	ArcadeUI.panel(content, Rect2(192, 220, 640, 320))
	label = ArcadeUI.label(content, "", Rect2(208, 244, 608, 272), 32, ArcadeUI.CREAM, true)
	layout()
	get_viewport().size_changed.connect(layout)


func layout() -> void:
	content.position = ((get_viewport().get_visible_rect().size - Vector2(1024, 768)) * 0.5).floor()


func show_text(text: String, seconds: float) -> void:
	label.text = text
	visible = true
	await get_tree().create_timer(seconds, false).timeout
	visible = false
	finished.emit()
