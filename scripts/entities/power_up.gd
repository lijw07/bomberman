class_name PowerUp
extends Area2D

enum Kind { FIRE, BOMB, SPEED, WALL_PASS, BOMB_PASS, DETONATOR, FLAMEPROOF, MYSTERY }

const CYCLE: Array[Kind] = [
	Kind.FIRE, Kind.BOMB, Kind.DETONATOR, Kind.SPEED, Kind.BOMB, Kind.BOMB, Kind.FIRE, Kind.DETONATOR,
	Kind.BOMB_PASS, Kind.WALL_PASS, Kind.BOMB, Kind.BOMB, Kind.DETONATOR, Kind.BOMB_PASS, Kind.FIRE,
	Kind.WALL_PASS, Kind.BOMB, Kind.BOMB_PASS, Kind.BOMB, Kind.DETONATOR, Kind.BOMB_PASS, Kind.DETONATOR,
	Kind.BOMB, Kind.DETONATOR, Kind.BOMB_PASS, Kind.MYSTERY, Kind.FIRE, Kind.BOMB, Kind.DETONATOR, Kind.FLAMEPROOF,
]

@export var kind := Kind.FIRE
@export var cell := Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D


static func for_level(level: int) -> Kind:
	return CYCLE[(level - 1) % CYCLE.size()]


func _ready() -> void:
	add_to_group("powerups")
	sprite.frame = kind
