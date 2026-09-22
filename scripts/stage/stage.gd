extends Node2D

const STAGE_SECONDS := 200
const MAX_ENEMIES := 10
const TIMEOUT_ENEMY := "pontan"
const TIMEOUT_SPAWN_DISTANCE := 4
const MAX_KILL_POINTS := 10000
const CLEAR_DELAY := 1.2
const DEATH_CARD_SECONDS := 2.5
const STAGE_MUSIC := ["stage_1", "stage_2", "stage_3"]

const PlayerScene := preload("res://scenes/entities/player.tscn")
const EnemyScene := preload("res://scenes/entities/enemy.tscn")
const PowerUpScene := preload("res://scenes/entities/power_up.tscn")

var data: LevelData
var player: Player
var item: PowerUp
var time_left := float(STAGE_SECONDS)
var timed_out := false
var kill_chain := 0
var enemies_spawned := 0
var finished := false
var running := false

@onready var grid: Grid = $Grid
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var stage_card: CanvasLayer = $StageCard
@onready var stage_clear: CanvasLayer = $StageClear


func _ready() -> void:
	data = LevelGenerator.campaign(Game.level, Game.seed_text, Game.attempt)
	grid.build(data)
	grid.brick_destroyed.connect(on_brick_destroyed)
	grid.bomb_exploded.connect(on_bomb_exploded)
	camera.frame_whole(data.pixel_size(Grid.TILE))
	stage_clear.next_selected.connect(Game.stage_cleared)
	stage_clear.quit_selected.connect(quit_to_menu)
	hud.set_lives(Game.lives)
	hud.set_score(Game.score)
	hud.set_time(STAGE_SECONDS)
	stage_card.show_text("STAGE %d" % Game.level, 2.2)
	await stage_card.finished
	spawn_player()
	spawn_initial_enemies()
	Audio.play_music(STAGE_MUSIC[(Game.level - 1) % STAGE_MUSIC.size()])
	running = true


func spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.setup(grid, data.spawns[0])
	player.bombs_max = Game.bombs_max
	player.fire_range = Game.fire_range
	player.has_skate = Game.has_skate
	player.death_started.connect(on_player_death_started)
	player.died.connect(on_player_died)
	grid.entities.add_child(player)
	camera.follow_target = player


func spawn_initial_enemies() -> void:
	for entry in data.enemies:
		spawn_enemy(entry.type, entry.cell)


func spawn_enemy(type_name: String, cell: Vector2i) -> void:
	var enemy: Enemy = EnemyScene.instantiate()
	enemy.setup(grid, player, type_name, cell, data.seed_value + enemies_spawned)
	enemy.died.connect(on_enemy_died)
	grid.entities.add_child(enemy)
	enemies_spawned += 1


func alive_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_alive():
			result.append(enemy)
	return result


func _process(delta: float) -> void:
	if not running or finished:
		return
	update_timer(delta)
	if grid.flames.is_empty():
		kill_chain = 0
	if player.is_alive():
		check_pickups()


func quit_to_menu() -> void:
	Audio.stop_music()
	Game.go_to(Game.MAIN_MENU)


func update_timer(delta: float) -> void:
	if timed_out:
		return
	time_left = maxf(time_left - delta, 0.0)
	hud.set_time(ceili(time_left))
	if time_left <= 0.0:
		on_timeout()


func on_timeout() -> void:
	timed_out = true
	Audio.play_sfx("hurry_up")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	var open := open_cells_away_from(player.cell(), TIMEOUT_SPAWN_DISTANCE)
	var rng := LevelGenerator.make_rng(data.seed_value ^ 0x7A11)
	LevelGenerator.shuffle(open, rng)
	for i in mini(MAX_ENEMIES, open.size()):
		spawn_enemy(TIMEOUT_ENEMY, open[i])


func open_cells_away_from(origin: Vector2i, min_distance: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			var far := absi(cell.x - origin.x) + absi(cell.y - origin.y) >= min_distance
			if data.is_passable(cell) and not grid.has_bomb(cell) and far:
				result.append(cell)
	return result


func check_pickups() -> void:
	if item != null and item.cell == player.cell():
		collect_item()


func collect_item() -> void:
	Audio.play_sfx("powerup")
	player.apply_power_up(item.kind)
	hud.show_remote_hint(player.remote)
	Game.fire_range = player.fire_range
	Game.bombs_max = player.bombs_max
	Game.has_skate = player.has_skate
	item.queue_free()
	item = null


func on_brick_destroyed(cell: Vector2i) -> void:
	Audio.play_sfx("brick_break")
	if cell == data.item_cell:
		item = PowerUpScene.instantiate()
		item.kind = data.item_type
		item.cell = cell
		item.position = grid.cell_center(cell)
		grid.entities.add_child(item)


func on_bomb_exploded(_bomb: Bomb, cells: Array[Vector2i]) -> void:
	if item != null and item.cell in cells:
		var cell := item.cell
		item.queue_free()
		item = null
		punish(cell)


func punish(cell: Vector2i) -> void:
	var spawn_type: String = EnemyTypes.ITEM_SPAWN.get(data.item_type, TIMEOUT_ENEMY)
	var room := MAX_ENEMIES - alive_enemies().size()
	for i in room:
		spawn_enemy(spawn_type, cell)


func on_enemy_died(enemy: Enemy) -> void:
	var points := mini(enemy.points() << kill_chain, MAX_KILL_POINTS)
	kill_chain += 1
	Game.add_score(points)
	hud.set_score(Game.score)
	if alive_enemies().is_empty() and player.is_alive():
		clear_stage()


func on_player_death_started() -> void:
	if finished:
		return
	finished = true
	Audio.stop_music()
	Audio.play_sfx("death_jingle")


func on_player_died() -> void:
	var remaining := Game.lives - 1
	if remaining < 0:
		Audio.play_sfx("game_over")
		stage_card.show_text("GAME OVER", DEATH_CARD_SECONDS)
	else:
		stage_card.show_text("YOU DIED\n\nLEFT %d" % remaining, DEATH_CARD_SECONDS)
	await stage_card.finished
	Game.player_died()


func clear_stage() -> void:
	if finished:
		return
	finished = true
	player.celebrate()
	Audio.stop_music()
	Audio.play_sfx("stage_clear")
	await get_tree().create_timer(CLEAR_DELAY).timeout
	stage_clear.open(Game.level, Game.score)
