extends Node

var live: Node
var output := "res://art-review/integration-v11/"
var assertions := 0


func _ready() -> void:
	call_deferred("run")


func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	frame.save_png(output + name + ".png")
	print("CAPTURE ", name)


func load_live(path: String) -> void:
	if is_instance_valid(live):
		live.free()
	live = load(path).instantiate()
	add_child(live)
	await get_tree().process_frame


func run() -> void:
	if "--gallery-only" in OS.get_cmdline_user_args():
		await load_live("res://scenes/arcade/asset_gallery.tscn")
		await capture("13-asset-gallery")
		live.free()
		Audio.silence()
		await get_tree().create_timer(0.2).timeout
		get_tree().quit()
		return
	get_window().size = Vector2i(1024, 768)
	await load_live("res://scenes/ui/main_menu.tscn")
	await capture("01-menu")
	live.show_screen("setup")
	await capture("02-setup")
	live.change_opponents(-1)
	assert(live.opponents == 2)
	assertions += 1
	live.show_screen("help")
	await capture("03-help")
	Game.seed_text = "arcade-integration"
	Game.mode = Game.Mode.CAMPAIGN
	await load_live("res://scenes/stage/stage.tscn")
	await get_tree().create_timer(2.4).timeout
	assert(live.running and live.player != null)
	assertions += 1
	live.player.enemies_can_touch = false
	live.player.flameproof = true
	await capture("04-campaign")
	Input.action_press("move_right")
	await get_tree().create_timer(0.30).timeout
	Input.action_release("move_right")
	assert(live.player.position.x > 96)
	assertions += 1
	Input.action_press("place_bomb")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("place_bomb")
	await capture("05-bomb-and-walk")
	var pause_event := InputEventAction.new()
	pause_event.action = &"ui_cancel"
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	await get_tree().process_frame
	assert(get_tree().paused)
	assertions += 1
	await capture("06-pause")
	pause_event = InputEventAction.new()
	pause_event.action = &"ui_cancel"
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	await get_tree().process_frame
	assert(not get_tree().paused)
	assertions += 1
	live.player.position = live.grid.cell_center(Vector2i(1, 1))
	live.player.fire_range = 4
	var bomb: Bomb = live.grid.place_bomb(Vector2i(1, 1), live.player, 4, false)
	if bomb != null:
		live.grid.detonate(bomb)
	await get_tree().create_timer(0.2).timeout
	await capture("07-explosion")
	for enemy: Enemy in live.alive_enemies():
		enemy.set_physics_process(false)
	live.clear_stage()
	await get_tree().create_timer(1.4).timeout
	await capture("08-stage-clear")
	Game.mode = Game.Mode.BATTLE
	Game.battle_wins = [0, 0, 0, 0]
	Game.battle_opponents = 3
	await load_live("res://scenes/battle/battle.tscn")
	await get_tree().create_timer(2.2).timeout
	assert(live.bombers.size() == 4)
	assertions += 1
	for bomber: Bomber in live.bombers:
		bomber.flameproof = true
	await capture("09-battle")
	get_window().size = Vector2i(1536, 1152)
	await get_tree().process_frame
	await capture("10-battle-large")
	get_window().size = Vector2i(1024, 768)
	Game.battle_wins = [2, 1, 0, 0]
	await load_live("res://scenes/ui/battle_results.tscn")
	await capture("11-results")
	await load_live("res://scenes/ui/game_over.tscn")
	await capture("12-game-over")
	await load_live("res://scenes/arcade/asset_gallery.tscn")
	await capture("13-asset-gallery")
	for i in live.records.size():
		live.show_asset(i)
		await get_tree().process_frame
	assertions += live.records.size()
	live.free()
	Audio.silence()
	print("ARCADE_VISUAL_SMOKE PASS assertions=", assertions)
	await get_tree().process_frame
	get_tree().quit()
