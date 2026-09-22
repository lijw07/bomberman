extends Node

const DANGER_COLOR := Color(1.0, 0.2, 0.2, 0.35)
const PATH_COLOR := Color(0.2, 0.9, 1.0, 0.9)
const BLAST_COLOR := Color(1.0, 0.8, 0.1, 0.25)
const TEXT_COLOR := Color(0.9, 1.0, 0.6)

var enabled := false
var world_layer: CanvasLayer
var overlay: Node2D
var panel: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world_layer = CanvasLayer.new()
	world_layer.layer = 20
	world_layer.follow_viewport_enabled = true
	overlay = Node2D.new()
	overlay.draw.connect(draw_overlay)
	world_layer.add_child(overlay)
	add_child(world_layer)
	var text_layer := CanvasLayer.new()
	text_layer.layer = 21
	panel = Label.new()
	panel.position = Vector2(4, 36)
	panel.add_theme_font_override("font", load("res://assets/fonts/PressStart2P-Regular.ttf"))
	panel.add_theme_font_size_override("font_size", 8)
	panel.add_theme_color_override("font_color", TEXT_COLOR)
	panel.add_theme_color_override("font_shadow_color", Color.BLACK)
	panel.add_theme_constant_override("shadow_offset_x", 1)
	panel.add_theme_constant_override("shadow_offset_y", 1)
	text_layer.add_child(panel)
	add_child(text_layer)
	set_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		set_enabled(not enabled)
	if not enabled:
		return
	if event.is_action_pressed("debug_kill_all"):
		kill_all()
	elif event.is_action_pressed("debug_power_up"):
		max_out_player()
	elif event.is_action_pressed("debug_invincible"):
		toggle_invincible()
	elif event.is_action_pressed("debug_skip"):
		skip()


func set_enabled(value: bool) -> void:
	enabled = value
	world_layer.visible = value
	panel.visible = value


func _process(_delta: float) -> void:
	if not enabled:
		return
	overlay.queue_redraw()
	panel.text = build_report()
	panel.position.y = get_viewport().get_visible_rect().size.y - panel.size.y - 4


func scene() -> Node:
	return get_tree().current_scene


func scene_grid() -> Grid:
	var current := scene()
	if current != null and current.get("grid") is Grid:
		return current.grid
	return null


func bombers() -> Array:
	var current := scene()
	if current == null:
		return []
	if current.get("bombers") != null:
		return current.bombers
	if current.get("player") is Bomber:
		return [current.player]
	return []


func draw_overlay() -> void:
	var grid := scene_grid()
	if grid == null:
		return
	for bomb: Bomb in grid.bombs.values():
		for entry: Dictionary in grid.blast_cells(bomb.cell, bomb.fire_range).flames:
			overlay.draw_rect(cell_rect(entry.cell), BLAST_COLOR)
	for bomber in bombers():
		if bomber is AiBomber and bomber.is_alive():
			draw_ai(grid, bomber)


func draw_ai(grid: Grid, ai: AiBomber) -> void:
	var danger := ai.build_danger(Vector2i(-1, -1), 0)
	for burning: Vector2i in danger:
		overlay.draw_rect(cell_rect(burning), DANGER_COLOR)
	var previous := ai.position
	for step: Vector2i in ai.path:
		var next := grid.cell_center(step)
		overlay.draw_line(previous, next, PATH_COLOR, 1.0)
		previous = next
	if not ai.path.is_empty():
		overlay.draw_circle(previous, 2.0, PATH_COLOR)
	overlay.draw_string(panel.get_theme_font("font"), ai.position + Vector2(-40, -10), ai.profile.name, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, TEXT_COLOR)


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * Grid.TILE, Vector2(Grid.TILE, Grid.TILE))


func build_report() -> String:
	var lines: Array[String] = ["DEBUG  FPS %d" % Engine.get_frames_per_second()]
	var grid := scene_grid()
	if grid != null:
		lines.append("bombs %d flames %d" % [grid.bombs.size(), grid.flames.size()])
	for bomber in bombers():
		lines.append(describe(bomber))
	lines.append("F3 hide  F5 kill all  F6 max power")
	lines.append("F7 invincible  F8 skip")
	return "\n".join(lines)


func describe(bomber: Bomber) -> String:
	var label: String = bomber.profile.name if bomber is AiBomber else "player"
	var flags := ""
	if bomber.has_skate:
		flags += "S"
	if bomber.wall_pass:
		flags += "W"
	if bomber.bomb_pass:
		flags += "P"
	if bomber.remote:
		flags += "R"
	if bomber.flameproof:
		flags += "F"
	var state := "alive" if bomber.is_alive() else "dead"
	var extra := ""
	if bomber is AiBomber:
		extra = " path %d idle %.1f" % [bomber.path.size(), bomber.idle_clock]
	return "%s %s %s f%d b%d %s%s" % [label, state, bomber.cell(), bomber.fire_range, bomber.bombs_max, flags, extra]


func kill_all() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.die()
	for bomber in bombers():
		if bomber is AiBomber:
			bomber.die()


func max_out_player() -> void:
	for bomber in bombers():
		if bomber is Player:
			for kind in [PowerUp.Kind.FIRE, PowerUp.Kind.FIRE, PowerUp.Kind.FIRE, PowerUp.Kind.BOMB, PowerUp.Kind.BOMB, PowerUp.Kind.SPEED, PowerUp.Kind.WALL_PASS, PowerUp.Kind.BOMB_PASS, PowerUp.Kind.DETONATOR]:
				bomber.apply_power_up(kind)


func toggle_invincible() -> void:
	for bomber in bombers():
		if bomber is Player:
			bomber.invincible_until = 0.0 if bomber.is_invincible() else INF


func skip() -> void:
	var current := scene()
	if current != null and current.has_method("clear_stage"):
		current.clear_stage()
	elif current != null and current.has_method("end_round"):
		current.end_round()
