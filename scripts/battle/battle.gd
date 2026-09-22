class_name Battle
extends Node2D

const ROUND_SECONDS := 120.0
const HURRY_AT := 60.0
const BLOCK_INTERVAL := 0.3
const BRICK_DENSITY := 0.6
const ITEM_CHANCE := 0.35
const PRESSURE_RINGS := 2
const ROUND_END_DELAY := 1.5
const CARD_SECONDS := 2.0
const MATCH_CARD_SECONDS := 3.0
const BATTLE_ITEMS: Array[PowerUp.Kind] = [
	PowerUp.Kind.FIRE, PowerUp.Kind.FIRE, PowerUp.Kind.FIRE,
	PowerUp.Kind.BOMB, PowerUp.Kind.BOMB, PowerUp.Kind.BOMB,
	PowerUp.Kind.SPEED, PowerUp.Kind.SPEED,
	PowerUp.Kind.WALL_PASS, PowerUp.Kind.BOMB_PASS, PowerUp.Kind.DETONATOR,
	PowerUp.Kind.FLAMEPROOF, PowerUp.Kind.MYSTERY,
]
const NAMES: Array[String] = ["P1", "CPU1", "CPU2", "CPU3"]

const PlayerScene := preload("res://scenes/entities/player.tscn")
const AiBomberScene := preload("res://scenes/entities/ai_bomber.tscn")
const PowerUpScene := preload("res://scenes/entities/power_up.tscn")

var data: LevelData
var bombers: Array[Bomber] = []
var hidden_items: Dictionary = {}
var items: Dictionary = {}
var spiral: Array[Vector2i] = []
var spiral_index := 0
var block_clock := 0.0
var time_left := ROUND_SECONDS
var hurry := false
var running := false
var finished := false

@onready var grid: Grid = $Grid
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var stage_card: CanvasLayer = $StageCard


static func bomber_name(index: int) -> String:
	return NAMES[index]


func _ready() -> void:
	data = LevelGenerator.battle(Game.seed_text, Game.battle_round, BRICK_DENSITY)
	grid.build(data)
	grid.brick_destroyed.connect(on_brick_destroyed)
	grid.bomb_exploded.connect(on_bomb_exploded)
	place_hidden_items()
	build_spiral()
	camera.frame_whole(data.pixel_size(Grid.TILE))
	hud.set_wins(Game.battle_wins)
	hud.set_time(ROUND_SECONDS)
	stage_card.show_text("ROUND %d" % (Game.battle_round + 1), CARD_SECONDS)
	await stage_card.finished
	spawn_bombers()
	Audio.play_music("stage_2")
	running = true


func place_hidden_items() -> void:
	var rng := LevelGenerator.make_rng(LevelGenerator.stream_seed(Game.seed_text, Game.battle_round, 0, "battle_items"))
	for brick in data.brick_cells():
		if rng.randf() < ITEM_CHANCE:
			hidden_items[brick] = BATTLE_ITEMS[rng.randi_range(0, BATTLE_ITEMS.size() - 1)]


func build_spiral() -> void:
	for ring in range(1, PRESSURE_RINGS + 1):
		var left := ring
		var top := ring
		var right := data.width - 1 - ring
		var bottom := data.height - 1 - ring
		for x in range(left, right + 1):
			spiral.append(Vector2i(x, top))
		for y in range(top + 1, bottom + 1):
			spiral.append(Vector2i(right, y))
		for x in range(right - 1, left - 1, -1):
			spiral.append(Vector2i(x, bottom))
		for y in range(bottom - 1, top, -1):
			spiral.append(Vector2i(left, y))


func spawn_bombers() -> void:
	var player: Player = PlayerScene.instantiate()
	player.death_started.connect(func() -> void: Audio.play_sfx("death_jingle"))
	add_bomber(player, 0)
	for i in Game.battle_opponents:
		var ai: AiBomber = AiBomberScene.instantiate()
		ai.seed_brain(data.seed_value + i, AiBomber.PROFILES[i % AiBomber.PROFILES.size()])
		add_bomber(ai, i + 1)
	for bomber in bombers:
		if bomber is AiBomber:
			bomber.opponents = opponents_of(bomber)


