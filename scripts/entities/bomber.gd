class_name Bomber
extends CharacterBody2D

signal died
signal death_started

enum State { ALIVE, DYING, DEAD }

const HALF_HITBOX := Grid.HALF_TILE - 0.1
const BASE_SPEED := 180.0
const SKATE_SPEED := 240.0
const DEATH_SECONDS := 0.8
const ENEMY_TOUCH_DISTANCE := 48.0
const INVINCIBLE_SECONDS := 34.0
const TURN_WINDOW := 8.0

var grid: Grid
var state := State.ALIVE
var facing := Vector2.DOWN
var moving := false
var death_clock := 0.0
var bombs_max := 1
var fire_range := 1
var has_skate := false
var wall_pass := false
var bomb_pass := false
var remote := false
var flameproof := false
var invincible_until := 0.0
var enemies_can_touch := true

@export_enum("white", "coral", "lime", "violet") var skin := "white"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	set_skin(skin)


func set_skin(value: String) -> void:
	skin = value
	if is_node_ready():
		sprite.sprite_frames = load("res://resources/arcade/bomber_%s.tres" % skin)
		sprite.play("idle_front")


func celebrate() -> void:
	set_physics_process(false)
	sprite.play("victory")


func setup(target_grid: Grid, cell_position: Vector2i) -> void:
	grid = target_grid
	position = grid.cell_center(cell_position)


func _physics_process(delta: float) -> void:
	if grid == null:
		return
	match state:
		State.ALIVE:
			update_alive(delta)
		State.DYING:
			update_dying(delta)


func update_alive(delta: float) -> void:
	var before := position
	advance(movement_candidates(delta), speed() * delta)
	moving = position != before
	if wants_bomb():
		place_bomb()
	if wants_detonate() and remote:
		detonate_oldest()
	animate_walk(delta)
	check_hazards()


func decide_direction(_delta: float) -> Vector2:
	return Vector2.ZERO


func movement_candidates(delta: float) -> Array[Vector2]:
	var dir := decide_direction(delta)
	var result: Array[Vector2] = []
	if dir != Vector2.ZERO:
		result.append(dir)
	return result


func wants_bomb() -> bool:
	return false


func wants_detonate() -> bool:
	return false


func speed() -> float:
	return SKATE_SPEED if has_skate else BASE_SPEED


func cell() -> Vector2i:
	return grid.to_cell(position)


func advance(candidates: Array[Vector2], distance: float) -> void:
	if candidates.is_empty():
		return
	facing = candidates[0]
	for dir in candidates:
		if try_move(dir, distance):
			return


func try_move(dir: Vector2, distance: float) -> bool:
	var current := cell()
	var center := grid.cell_center(current)
	var perpendicular := Vector2(absf(dir.y), absf(dir.x))
	var lane_offset := (position - center).dot(perpendicular)
	var ahead_open := is_walkable(current + Vector2i(dir))
	if absf(lane_offset) > TURN_WINDOW:
		return ahead_open and walk_to_lane(perpendicular, lane_offset, distance)
	var forward := (position - center).dot(dir)
	if not ahead_open and forward >= 0.0:
		return false
	var step := distance if ahead_open else minf(distance, -forward)
	position += dir * step - perpendicular * lane_offset
	facing = dir
	return true


func walk_to_lane(perpendicular: Vector2, lane_offset: float, distance: float) -> bool:
	var toward_lane := -perpendicular * signf(lane_offset)
	facing = toward_lane
	position += toward_lane * minf(distance, absf(lane_offset))
	return true


func apply_power_up(kind: PowerUp.Kind) -> void:
	match kind:
		PowerUp.Kind.FIRE:
			fire_range = mini(fire_range + 1, Game.MAX_FIRE)
		PowerUp.Kind.BOMB:
			bombs_max = mini(bombs_max + 1, Game.MAX_BOMBS)
		PowerUp.Kind.SPEED:
			has_skate = true
		PowerUp.Kind.WALL_PASS:
			wall_pass = true
		PowerUp.Kind.BOMB_PASS:
			bomb_pass = true
		PowerUp.Kind.DETONATOR:
			remote = true
		PowerUp.Kind.FLAMEPROOF:
			flameproof = true
		PowerUp.Kind.MYSTERY:
			grant_invincibility()


func is_walkable(target: Vector2i) -> bool:
	return grid.is_walkable(target, wall_pass, bomb_pass, self)


func place_bomb() -> void:
	if active_bomb_count() >= bombs_max:
		return
	grid.place_bomb(cell(), self, fire_range, remote)


func active_bomb_count() -> int:
	var count := 0
	for bomb: Bomb in grid.bombs.values():
		if bomb.owner_actor == self:
			count += 1
	return count


func detonate_oldest() -> void:
	var bomb := grid.oldest_bomb_for(self)
	if bomb != null:
		grid.detonate(bomb)


func animate_walk(_delta: float) -> void:
	var direction := "front"
	if facing == Vector2.UP:
		direction = "back"
	elif facing == Vector2.RIGHT:
		direction = "right"
	elif facing == Vector2.LEFT:
		direction = "left"
	sprite.play(("walk_" if moving else "idle_") + direction)
	sprite.self_modulate = blink_color() if is_invincible() else Color.WHITE
	collision_mask = 1 | (0 if wall_pass else 2) | (0 if bomb_pass else 16)


func blink_color() -> Color:
	return Color(1.0, 1.0, 0.6) if int(Time.get_ticks_msec() / 80.0) % 2 == 0 else Color.WHITE


func is_invincible() -> bool:
	return Time.get_ticks_msec() / 1000.0 < invincible_until


func grant_invincibility() -> void:
	invincible_until = Time.get_ticks_msec() / 1000.0 + INVINCIBLE_SECONDS


func check_hazards() -> void:
	if is_invincible():
		return
	if grid.is_burning(cell()) and not flameproof:
		die()
		return
	if not enemies_can_touch:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_alive() and enemy.position.distance_to(position) < ENEMY_TOUCH_DISTANCE:
			die()
			return


func die() -> void:
	if state != State.ALIVE:
		return
	state = State.DYING
	death_clock = 0.0
	moving = false
	sprite.self_modulate = Color.WHITE
	sprite.play("death")
	$CollisionShape2D.set_deferred("disabled", true)
	Audio.play_sfx("death")
	death_started.emit()


func update_dying(delta: float) -> void:
	death_clock += delta
	if death_clock >= DEATH_SECONDS:
		state = State.DEAD
		sprite.visible = false
		died.emit()


func is_alive() -> bool:
	return state == State.ALIVE
