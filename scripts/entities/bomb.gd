class_name Bomb
extends StaticBody2D

const FUSE_SECONDS := 2.65
const REMOTE_FUSE_SECONDS := 8.0
const OWNER_CLEARANCE := Grid.HALF_TILE + Bomber.HALF_HITBOX

var grid: Grid
var cell := Vector2i.ZERO
var owner_actor: Node2D
var fire_range := 1
var remote := false
var solid := false
var exploded := false
var placed_at := 0
var fuse := FUSE_SECONDS

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(target_grid: Grid, target_cell: Vector2i, placer: Node2D, range_value: int, is_remote: bool) -> void:
	grid = target_grid
	cell = target_cell
	owner_actor = placer
	fire_range = range_value
	remote = is_remote
	fuse = REMOTE_FUSE_SECONDS if remote else FUSE_SECONDS
	placed_at = Time.get_ticks_msec()


func _process(delta: float) -> void:
	if grid == null:
		return
	if not solid and owner_has_left():
		solid = true
	fuse -= delta
	if fuse <= 0.0:
		grid.detonate(self)




func owner_has_left() -> bool:
	if owner_actor == null or not is_instance_valid(owner_actor):
		return true
	var offset := (owner_actor.position - position).abs()
	return offset.x >= OWNER_CLEARANCE or offset.y >= OWNER_CLEARANCE