func opponents_of(bomber: Bomber) -> Array[Bomber]:
	var result: Array[Bomber] = []
	for other in bombers:
		if other != bomber:
			result.append(other)
	return result


func add_bomber(bomber: Bomber, index: int) -> void:
	bomber.setup(grid, data.spawns[index])
	bomber.enemies_can_touch = false
	bomber.skin = ["white", "coral", "lime", "violet"][index]
	bombers.append(bomber)
	grid.entities.add_child(bomber)
	if index == 0:
		camera.follow_target = bomber


func _process(delta: float) -> void:
	if not running or finished:
		return
	update_timer(delta)
	update_pressure(delta)
	check_pickups()
	check_round_end()


func update_timer(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	hud.set_time(time_left)
	if not hurry and time_left <= HURRY_AT:
		hurry = true
		hud.show_hurry(true)
		Audio.play_sfx("hurry_up")
	if time_left <= 0.0:
		end_round()


func update_pressure(delta: float) -> void:
	if not hurry or spiral_index >= spiral.size():
		return
	block_clock += delta
	while block_clock >= BLOCK_INTERVAL and spiral_index < spiral.size():
		block_clock -= BLOCK_INTERVAL
		drop_pressure_block(spiral[spiral_index])
		spiral_index += 1


func drop_pressure_block(cell: Vector2i) -> void:
	grid.drop_block(cell)
	hidden_items.erase(cell)
	remove_item(cell)
	for bomber in bombers:
		if bomber.is_alive() and bomber.cell() == cell:
			bomber.die()


func check_pickups() -> void:
	for bomber in bombers:
		if not bomber.is_alive():
			continue
		var cell := bomber.cell()
		if items.has(cell):
			collect_item(bomber, items[cell])


func collect_item(bomber: Bomber, item: PowerUp) -> void:
	Audio.play_sfx("powerup")
	bomber.apply_power_up(item.kind)
	remove_item(item.cell)


func remove_item(cell: Vector2i) -> void:
	var item: PowerUp = items.get(cell)
	if item == null:
		return
	items.erase(cell)
	item.queue_free()


func on_brick_destroyed(cell: Vector2i) -> void:
	Audio.play_sfx("brick_break")
	if not hidden_items.has(cell):
		return
	var item: PowerUp = PowerUpScene.instantiate()
	item.kind = hidden_items[cell]
	item.cell = cell
	item.position = grid.cell_center(cell)
	grid.entities.add_child(item)
	items[cell] = item
	hidden_items.erase(cell)


func on_bomb_exploded(_bomb: Bomb, cells: Array[Vector2i]) -> void:
	for cell in cells:
		remove_item(cell)


func alive_indices() -> Array[int]:
	var result: Array[int] = []
	for i in bombers.size():
		if bombers[i].is_alive():
			result.append(i)
	return result


func check_round_end() -> void:
	if alive_indices().size() <= 1:
		end_round()


func end_round() -> void:
	if finished:
		return
	finished = true
	await get_tree().create_timer(ROUND_END_DELAY).timeout
	var alive := alive_indices()
	var winner := alive[0] if alive.size() == 1 else -1
	Audio.stop_music()
	if winner >= 0:
		Game.battle_wins[winner] += 1
		hud.set_wins(Game.battle_wins)
		bombers[winner].celebrate()
	var round_label := "ROUND %d" % (Game.battle_round + 1)
	if Game.battle_winner() >= 0:
		Audio.play_sfx("stage_clear")
		stage_card.show_text("%s\n%s WINS" % [round_label, bomber_name(winner)], MATCH_CARD_SECONDS)
		await stage_card.finished
		Game.go_to(Game.BATTLE_RESULTS)
		return
	stage_card.show_text("%s\n%s" % [round_label, "DRAW" if winner < 0 else "%s WINS" % bomber_name(winner)], CARD_SECONDS)
	await stage_card.finished
	Game.next_battle_round()
