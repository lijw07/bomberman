extends CanvasLayer

var content: Control
var resume_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	content = Control.new()
	add_child(content)
	ArcadeUI.panel(content, Rect2(192, 168, 640, 440))
	ArcadeUI.label(content, "PAUSED", Rect2(192, 208, 640, 80), 40, ArcadeUI.CREAM, true)
	resume_button = ArcadeUI.button(content, "RESUME", Rect2(320, 352, 384, 64), resume)
	ArcadeUI.button(content, "MAIN MENU", Rect2(320, 456, 384, 64), func() -> void:
		resume()
		Game.go_to(Game.MAIN_MENU))
	layout()
	get_viewport().size_changed.connect(layout)


func layout() -> void:
	content.position = ((get_viewport().get_visible_rect().size - Vector2(1024, 768)) * 0.5).floor()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func resume() -> void:
	get_tree().paused = false
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		resume()
	elif get_parent().get("running") and not get_parent().get("finished"):
		open()
	get_viewport().set_input_as_handled()
