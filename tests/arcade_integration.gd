extends Node

@onready var root: Window = get_tree().root

var checks := 0
var failures: Array[String] = []
var gameplay_completed := false


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/arcade/manifest.json"))
	var coverage := {}
	var clips := 0
	var frames := 0
	for asset: Dictionary in manifest.assets:
		var texture: Texture2D = load("res://assets/arcade/" + asset.file)
		check(texture != null, "Texture loads: " + asset.name)
		var imported := texture.get_image()
		if imported.is_compressed():
			imported.decompress()
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/arcade/" + asset.file))
		check(imported.get_size() == source.get_size(), "Native texture dimensions: " + asset.name)
		var exact := true
		for y in source.get_height():
			for x in source.get_width():
				var expected := source.get_pixel(x, y)
				var actual := imported.get_pixel(x, y)
				if actual.a != expected.a or (expected.a > 0.0 and actual != expected):
					exact = false
		check(exact, "Imported pixel fidelity: " + asset.name)
		if asset.tags.is_empty():
			continue
		var animation: SpriteFrames = load("res://resources/arcade/" + asset.name + ".tres")
		for tag: Array in asset.tags:
			clips += 1
			var count := int(tag[2] - tag[1] + 1)
			frames += count
			check(animation.get_frame_count(tag[0]) == count, "Full clip count: " + asset.name + "/" + tag[0])
			check(absf(1.0 / animation.get_animation_speed(tag[0]) - asset.seconds) < 0.00001, "Source timing: " + asset.name + "/" + tag[0])
			check(animation.get_animation_loop(tag[0]) == not (tag[0] in ["death", "break", "disappear", "center", "arm", "tip"]), "Loop policy: " + asset.name + "/" + tag[0])
			for i in count:
				var tex: AtlasTexture = animation.get_frame_texture(tag[0], i)
				var source_frame := int(tag[1]) - 1 + i
				check(tex.region == Rect2((source_frame % int(asset.columns)) * asset.width, floori(source_frame / asset.columns) * asset.height, asset.width, asset.height), "Atlas frame: " + asset.name + "/" + tag[0])
	check(clips == 87 and frames == 632, "Complete animation coverage")
	for record: Dictionary in manifest.scenes:
		coverage[record.asset] = true
		var packed: PackedScene = load(record.scene)
		check(packed != null and packed.can_instantiate(), "Scene loads: " + record.scene)
		var node := packed.instantiate()
		if record.collision.has("size"):
			check(node is CollisionObject2D, "Physics root: " + record.scene)
			check(node.get_node("CollisionShape2D").shape.size == Vector2(record.collision.size[0], record.collision.size[1]), "Collision size: " + record.scene)
			check(node.collision_layer == int(record.collision.layer) and node.collision_mask == int(record.collision.mask), "Collision layers: " + record.scene)
		root.add_child(node)
		await get_tree().process_frame
		node.free()
	check(coverage.size() == 32, "Every sheet has a scene")
	await check_gameplay()
	check(gameplay_completed, "Gameplay checks reached completion")
	root.get_node("Audio").silence()
	for player: AudioStreamPlayer in root.get_node("Audio").sfx_players:
		player.stream = null
	await get_tree().create_timer(0.2).timeout
	var result := {"checks": checks, "failures": failures, "assets": 32, "asset_scenes": manifest.scenes.size(), "animation_clips": clips, "animated_frames": frames, "status": "PASS" if failures.is_empty() else "FAIL"}
	var output := FileAccess.open("res://art-review/integration-v11/test-results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
	print("ARCADE_INTEGRATION ", JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)


func query(position: Vector2, mask: int, areas := false) -> Array[Dictionary]:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = position
	params.collision_mask = mask
	params.collide_with_areas = areas
	params.collide_with_bodies = not areas
	return root.world_2d.direct_space_state.intersect_point(params)


func check_gameplay() -> void:
	var grid: Grid = load("res://scenes/level/grid.tscn").instantiate()
	root.add_child(grid)
	var data := LevelData.new(7, 7)
	LevelGenerator.build_lattice(data)
	data.set_cell(Vector2i(3, 1), LevelData.Cell.BRICK)
	grid.build(data)
	var player: Player = load("res://scenes/entities/player.tscn").instantiate()
	player.setup(grid, Vector2i(1, 1))
	grid.entities.add_child(player)
	player.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(Grid.TILE == 64, "Approved grid size")
	check(not query(grid.cell_center(Vector2i(0, 1)), 1).is_empty(), "Solid wall physics shape present")
	check(not query(grid.cell_center(Vector2i(3, 1)), 2).is_empty(), "Breakable brick physics shape present")
	check(query(grid.cell_center(Vector2i(1, 1)), 1 | 2).is_empty(), "Floor has no blocking collision")
	check(not player.try_move(Vector2.LEFT, 12), "Cannot move through boundary wall")
	check(player.try_move(Vector2.RIGHT, 64), "Moves one native tile in clear lane")
	check(player.position == grid.cell_center(Vector2i(2, 1)), "Actor keeps tile anchor")
	check(not player.try_move(Vector2.RIGHT, 64), "Cannot pass a brick")
	player.wall_pass = true
	check(player.try_move(Vector2.RIGHT, 64), "Wall-pass powerup preserves movement rule")
	player.wall_pass = false
	player.position = grid.cell_center(Vector2i(1, 1))
	var bomb := grid.place_bomb(Vector2i(1, 1), player, 3, false)
	bomb.set_process(false)
	check(grid.is_walkable(Vector2i(1, 1), false, false, player), "Bomb owner can leave newly placed bomb")
	player.try_move(Vector2.DOWN, 64)
	check(bomb.owner_has_left(), "Bomb detects owner departure at native scale")
	bomb.solid = true
	check(not grid.is_walkable(Vector2i(1, 1), false, false, player), "Solid bomb blocks return")
	check(grid.is_walkable(Vector2i(1, 1), false, true, player), "Bomb-pass remains functional")
	await get_tree().physics_frame
	check(not query(bomb.position, 16).is_empty(), "Bomb physics shape present")
	var pickup: PowerUp = load("res://scenes/arcade/pickups/remote.tscn").instantiate()
	pickup.position = player.position
	grid.entities.add_child(pickup)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not query(pickup.position, 32, true).is_empty(), "Pickup detection area present")
	check(pickup.overlaps_body(player), "Pickup area detects bomber footprint")
	player.apply_power_up(pickup.kind)
	check(player.remote, "Pickup applies its matching powerup")
	var blast := grid.blast_cells(Vector2i(1, 1), 3)
	check(Vector2i(3, 1) in blast.bricks, "Blast reaches and stops at brick")
	grid.detonate(bomb)
	check(not data.is_brick(Vector2i(3, 1)), "Destruction removes brick from grid")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(query(grid.cell_center(Vector2i(3, 1)), 2).is_empty(), "Destruction removes brick collider")
	check(grid.is_burning(Vector2i(1, 1)), "Flame is registered")
	check(not query(grid.cell_center(Vector2i(1, 1)), 64, true).is_empty(), "Flame detection shape present")
	await get_tree().create_timer(0.55).timeout
	check(not grid.is_burning(Vector2i(1, 1)), "No invisible hazard on final transparent flame frame")
	await get_tree().create_timer(0.15).timeout
	check(grid.flames.is_empty(), "Flame areas and registration expire together")
	grid.drop_block(Vector2i(3, 1))
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not query(grid.cell_center(Vector2i(3, 1)), 1).is_empty(), "Pressure block creates solid collision")
	player.set_skin("violet")
	check(player.sprite.sprite_frames.resource_path.ends_with("bomber_violet.tres"), "Uses authored color art without tint")
	player.celebrate()
	check(player.sprite.animation == &"victory", "Victory clip connected")
	player.die()
	check(player.sprite.animation == &"death", "Death clip connected")
	player.update_dying(0.8)
	check(player.state == Bomber.State.DEAD, "Death completes after authored duration")
	grid.free()
	gameplay_completed = true
