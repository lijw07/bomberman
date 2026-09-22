class_name Grid
extends Node2D

signal brick_destroyed(cell: Vector2i)
signal bomb_exploded(bomb: Bomb, cells: Array[Vector2i])

const TILE := 64
const HALF_TILE := 32.0
const ATLAS_FLOOR := Vector2i(0, 0)
const ATLAS_WALL := Vector2i(1, 0)
const ATLAS_PILLAR := Vector2i(1, 0)
const ATLAS_BRICK := Vector2i(2, 0)
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

const BombScene := preload("res://scenes/entities/bomb.tscn")
const FlameScene := preload("res://scenes/entities/flame.tscn")
const BrickBreakScene := preload("res://scenes/effects/brick_break.tscn")
const TILES_TEXTURE := preload("res://assets/arcade/sprites/terrain.png")

var data: LevelData
var bombs: Dictionary = {}
var flames: Dictionary = {}
var obstacles: Dictionary = {}

const StoneScene := preload("res://scenes/arcade/terrain/stone.tscn")
const BrickScene := preload("res://scenes/arcade/terrain/brick.tscn")
const VineScene := preload("res://scenes/arcade/terrain/vine_stone.tscn")

@onready var floor_layer: TileMapLayer = $Floor
@onready var bricks_layer: TileMapLayer = $Bricks
@onready var entities: Node2D = $Entities


static func make_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = TILES_TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	for i in 8:
		source.create_tile(Vector2i(i, 0))
	tileset.add_source(source, 0)
	return tileset


func build(level: LevelData) -> void:
	data = level
	bombs.clear()
	flames.clear()
	obstacles.clear()
	for child in entities.get_children():
		child.queue_free()
	var tileset := make_tileset()
	floor_layer.tile_set = tileset
	bricks_layer.tile_set = tileset
	floor_layer.clear()
	bricks_layer.clear()
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			floor_layer.set_cell(cell, 0, ATLAS_FLOOR)
			if data.get_cell(cell) != LevelData.Cell.FLOOR:
				add_obstacle(cell, data.is_brick(cell))


func add_obstacle(cell: Vector2i, brick: bool) -> void:
	var packed: PackedScene = BrickScene if brick else (VineScene if (cell.x + cell.y) % 13 == 0 else StoneScene)
	var obstacle: StaticBody2D = packed.instantiate()
	obstacle.position = cell_center(cell)
	entities.add_child(obstacle)
	obstacles[cell] = obstacle


func remove_obstacle(cell: Vector2i) -> void:
	var obstacle: Node = obstacles.get(cell)
	if is_instance_valid(obstacle):
		obstacle.queue_free()
	obstacles.erase(cell)


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(HALF_TILE, HALF_TILE)


func to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


func is_walkable(cell: Vector2i, wall_pass := false, bomb_pass := false, actor: Node2D = null) -> bool:
	if not data.is_passable(cell, wall_pass):
		return false
	var bomb: Bomb = bombs.get(cell)
	if bomb == null:
		return true
	return bomb_pass or (bomb.owner_actor == actor and not bomb.solid)


func is_burning(cell: Vector2i) -> bool:
	return flames.get(cell, 0) > 0


func has_bomb(cell: Vector2i) -> bool:
	return bombs.has(cell)


func place_bomb(cell: Vector2i, placer: Node2D, fire_range: int, remote: bool) -> Bomb:
	if bombs.has(cell) or not data.is_passable(cell):
		return null
	var bomb: Bomb = BombScene.instantiate()
	bomb.setup(self, cell, placer, fire_range, remote)
	bomb.position = cell_center(cell)
	entities.add_child(bomb)
	bombs[cell] = bomb
	Audio.play_sfx("bomb_place")
	return bomb


func oldest_bomb_for(placer: Node2D) -> Bomb:
	var oldest: Bomb = null
	for bomb: Bomb in bombs.values():
		if bomb.owner_actor != placer:
			continue
		if oldest == null or bomb.placed_at < oldest.placed_at:
			oldest = bomb
	return oldest


func detonate(bomb: Bomb) -> void:
	if bomb.exploded:
		return
	bomb.exploded = true
	bombs.erase(bomb.cell)
	var blast := blast_cells(bomb.cell, bomb.fire_range)
	var burned: Array[Vector2i] = []
	for entry: Dictionary in blast.flames:
		spawn_flame(entry.cell, entry.kind, entry.dir)
		burned.append(entry.cell)
	for brick_cell: Vector2i in blast.bricks:
		destroy_brick(brick_cell)
	bomb.queue_free()
	Audio.play_sfx("explosion")
	bomb_exploded.emit(bomb, burned)
	for other: Bomb in blast.bombs:
		detonate(other)


func blast_cells(origin: Vector2i, fire_range: int) -> Dictionary:
	var result := {
		"flames": [{"cell": origin, "kind": Flame.Kind.CENTER, "dir": Vector2i.RIGHT}],
		"bricks": [],
		"bombs": [],
	}
	for dir in DIRECTIONS:
		var last_index := -1
		for step in range(1, fire_range + 1):
			var cell := origin + dir * step
			var cell_type := data.get_cell(cell)
			if cell_type == LevelData.Cell.WALL or cell_type == LevelData.Cell.PILLAR:
				break
			if cell_type == LevelData.Cell.BRICK:
				result.bricks.append(cell)
				break
			if bombs.has(cell):
				result.bombs.append(bombs[cell])
				break
			result.flames.append({"cell": cell, "kind": Flame.Kind.ARM, "dir": dir})
			last_index = result.flames.size() - 1
		if last_index >= 0:
			result.flames[last_index].kind = Flame.Kind.TIP
	return result


func spawn_flame(cell: Vector2i, kind: Flame.Kind, dir: Vector2i) -> void:
	var flame: Flame = FlameScene.instantiate()
	flame.setup(self, cell, kind, dir)
	flame.position = cell_center(cell)
	entities.add_child(flame)


func register_flame(cell: Vector2i) -> void:
	flames[cell] = flames.get(cell, 0) + 1


func unregister_flame(cell: Vector2i) -> void:
	var count: int = flames.get(cell, 0) - 1
	if count <= 0:
		flames.erase(cell)
	else:
		flames[cell] = count


func destroy_brick(cell: Vector2i) -> void:
	if not data.is_brick(cell):
		return
	data.set_cell(cell, LevelData.Cell.FLOOR)
	remove_obstacle(cell)
	var effect: Node2D = BrickBreakScene.instantiate()
	effect.position = cell_center(cell)
	entities.add_child(effect)
	brick_destroyed.emit(cell)


func drop_block(cell: Vector2i) -> void:
	data.set_cell(cell, LevelData.Cell.WALL)
	remove_obstacle(cell)
	add_obstacle(cell, false)
	var bomb: Bomb = bombs.get(cell)
	if bomb != null:
		bombs.erase(cell)
		bomb.queue_free()


func open_directions(cell: Vector2i, wall_pass := false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if is_walkable(cell + dir, wall_pass):
			result.append(dir)
	return result


func line_is_clear(from: Vector2i, to: Vector2i, wall_pass := false) -> bool:
	var delta := to - from
	if delta.x != 0 and delta.y != 0:
		return false
	var dir := delta.sign()
	var cell := from + dir
	while cell != to:
		if not is_walkable(cell, wall_pass):
			return false
		cell += dir
	return true
