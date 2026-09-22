extends Control

@export_enum("menu", "results", "game_over") var initial_screen := "menu"
var screen := "menu"
var selected := 0
var opponents := 3
var buttons: Array[Button] = []
var content: Control
var opponents_label: Label


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ArcadeUI.backdrop(self)
	content = Control.new()
	add_child(content)
	resized.connect(layout)
	layout()
	show_screen(initial_screen)
	Audio.play_music("ending" if initial_screen == "results" else "title")


func layout() -> void:
	if content:
		content.position = ((size - Vector2(1024, 768)) * 0.5).floor()


func show_screen(next: String) -> void:
	screen = next
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	buttons.clear()
	selected = 0
	match screen:
		"menu": build_menu()
		"setup": build_setup()
		"help": build_help()
		"results": build_results()
		"game_over": build_game_over()
	if not buttons.is_empty():
		buttons[2 if screen == "setup" else 0].grab_focus()


func add_button(text: String, rect: Rect2, action: Callable) -> void:
	var index := buttons.size()
	var button := ArcadeUI.button(content, text, rect, func() -> void:
		Audio.play_sfx("menu_select")
		action.call())
	button.focus_entered.connect(func() -> void: selected = index)
	buttons.append(button)


func build_menu() -> void:
	ArcadeUI.header(content, "READY. SET. BOOM.")
	for entry in [[176, "white"], [848, "coral"]]:
		ArcadeUI.image(content, ArcadeUI.atlas("res://assets/arcade/sprites/terrain.png", Rect2(64, 0, 64, 64)), Vector2(entry[0] - 32, 504))
		ArcadeUI.portrait(content, entry[1], Vector2(entry[0], 438))
	add_button("CAMPAIGN", Rect2(320, 252, 384, 64), Game.start_campaign)
	add_button("BATTLE", Rect2(320, 334, 384, 64), func() -> void: show_screen("setup"))
	add_button("HOW TO PLAY", Rect2(320, 416, 384, 64), func() -> void: show_screen("help"))
	if not OS.has_feature("web"):
		add_button("QUIT", Rect2(320, 498, 384, 64), Game.quit)
	ArcadeUI.panel(content, Rect2(256, 650, 512, 64))
	ArcadeUI.label(content, "WASD SELECT / ENTER CONFIRM", Rect2(256, 650, 512, 64), 16, ArcadeUI.BLUE, true)


func build_setup() -> void:
	ArcadeUI.header(content, "BATTLE SETUP")
	for i in 4:
		var x := 64 + i * 232
		ArcadeUI.panel(content, Rect2(x, 237, 200, 267), i == 0)
		ArcadeUI.label(content, "PLAYER 1" if i == 0 else "CPU %d" % i, Rect2(x, 255, 200, 42), 20, ArcadeUI.CREAM, true)
		ArcadeUI.portrait(content, ["white", "coral", "lime", "violet"][i], Vector2(x + 100, 363))
		ArcadeUI.label(content, "READY" if i == 0 else "NORMAL", Rect2(x, 441, 200, 48), 20, ArcadeUI.GOLD, true)
	opponents_label = ArcadeUI.label(content, "", Rect2(256, 526, 512, 64), 24, ArcadeUI.TEAL, true)
	add_button("-", Rect2(160, 530, 64, 64), func() -> void: change_opponents(-1))
	add_button("+", Rect2(800, 530, 64, 64), func() -> void: change_opponents(1))
	ArcadeUI.label(content, "FIRST TO 2 WINS / 2:00 PER ROUND", Rect2(128, 594, 768, 32), 16, ArcadeUI.BLUE, true)
	add_button("START BATTLE", Rect2(320, 648, 384, 64), func() -> void: Game.start_battle(opponents))
	add_button("BACK", Rect2(32, 680, 192, 64), func() -> void: show_screen("menu"))
	change_opponents(0)


func change_opponents(step: int) -> void:
	opponents = wrapi(opponents + step, 1, 4)
	opponents_label.text = "%d OPPONENT%s" % [opponents, "" if opponents == 1 else "S"]


func build_help() -> void:
	ArcadeUI.image(content, load("res://assets/arcade/ui/screen-how-to-play.png"), Vector2.ZERO)
	add_button("BACK", Rect2(320, 653, 384, 64), func() -> void: show_screen("menu"))


func build_results() -> void:
	var winner := maxi(0, Game.battle_winner())
	ArcadeUI.header(content, "%s WINS THE MATCH" % Battle.bomber_name(winner))
	ArcadeUI.portrait(content, ["white", "coral", "lime", "violet"][winner], Vector2(512, 274), "victory")
	for i in Game.battle_wins.size():
		ArcadeUI.label(content, "%s     %d WINS" % [Battle.bomber_name(i), Game.battle_wins[i]], Rect2(256, 350 + i * 44, 512, 40), 24, ArcadeUI.GOLD if i == winner else ArcadeUI.CREAM, true)
	add_button("REMATCH", Rect2(320, 560, 384, 64), func() -> void: Game.start_battle(Game.battle_opponents))
	add_button("MAIN MENU", Rect2(320, 648, 384, 64), func() -> void: Game.go_to(Game.MAIN_MENU))


func build_game_over() -> void:
	ArcadeUI.header(content, "GAME OVER")
	ArcadeUI.panel(content, Rect2(224, 264, 576, 240))
	ArcadeUI.label(content, "SCORE %08d" % Game.score, Rect2(224, 296, 576, 64), 24, ArcadeUI.GOLD, true)
	ArcadeUI.label(content, "REACHED STAGE %d" % Game.level, Rect2(224, 380, 576, 64), 24, ArcadeUI.CREAM, true)
	add_button("TRY AGAIN", Rect2(320, 560, 384, 64), Game.start_campaign)
	add_button("MAIN MENU", Rect2(320, 648, 384, 64), func() -> void: Game.go_to(Game.MAIN_MENU))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and screen != "menu":
		show_screen("menu")
	elif screen == "setup" and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		change_opponents(-1 if event.is_action_pressed("move_left") else 1)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		selected = wrapi(selected + (1 if event.is_action_pressed("move_down") else -1), 0, buttons.size())
		buttons[selected].grab_focus()
		Audio.play_sfx("menu_move")
	elif event.is_action_pressed("place_bomb"):
		buttons[selected].pressed.emit()
