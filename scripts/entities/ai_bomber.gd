class_name AiBomber
extends Bomber

const NO_DANGER := 1.0e9
const SEARCH_DEPTH := 40
const BRICK_VALUE := 1.0
const MIN_BOMB_VALUE := 1.0
const ARRIVAL_EPSILON := 2.4
const REMOTE_DELAY := 0.4
const CALM_RADIUS := 4
const STUCK_SECONDS := 3.0
const SPOT_RANGE := 8
const SPOT_DISTANCE_COST := 0.35
const TRAP_VALUE := 8.0
const TRAP_REACH := 2
const ESCAPE_SEARCH_DEPTH := 4
const ITEM_RANGE := 6
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

const CROWD_DISTANCE := 2
const CROWD_PENALTY := 6.0
const TARGET_NOISE := 3.0

const PROFILES: Array[Dictionary] = [
	{
		"name": "hunter", "think_interval": 0.1, "chase_radius": 11, "opponent_value": 6.0,
		"safety_margin": 0.2, "wander_chance": 0.05, "pause_chance": 0.0, "pause_max": 0.0,
		"home_bias": 0.0, "priorities": ["opponent", "spot", "item"],
	},
	{
		"name": "miner", "think_interval": 0.2, "chase_radius": 4, "opponent_value": 2.5,
		"safety_margin": 0.5, "wander_chance": 0.1, "pause_chance": 0.15, "pause_max": 0.35,
		"home_bias": 0.6, "priorities": ["item", "spot", "opponent"],
	},
	{
		"name": "wildcard", "think_interval": 0.15, "chase_radius": 7, "opponent_value": 4.0,
		"safety_margin": 0.3, "wander_chance": 0.4, "pause_chance": 0.3, "pause_max": 0.6,
		"home_bias": 0.25, "priorities": ["spot", "opponent", "item"],
	},
]

var rng := RandomNumberGenerator.new()
var profile: Dictionary = PROFILES[0]
var opponents: Array[Bomber] = []
var direction_order: Array[Vector2i] = DIRECTIONS.duplicate()
var home := Vector2i.ZERO
var think_clock := 0.0
var pause_clock := 0.0
var remote_clock := 0.0
var idle_clock := 0.0
var path: Array[Vector2i] = []
var bomb_requested := false


func seed_brain(seed_value: int, brain_profile: Dictionary) -> void:
	rng.seed = seed_value
	profile = brain_profile
	think_clock = rng.randf_range(0.0, profile.think_interval)
	LevelGenerator.shuffle(direction_order, rng)


func setup(target_grid: Grid, cell_position: Vector2i) -> void:
	super.setup(target_grid, cell_position)
	home = cell_position


func is_walkable(target: Vector2i) -> bool:
	if not super.is_walkable(target):
		return false
	for rival in rivals():
		if rival.cell() == target:
			return false
	return true


func decide_direction(delta: float) -> Vector2:
	think_clock -= delta
	remote_clock += delta
	idle_clock = 0.0 if moving else idle_clock + delta
	if pause_clock > 0.0:
		pause_clock -= delta
		return Vector2.ZERO
	if think_clock <= 0.0 and (path.is_empty() or threatened()):
		think()
	return realign(direction_along_path())


func wants_detonate() -> bool:
	if not remote or active_bomb_count() == 0 or remote_clock < REMOTE_DELAY:
		return false
	var danger := build_danger(Vector2i(-1, -1), 0)
	return not danger.has(cell())


