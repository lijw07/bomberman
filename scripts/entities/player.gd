class_name Player
extends Bomber

var vertical_priority := false


func movement_candidates(_delta: float) -> Array[Vector2]:
	var horizontal := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("move_up", "move_down")
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		vertical_priority = true
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		vertical_priority = false
	var result: Array[Vector2] = []
	if horizontal != 0.0:
		result.append(Vector2(signf(horizontal), 0.0))
	if vertical != 0.0:
		var vertical_dir := Vector2(0.0, signf(vertical))
		if vertical_priority:
			result.push_front(vertical_dir)
		else:
			result.append(vertical_dir)
	return result


func wants_bomb() -> bool:
	return Input.is_action_just_pressed("place_bomb")


func wants_detonate() -> bool:
	return Input.is_action_just_pressed("detonate")
