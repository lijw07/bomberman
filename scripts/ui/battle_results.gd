extends Control

const OPTIONS := ["REMATCH", "MAIN MENU"]
const CURSOR := "> "
const BLANK := "  "
const WINNER_COLOR := Color(1.0, 0.85, 0.4)
const LOSER_COLOR := Color(0.75, 0.75, 0.75)

var selected := 0

@onready var winner_label: Label = $Panel/Winner
@onready var rows: VBoxContainer = $Panel/Rows
@onready var option_labels: Array[Label] = [$Panel/Rematch, $Panel/Menu]


func _ready() -> void:
	var winner := Game.battle_winner()
	winner_label.text = "%s WINS THE MATCH" % Battle.bomber_name(winner)
	build_rows(winner)
	refresh()
	Audio.play_music("ending", false)


func build_rows(winner: int) -> void:
	var template: Label = rows.get_child(0)
	for i in Game.battle_wins.size():
		var row: Label = template.duplicate()
		row.text = "%-5s %d ROUND%s" % [Battle.bomber_name(i), Game.battle_wins[i], "" if Game.battle_wins[i] == 1 else "S"]
		row.modulate = WINNER_COLOR if i == winner else LOSER_COLOR
		row.visible = true
		rows.add_child(row)
	template.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		move_cursor(1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		move_cursor(-1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("place_bomb"):
		choose()
	elif event.is_action_pressed("ui_cancel"):
		go_to_menu()


func move_cursor(step: int) -> void:
	selected = wrapi(selected + step, 0, OPTIONS.size())
	Audio.play_sfx("menu_move")
	refresh()


func refresh() -> void:
	for i in option_labels.size():
		option_labels[i].text = (CURSOR if i == selected else BLANK) + OPTIONS[i]


func choose() -> void:
	Audio.play_sfx("menu_select")
	Audio.stop_music()
	if selected == 0:
		Game.start_battle(Game.battle_opponents)
	else:
		go_to_menu()


func go_to_menu() -> void:
	Audio.stop_music()
	Game.go_to(Game.MAIN_MENU)
