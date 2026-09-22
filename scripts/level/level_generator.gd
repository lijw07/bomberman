class_name LevelGenerator
extends RefCounted

const CAMPAIGN_WIDTH := 31
const CAMPAIGN_HEIGHT := 13
const BATTLE_WIDTH := 15
const BATTLE_HEIGHT := 13
const BASE_BRICKS := 54
const BRICKS_PER_LEVEL := 2
const SPAWN_ARM_LENGTH := 2
const MIN_ENEMY_DISTANCE := 6
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]


static func campaign(level: int, seed_text: String, attempt: int) -> LevelData:
	var data := LevelData.new(CAMPAIGN_WIDTH, CAMPAIGN_HEIGHT)
	data.level = level
	data.seed_value = stream_seed(seed_text, level, attempt, "layout")
	data.spawns = [Vector2i(1, 1)]
	build_lattice(data)
	var layout_rng := make_rng(data.seed_value)
	var brick_count := BASE_BRICKS + BRICKS_PER_LEVEL * (level - 1)
	place_bricks(data, brick_count, layout_rng)
	var item_rng := make_rng(stream_seed(seed_text, level, attempt, "items"))
	place_hidden_objects(data, item_rng)
	var enemy_rng := make_rng(stream_seed(seed_text, level, attempt, "enemies"))
	place_enemies(data, roll_enemy_types(level, enemy_rng), enemy_rng)
	return data


static func battle(seed_text: String, round_index: int, density: float) -> LevelData:
	var data := LevelData.new(BATTLE_WIDTH, BATTLE_HEIGHT)
	data.seed_value = stream_seed(seed_text, round_index, 0, "battle")
	data.spawns = [
		Vector2i(1, 1),
		Vector2i(BATTLE_WIDTH - 2, BATTLE_HEIGHT - 2),
		Vector2i(BATTLE_WIDTH - 2, 1),
		Vector2i(1, BATTLE_HEIGHT - 2),
	]
	build_lattice(data)
	place_bricks_symmetric(data, density, make_rng(data.seed_value))
	return data


static func stream_seed(seed_text: String, level: int, attempt: int, stream: String) -> int:
	return hash("%s|%d|%d|%s" % [seed_text, level, attempt, stream])


static func make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func build_lattice(data: LevelData) -> void:
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			if x == 0 or y == 0 or x == data.width - 1 or y == data.height - 1:
				data.set_cell(cell, LevelData.Cell.WALL)
			elif x % 2 == 0 and y % 2 == 0:
				data.set_cell(cell, LevelData.Cell.PILLAR)
			else:
				data.set_cell(cell, LevelData.Cell.FLOOR)


static func protected_cells(data: LevelData) -> Dictionary:
	var result := {}
	for spawn in data.spawns:
		result[spawn] = true
		for dir in DIRECTIONS:
			for step in range(1, SPAWN_ARM_LENGTH + 1):
				result[spawn + dir * step] = true
	return result


static func candidate_cells(data: LevelData) -> Array[Vector2i]:
	var protected := protected_cells(data)
	var result: Array[Vector2i] = []
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			if data.get_cell(cell) == LevelData.Cell.FLOOR and not protected.has(cell):
				result.append(cell)
	return result


static func place_bricks(data: LevelData, count: int, rng: RandomNumberGenerator) -> void:
	var candidates := candidate_cells(data)
	shuffle(candidates, rng)
	for i in mini(count, candidates.size()):
		data.set_cell(candidates[i], LevelData.Cell.BRICK)


static func place_bricks_symmetric(data: LevelData, density: float, rng: RandomNumberGenerator) -> void:
	var protected := protected_cells(data)
	var half_w := int((data.width + 1) / 2.0)
	var half_h := int((data.height + 1) / 2.0)
	for y in range(1, half_h):
		for x in range(1, half_w):
			var cell := Vector2i(x, y)
			if data.get_cell(cell) != LevelData.Cell.FLOOR or rng.randf() >= density:
				continue
			for mirrored in mirror_cells(cell, data):
				if not protected.has(mirrored):
					data.set_cell(mirrored, LevelData.Cell.BRICK)


static func mirror_cells(cell: Vector2i, data: LevelData) -> Array[Vector2i]:
	var mx := data.width - 1 - cell.x
	var my := data.height - 1 - cell.y
	return [cell, Vector2i(mx, cell.y), Vector2i(cell.x, my), Vector2i(mx, my)]


static func place_hidden_objects(data: LevelData, rng: RandomNumberGenerator) -> void:
	var bricks := data.brick_cells()
	if bricks.is_empty():
		return
	var distances := bfs_distances(data, data.spawns[0], true)
	var min_distance := int(maxi(data.width, data.height) / 4.0)
	var far_bricks := bricks.filter(func(c: Vector2i) -> bool: return distances.get(c, 0) >= min_distance)
	if far_bricks.is_empty():
		far_bricks = bricks
	data.item_cell = far_bricks[rng.randi_range(0, far_bricks.size() - 1)]
	data.item_type = PowerUp.for_level(data.level)


static func enemy_count(level: int) -> int:
	return clampi(6 + int(level / 8.0), 6, 10)


static func roll_enemy_types(level: int, rng: RandomNumberGenerator) -> Array[String]:
	var pool := EnemyTypes.available_for_level(level)
	var weights: Array[float] = []
	var total := 0.0
	for type_name in pool:
		var w := EnemyTypes.weight_for_level(type_name, level)
		weights.append(w)
		total += w
	var result: Array[String] = []
	for i in enemy_count(level):
		var roll := rng.randf() * total
		var picked := pool[pool.size() - 1]
		for j in pool.size():
			roll -= weights[j]
			if roll <= 0.0:
				picked = pool[j]
				break
		result.append(picked)
	return result


static func place_enemies(data: LevelData, types: Array[String], rng: RandomNumberGenerator) -> void:
	var distances := bfs_distances(data, data.spawns[0], true)
	var open: Array[Vector2i] = []
	for cell in distances:
		var far: bool = distances[cell] >= MIN_ENEMY_DISTANCE
		if far and data.get_cell(cell) == LevelData.Cell.FLOOR and not is_pocket(data, cell):
			open.append(cell)
	shuffle(open, rng)
	for i in mini(types.size(), open.size()):
		data.enemies.append({"type": types[i], "cell": open[i]})


static func is_pocket(data: LevelData, cell: Vector2i) -> bool:
	for dir in DIRECTIONS:
		if data.is_passable(cell + dir):
			return false
	return true


static func bfs_distances(data: LevelData, start: Vector2i, through_bricks: bool) -> Dictionary:
	var distances := {start: 0}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		for dir in DIRECTIONS:
			var next := current + dir
			if distances.has(next) or not data.is_passable(next, through_bricks):
				continue
			distances[next] = distances[current] + 1
			queue.append(next)
	return distances


static func shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
