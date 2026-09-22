extends Node

enum Mode { CAMPAIGN, BATTLE }

const STARTING_LIVES := 2
const MAX_BOMBS := 10
const MAX_FIRE := 5
const ROUNDS_TO_WIN := 2
const MAX_OPPONENTS := 3
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const STAGE := "res://scenes/stage/stage.tscn"
const BATTLE := "res://scenes/battle/battle.tscn"
const GAME_OVER := "res://scenes/ui/game_over.tscn"
const BATTLE_RESULTS := "res://scenes/ui/battle_results.tscn"

var mode := Mode.CAMPAIGN
var seed_text := ""
var level := 1
var attempt := 0
var score := 0
var lives := STARTING_LIVES
var bombs_max := 1
var fire_range := 1
var has_skate := false
var battle_opponents := MAX_OPPONENTS
var battle_round := 0
var battle_wins: Array[int] = []


func start_campaign() -> void:
	mode = Mode.CAMPAIGN
	seed_text = random_seed()
	level = 1
	attempt = 0
	score = 0
	lives = STARTING_LIVES
	bombs_max = 1
	fire_range = 1
	has_skate = false
	go_to(STAGE)


func start_battle(opponents: int) -> void:
	mode = Mode.BATTLE
	seed_text = random_seed()
	battle_opponents = clampi(opponents, 1, MAX_OPPONENTS)
	battle_round = 0
	battle_wins = []
	for i in battle_opponents + 1:
		battle_wins.append(0)
	go_to(BATTLE)


func next_battle_round() -> void:
	battle_round += 1
	go_to(BATTLE)


func battle_winner() -> int:
	for i in battle_wins.size():
		if battle_wins[i] >= ROUNDS_TO_WIN:
			return i
	return -1


func random_seed() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return to_base36(rng.randi())


func to_base36(value: int) -> String:
	const DIGITS := "0123456789abcdefghijklmnopqrstuvwxyz"
	if value == 0:
		return "0"
	var result := ""
	var remaining := absi(value)
	while remaining > 0:
		result = DIGITS[remaining % 36] + result
		remaining = int(remaining / 36.0)
	return result


func add_score(points: int) -> void:
	score += points


func stage_cleared() -> void:
	level += 1
	lives += 1
	attempt = 0
	go_to(STAGE)


func player_died() -> void:
	lives -= 1
	if lives < 0:
		go_to(GAME_OVER)
		return
	attempt += 1
	go_to(STAGE)


func go_to(scene_path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", scene_path)


func quit() -> void:
	Audio.silence()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
