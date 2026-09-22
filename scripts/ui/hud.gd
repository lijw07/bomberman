extends CanvasLayer

@export var battle := false
var time_label: Label
var score_label: Label
var lives_label: Label
var hint_label: Label
var hurry_label: Label
var wins_labels: Array[Label] = []
var bar: Control


func _ready() -> void:
	bar = Control.new()
	add_child(bar)
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = ArcadeUI.INK
	backdrop.size = Vector2(4096, 140)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(backdrop)
	if battle:
		for i in 4:
			var x: int = [16, 208, 624, 816][i]
			ArcadeUI.panel(bar, Rect2(x, 8, 192, 124))
			ArcadeUI.portrait(bar, ["white", "coral", "lime", "violet"][i], Vector2(x + 38, 66))
			ArcadeUI.label(bar, "P1" if i == 0 else "CPU %d" % i, Rect2(x + 84, 26, 100, 32), 16)
			wins_labels.append(ArcadeUI.label(bar, "0 WINS", Rect2(x + 84, 76, 100, 32), 16, ArcadeUI.GOLD))
		ArcadeUI.panel(bar, Rect2(416, 8, 192, 124))
		ArcadeUI.label(bar, "BATTLE", Rect2(416, 18, 192, 32), 16, ArcadeUI.TEAL, true)
		time_label = ArcadeUI.label(bar, "2:00", Rect2(416, 50, 192, 48), 32, ArcadeUI.CREAM, true)
		ArcadeUI.label(bar, "FIRST TO 2", Rect2(416, 100, 192, 24), 12, ArcadeUI.GOLD, true)
	else:
		ArcadeUI.panel(bar, Rect2(16, 8, 288, 124))
		ArcadeUI.label(bar, "STAGE %02d" % Game.level, Rect2(40, 24, 240, 40), 24)
		time_label = ArcadeUI.label(bar, "TIME 200", Rect2(40, 76, 240, 40), 24, ArcadeUI.GOLD)
		ArcadeUI.panel(bar, Rect2(320, 8, 368, 124))
		ArcadeUI.label(bar, "SCORE", Rect2(320, 24, 368, 32), 16, ArcadeUI.TEAL, true)
		score_label = ArcadeUI.label(bar, "00000000", Rect2(320, 66, 368, 48), 32, ArcadeUI.CREAM, true)
		ArcadeUI.panel(bar, Rect2(704, 8, 304, 124))
		ArcadeUI.portrait(bar, "white", Vector2(754, 66))
		lives_label = ArcadeUI.label(bar, "LIVES 3", Rect2(818, 34, 184, 48), 24)
	hint_label = ArcadeUI.label(bar, "X  REMOTE", Rect2(800, 140, 208, 32), 16, ArcadeUI.TEAL)
	hint_label.visible = false
	hurry_label = ArcadeUI.label(bar, "HURRY UP!", Rect2(320, 140, 384, 40), 24, ArcadeUI.GOLD, true)
	hurry_label.visible = false
	var footer := Control.new()
	footer.name = "Footer"
	bar.add_child(footer)
	var cover := ColorRect.new()
	cover.name = "Cover"
	cover.color = ArcadeUI.INK
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(cover)
	ArcadeUI.panel(footer, Rect2(16, 0, 992, 48))
	ArcadeUI.label(footer, "WASD MOVE   SPACE BOMB   ESC PAUSE", Rect2(16, 0, 992, 48), 16, ArcadeUI.BLUE, true)
	layout()
	get_viewport().size_changed.connect(layout)


func layout() -> void:
	bar.position.x = floorf((get_viewport().get_visible_rect().size.x - 1024) * 0.5)
	bar.get_node("Backdrop").position.x = -bar.position.x
	bar.get_node("Backdrop").size.x = get_viewport().get_visible_rect().size.x
	bar.get_node("Footer").position.y = get_viewport().get_visible_rect().size.y - 56
	bar.get_node("Footer/Cover").position.x = -bar.position.x
	bar.get_node("Footer/Cover").size = Vector2(get_viewport().get_visible_rect().size.x, 56)


func set_time(seconds: float) -> void:
	var whole := ceili(seconds)
	time_label.text = "%d:%02d" % [int(whole / 60.0), whole % 60] if battle else "TIME %d" % whole


func set_score(score: int) -> void:
	score_label.text = "%08d" % score


func set_lives(lives: int) -> void:
	lives_label.text = "LIVES %d" % (lives + 1)


func show_remote_hint(value: bool) -> void:
	hint_label.visible = value


func set_wins(wins: Array[int]) -> void:
	for i in wins_labels.size():
		wins_labels[i].text = "%d WINS" % wins[i] if i < wins.size() else "OFF"


func show_hurry(value: bool) -> void:
	hurry_label.visible = value
