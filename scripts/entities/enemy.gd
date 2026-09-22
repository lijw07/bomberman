class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

enum State { WALK, DYING, DEAD }

const DEATH_SECONDS := 0.96
const CHASE_RANGE := 8
const FLEE_FLIP_MIN := 2.0
const FLEE_FLIP_MAX := 5.0


var grid: Grid
var player: Player
var rng: RandomNumberGenerator
@export var type_name := "ballom"
var stats: Dictionary
var cell := Vector2i.ZERO
var dir := Vector2i.ZERO
var speed := 30.0
var state := State.WALK
var turn_timer := 0.0
var fleeing := false
var flee_timer := 0.0
var death_clock := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(target_grid: Grid, target_player: Player, enemy_type: String, start_cell: Vector2i, seed_value: int) -> void:
	grid = target_grid
	player = target_player
	type_name = enemy_type
	stats = EnemyTypes.stats(enemy_type)
	collision_mask = 17 if stats.wall_pass else 19
	cell = start_cell
	speed = stats.speed
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	position = grid.cell_center(cell)


func _ready() -> void:
	add_to_group("enemies")
	sprite.sprite_frames = load("res://resources/arcade/enemy_%s.tres" % type_name)
	sprite.play("move_down")
	if grid == null:
		set_physics_process(false)
		return
	reset_turn_timer()
	choose_direction()


func _physics_process(delta: float) -> void:
	match state:
		State.WALK:
			update_walk(delta)
		State.DYING:
			update_dying(delta)


func update_walk(delta: float) -> void:
	turn_timer -= delta
	update_flee(delta)
	if dir == Vector2i.ZERO:
		choose_direction()
	else:
		advance(delta)
	animate(delta)
	if grid.is_burning(grid.to_cell(position)):
		die()


func advance(delta: float) -> void:
	var target := grid.cell_center(cell + dir)
	position = position.move_toward(target, speed * delta)
	if position.distance_to(target) > 0.01:
		return
	cell += dir
	position = target
	decide()


func decide() -> void:
	var open := grid.open_directions(cell, stats.wall_pass)
	var chase := chase_direction()
	if chase != Vector2i.ZERO and chase in open:
		dir = chase
		return
	var at_junction := open.size() > 2 or not (dir in open)
	var erratic_turn: bool = stats.erratic and rng.randf() < 0.5
	if not (dir in open) or (at_junction and turn_timer <= 0.0) or erratic_turn:
		choose_direction()
		if stats.erratic:
			speed = stats.speed * rng.randf_range(0.7, 1.3)


func choose_direction() -> void:
	var open := grid.open_directions(cell, stats.wall_pass)
	reset_turn_timer()
	if open.is_empty():
		dir = Vector2i.ZERO
		return
	var options := open.filter(func(d: Vector2i) -> bool: return d != -dir) if open.size() > 1 else open
	dir = options[rng.randi_range(0, options.size() - 1)]


func reset_turn_timer() -> void:
	turn_timer = rng.randf_range(stats.turn_min, stats.turn_max)


func chase_direction() -> Vector2i:
	if stats.chase == EnemyTypes.Chase.NONE or player == null or not player.is_alive():
		return Vector2i.ZERO
	var target := grid.to_cell(player.position)
	var delta := target - cell
	var chase := Vector2i.ZERO
	if delta.x == 0 and absi(delta.y) <= CHASE_RANGE and stats.chase != EnemyTypes.Chase.ROW:
		chase = Vector2i(0, signi(delta.y))
	elif delta.y == 0 and absi(delta.x) <= CHASE_RANGE and stats.chase != EnemyTypes.Chase.COLUMN:
		chase = Vector2i(signi(delta.x), 0)
	if chase == Vector2i.ZERO or not grid.line_is_clear(cell, target, stats.wall_pass):
		return Vector2i.ZERO
	return -chase if fleeing else chase


func update_flee(delta: float) -> void:
	if not stats.flee:
		return
	flee_timer -= delta
	if flee_timer <= 0.0:
		fleeing = not fleeing
		flee_timer = rng.randf_range(FLEE_FLIP_MIN, FLEE_FLIP_MAX)


func animate(_delta: float) -> void:
	var direction: String = {Vector2i.DOWN: "down", Vector2i.UP: "up", Vector2i.RIGHT: "right", Vector2i.LEFT: "left"}.get(dir, "down")
	sprite.play("move_" + direction)


func die() -> void:
	if state != State.WALK:
		return
	state = State.DYING
	death_clock = 0.0
	sprite.play("death")
	$CollisionShape2D.set_deferred("disabled", true)
	Audio.play_sfx("enemy_die")


func update_dying(delta: float) -> void:
	death_clock += delta
	if death_clock >= DEATH_SECONDS:
		state = State.DEAD
		died.emit(self)
		queue_free()


func is_alive() -> bool:
	return state == State.WALK


func points() -> int:
	return stats.points
