extends Camera2D

const HUD_HEIGHT := 140.0
const FOOTER_HEIGHT := 56.0
var arena_size := Vector2.ZERO
var follow_target: Node2D


func frame_whole(size_pixels: Vector2) -> void:
	arena_size = size_pixels
	zoom = Vector2.ONE
	position_smoothing_enabled = false
	update_frame()


func _process(_delta: float) -> void:
	update_frame()


func update_frame() -> void:
	var viewport := get_viewport_rect().size
	var available := viewport - Vector2(0, HUD_HEIGHT + FOOTER_HEIGHT)
	var focus := follow_target.position if is_instance_valid(follow_target) else Vector2(96, 96)
	var center := arena_size * 0.5
	if available.x < arena_size.x:
		center.x = clampf(focus.x, available.x * 0.5, arena_size.x - available.x * 0.5)
	if available.y < arena_size.y:
		center.y = clampf(focus.y, available.y * 0.5, arena_size.y - available.y * 0.5)
	position = (center - Vector2(0, (HUD_HEIGHT - FOOTER_HEIGHT) * 0.5)).round()
