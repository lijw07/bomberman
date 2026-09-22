class_name LevelData
extends RefCounted

enum Cell { FLOOR, WALL, PILLAR, BRICK }

var width: int
var height: int
var cells: PackedByteArray
var spawns: Array[Vector2i] = []
var item_cell := Vector2i(-1, -1)
var item_type := PowerUp.Kind.FIRE
var enemies: Array[Dictionary] = []
var level := 1
var seed_value := 0


func _init(w: int, h: int) -> void:
	width = w
	height = h
	cells.resize(w * h)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func get_cell(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return Cell.WALL
	return cells[cell.y * width + cell.x]


func set_cell(cell: Vector2i, value: int) -> void:
	cells[cell.y * width + cell.x] = value


func is_brick(cell: Vector2i) -> bool:
	return get_cell(cell) == Cell.BRICK


func is_passable(cell: Vector2i, wall_pass := false) -> bool:
	var value := get_cell(cell)
	if value == Cell.FLOOR:
		return true
	return wall_pass and value == Cell.BRICK


func brick_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			if is_brick(cell):
				result.append(cell)
	return result


func pixel_size(tile: int) -> Vector2:
	return Vector2(width * tile, height * tile)
