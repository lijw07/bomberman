extends Node2D

@export var animation_name: StringName = &"break"
@export var repeat_preview := false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play(animation_name)
	sprite.animation_finished.connect(_finished)


func _finished() -> void:
	if repeat_preview:
		sprite.play(animation_name)
	else:
		queue_free()