func realign(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return dir
	var perpendicular := Vector2(absf(dir.y), absf(dir.x))
	var lane_offset := (position - grid.cell_center(cell())).dot(perpendicular)
	if absf(lane_offset) > TURN_WINDOW:
		return -perpendicular * signf(lane_offset)
	return dir


func threatened() -> bool:
	var danger := build_danger(Vector2i(-1, -1), 0)
	if danger.has(cell()):
		return true
	return not path.is_empty() and danger.has(path[0])


func wants_bomb() -> bool:
	var requested := bomb_requested
	bomb_requested = false
	return requested


func think() -> void:
	think_clock = profile.think_interval
	var me := cell()
	var danger := build_danger(Vector2i(-1, -1), 0)
	var search := breadth_first(me)
	if danger.get(me, NO_DANGER) < NO_DANGER:
		path = path_to(search, safest_cell(me, search, danger))
		return
	if can_bomb_here(me) and bomb_value(me) >= MIN_BOMB_VALUE:
		var future := build_danger(me, fire_range)
		var escape := safe_cell(me, search, future)
		if escape == me and idle_clock > STUCK_SECONDS:
			escape = safest_cell(me, search, future)
		if escape != me:
			bomb_requested = true
			remote_clock = 0.0
			path = path_to(search, escape)
			return
	path = path_to(search, choose_target(me, search, danger))
	if rng.randf() < profile.pause_chance:
		pause_clock = rng.randf_range(0.1, profile.pause_max)


func bombs_nearby(search: Dictionary, danger: Dictionary) -> bool:
	for burning: Vector2i in danger:
		if search.dist.get(burning, SEARCH_DEPTH + 1) <= CALM_RADIUS:
			return true
	return false


func can_bomb_here(me: Vector2i) -> bool:
	var centered := position.distance_to(grid.cell_center(me)) < ARRIVAL_EPSILON
	return centered and active_bomb_count() < bombs_max and not grid.has_bomb(me)


func step_time() -> float:
	return Grid.TILE / speed()


func build_danger(extra_cell: Vector2i, extra_range: int) -> Dictionary:
	var entries: Array[Dictionary] = []
	for bomb: Bomb in grid.bombs.values():
		var time := remote_bomb_time(bomb) if bomb.remote else bomb.fuse
		entries.append({"cell": bomb.cell, "range": bomb.fire_range, "time": time})
	if extra_range > 0:
		entries.append({"cell": extra_cell, "range": extra_range, "time": Bomb.FUSE_SECONDS})
	var blasts: Array[Array] = []
	for entry in entries:
		blasts.append(blast_area(entry.cell, entry.range, extra_cell))
	resolve_chains(entries, blasts)
	var danger := {}
	for i in entries.size():
		for burned: Vector2i in blasts[i]:
			danger[burned] = minf(danger.get(burned, NO_DANGER), entries[i].time)
	for flame_cell: Vector2i in grid.flames:
		danger[flame_cell] = 0.0
	return danger


func remote_bomb_time(bomb: Bomb) -> float:
	return maxf(REMOTE_DELAY - remote_clock, 0.0) if bomb.owner_actor == self else 0.0


func resolve_chains(entries: Array[Dictionary], blasts: Array[Array]) -> void:
	var changed := true
	var guard := 0
	while changed and guard < entries.size():
		changed = false
		guard += 1
		for i in entries.size():
			for j in entries.size():
				if i != j and entries[j].cell in blasts[i] and entries[j].time > entries[i].time:
					entries[j].time = entries[i].time
					changed = true


func blast_area(origin: Vector2i, fire: int, extra_cell: Vector2i) -> Array:
	var cells: Array = [origin]
	for dir in DIRECTIONS:
		for step in range(1, fire + 1):
			var target := origin + dir * step
			var cell_type := grid.data.get_cell(target)
			if cell_type != LevelData.Cell.FLOOR:
				break
			cells.append(target)
			if grid.has_bomb(target) or target == extra_cell:
				break
	return cells


func bricks_hit(origin: Vector2i) -> int:
	var count := 0
	for dir in DIRECTIONS:
		for step in range(1, fire_range + 1):
			var target := origin + dir * step
			var cell_type := grid.data.get_cell(target)
			if cell_type == LevelData.Cell.BRICK:
				count += 1
				break
			if cell_type != LevelData.Cell.FLOOR or grid.has_bomb(target):
				break
	return count


func bomb_value(origin: Vector2i) -> float:
	var value := BRICK_VALUE * bricks_hit(origin)
	var area := blast_area(origin, fire_range, origin)
	for opponent in opponents:
		if not opponent.is_alive():
			continue
		var target := opponent.cell()
		if target in area:
			value += profile.opponent_value
		if manhattan(target, origin) <= fire_range + TRAP_REACH:
			value += trap_bonus(target, origin, area)
	return value


func trap_bonus(target: Vector2i, bomb_cell: Vector2i, area: Array) -> float:
	var escapes := escape_count(target, bomb_cell, area)
	if escapes == 0:
		return TRAP_VALUE
	if escapes <= 2:
		return TRAP_VALUE * 0.4
	return 0.0


func escape_count(start: Vector2i, bomb_cell: Vector2i, area: Array) -> int:
	var dist := {start: 0}
	var queue: Array[Vector2i] = [start]
	var head := 0
	var escapes := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		if not (current in area):
			escapes += 1
		if dist[current] >= ESCAPE_SEARCH_DEPTH:
			continue
		for dir in DIRECTIONS:
			var next := current + dir
			if dist.has(next) or next == bomb_cell or not grid.is_walkable(next):
				continue
			dist[next] = dist[current] + 1
			queue.append(next)
	return escapes


func breadth_first(start: Vector2i) -> Dictionary:
	var dist := {start: 0}
	var prev := {}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		if dist[current] >= SEARCH_DEPTH:
			continue
		for dir in direction_order:
			var next := current + dir
			if dist.has(next) or not is_walkable(next):
				continue
			dist[next] = dist[current] + 1
			prev[next] = current
			queue.append(next)
	return {"dist": dist, "prev": prev}


func path_to(search: Dictionary, target: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not search.dist.has(target):
		return result
	var current := target
	while search.prev.has(current):
		result.push_front(current)
		current = search.prev[current]
	return result


func path_is_safe(search: Dictionary, target: Vector2i, danger: Dictionary) -> bool:
	var step := step_time()
	var current := target
	while search.prev.has(current):
		var arrival: float = search.dist[current] * step
		if not cell_is_safe_at(current, arrival, step, danger):
			return false
		current = search.prev[current]
	return true


func cell_is_safe_at(target: Vector2i, arrival: float, step: float, danger: Dictionary) -> bool:
	var explode_at: float = danger.get(target, NO_DANGER)
	if explode_at >= NO_DANGER:
		return true
	var margin: float = profile.safety_margin
	var leaves_before := arrival + step + margin < explode_at
	var arrives_after := arrival > explode_at + Flame.LIFETIME + margin
	return leaves_before or arrives_after


func safe_cell(me: Vector2i, search: Dictionary, danger: Dictionary) -> Vector2i:
	var best := me
	var best_dist := SEARCH_DEPTH + 1
	for candidate: Vector2i in search.dist:
		if danger.get(candidate, NO_DANGER) < NO_DANGER:
			continue
		var d: int = search.dist[candidate]
		if d < best_dist and path_is_safe(search, candidate, danger):
			best = candidate
			best_dist = d
	return best


func safest_cell(me: Vector2i, search: Dictionary, danger: Dictionary) -> Vector2i:
	var safe := safe_cell(me, search, danger)
	if safe != me:
		return safe
	var best := me
	var best_margin := -NO_DANGER
	for candidate: Vector2i in search.dist:
		var margin: float = danger.get(candidate, NO_DANGER) - search.dist[candidate] * step_time()
		if margin > best_margin:
			best = candidate
			best_margin = margin
	return best


func choose_target(me: Vector2i, search: Dictionary, danger: Dictionary) -> Vector2i:
	var calm := not bombs_nearby(search, danger)
	if calm and rng.randf() < profile.wander_chance:
		return random_safe_cell(me, search, danger)
	for priority: String in profile.priorities:
		var target := target_for(priority, me, search, danger)
		if target != me:
			return target
	return random_safe_cell(me, search, danger) if calm else me


func target_for(priority: String, me: Vector2i, search: Dictionary, danger: Dictionary) -> Vector2i:
	match priority:
		"opponent":
			return approach_opponent(search, danger)
		"item":
			return nearest_item(search, danger)
	return best_bombing_spot(me, search, danger)


func approach_opponent(search: Dictionary, danger: Dictionary) -> Vector2i:
	var me := cell()
	var best := me
	var best_score := INF
	for opponent in opponents:
		if not opponent.is_alive():
			continue
		for dir in direction_order:
			var target := opponent.cell() + dir
			var d: int = search.dist.get(target, SEARCH_DEPTH + 1)
			if d > profile.chase_radius:
				continue
			var score: float = d + crowd_penalty(target) + rng.randf() * TARGET_NOISE
			if score < best_score and path_is_safe(search, target, danger):
				best = target
				best_score = score
	return best


func nearest_item(search: Dictionary, danger: Dictionary) -> Vector2i:
	var me := cell()
	var best := me
	var best_dist := SEARCH_DEPTH + 1
	for item in get_tree().get_nodes_in_group("powerups"):
		var target: Vector2i = item.cell
		var d: int = search.dist.get(target, SEARCH_DEPTH + 1)
		if d < best_dist and d <= ITEM_RANGE and not rival_is_closer(target, d) and path_is_safe(search, target, danger):
			best = target
			best_dist = d
	return best


func rival_is_closer(target: Vector2i, my_distance: int) -> bool:
	for rival in rivals():
		if manhattan(rival.cell(), target) < my_distance:
			return true
	return false


func rivals() -> Array[Bomber]:
	var result: Array[Bomber] = []
	for opponent in opponents:
		if opponent is AiBomber and opponent.is_alive():
			result.append(opponent)
	return result


func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func crowd_penalty(candidate: Vector2i) -> float:
	for rival in rivals():
		if manhattan(rival.cell(), candidate) <= CROWD_DISTANCE:
			return CROWD_PENALTY
	return 0.0


func best_bombing_spot(me: Vector2i, search: Dictionary, danger: Dictionary) -> Vector2i:
	if active_bomb_count() >= bombs_max:
		return me
	var best := me
	var best_score := 0.0
	for candidate: Vector2i in search.dist:
		var d: int = search.dist[candidate]
		if d == 0 or d > SPOT_RANGE or grid.has_bomb(candidate) or danger.has(candidate):
			continue
		var value := bomb_value(candidate)
		if value < MIN_BOMB_VALUE:
			continue
		var score: float = value - SPOT_DISTANCE_COST * d - profile.home_bias * 0.1 * manhattan(candidate, home) - crowd_penalty(candidate) * 0.5 + rng.randf() * TARGET_NOISE * 0.5
		if score > best_score and path_is_safe(search, candidate, danger):
			best = candidate
			best_score = score
	return best


func random_safe_cell(me: Vector2i, search: Dictionary, danger: Dictionary) -> Vector2i:
	var best := me
	var best_score := -INF
	for candidate: Vector2i in search.dist:
		if candidate == me or search.dist[candidate] > 4 or not path_is_safe(search, candidate, danger):
			continue
		var score: float = rng.randf() * TARGET_NOISE - crowd_penalty(candidate)
		if score > best_score:
			best = candidate
			best_score = score
	return best


func direction_along_path() -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	var offset := path[0] - cell()
	if absi(offset.x) + absi(offset.y) > 1:
		path.clear()
		return Vector2.ZERO
	var target := grid.cell_center(path[0])
	if position.distance_to(target) < ARRIVAL_EPSILON:
		position = target
		path.pop_front()
		think()
		return direction_along_path()
	var delta := target - position
	if absf(delta.x) > absf(delta.y):
		return Vector2(signf(delta.x), 0.0)
	return Vector2(0.0, signf(delta.y))
