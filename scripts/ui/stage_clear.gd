extends CanvasLayer

signal next_selected
signal quit_selected
var title_label: Label
var score_label: Label
var content: Control
var first_button: Button


func _ready() -> void:
	visible = false
	content = Control.new()
	add_child(content)
	ArcadeUI.panel(content, Rect2(192, 140, 640, 520))
	title_label = ArcadeUI.label(content, "STAGE CLEAR", Rect2(208, 180, 608, 64), 32, ArcadeUI.GOLD, true)
	score_label = ArcadeUI.label(content, "", Rect2(208, 294, 608, 64), 24, ArcadeUI.CREAM, true)
	first_button = ArcadeUI.button(content, "NEXT STAGE", Rect2(320, 432, 384, 64), func() -> void: next_selected.emit())
	ArcadeUI.button(content, "QUIT TO MENU", Rect2(320, 528, 384, 64), func() -> void: quit_selected.emit())
	layout()
	get_viewport().size_changed.connect(layout)


func layout() -> void:
	content.position = ((get_viewport().get_visible_rect().size - Vector2(1024, 768)) * 0.5).floor()


func open(level: int, score: int) -> void:
	title_label.text = "STAGE %d CLEAR" % level
	score_label.text = "SCORE %08d" % score
	visible = true
	first_button.grab_focus()
