extends Control

const RETURN_SECONDS := 4.0

@onready var score_label: Label = $ScoreLabel
@onready var stage_label: Label = $StageLabel


func _ready() -> void:
	score_label.text = "SCORE %08d" % Game.score
	stage_label.text = "REACHED STAGE %d" % Game.level
	await get_tree().create_timer(RETURN_SECONDS).timeout
	Game.go_to(Game.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		Game.go_to(Game.MAIN_MENU)
