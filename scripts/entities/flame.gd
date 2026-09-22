class_name Flame
extends Area2D

enum Kind { CENTER, ARM, TIP }

const LIFETIME := 0.6

var grid: Grid
var cell := Vector2i.ZERO
@export var kind := Kind.CENTER
var clock := 0.0
var registered := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(target_grid: Grid, target_cell: Vector2i, flame_kind: Kind, dir: Vector2i) -> void:
	grid = target_grid
	cell = target_cell
	kind = flame_kind
	rotation = Vector2(dir).angle()


func _ready() -> void:
	sprite.play(["center", "arm", "tip"][kind])
	if grid != null:
		grid.register_flame(cell)
		registered = true


func _process(delta: float) -> void:
	if grid == null:
		return
	clock += delta
	if registered and clock >= LIFETIME - 0.075:
		grid.unregister_flame(cell)
		registered = false
		$CollisionShape2D.set_deferred("disabled", true)
	if clock >= LIFETIME:
		queue_free()


func _exit_tree() -> void:
	if registered and is_instance_valid(grid):
		grid.unregister_flame(cell)
