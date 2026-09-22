class_name EnemyTypes
extends RefCounted

enum Chase { NONE, COLUMN, ROW, BOTH }

const SLOWEST := 88.0
const SLOW := 120.0
const MEDIUM := 180.0
const FAST := 240.0

const TYPES := {
	"ballom": {
		"points": 100, "speed": SLOW, "chase": Chase.NONE, "wall_pass": false,
		"turn_min": 2.0, "turn_max": 4.0, "erratic": false, "flee": false,
		"unlock": 1, "retire": 30, "weight": 10, "sprite": "ballom",
	},
	"onil": {
		"points": 200, "speed": MEDIUM, "chase": Chase.COLUMN, "wall_pass": false,
		"turn_min": 0.8, "turn_max": 3.2, "erratic": false, "flee": false,
		"unlock": 2, "retire": 35, "weight": 8, "sprite": "onil",
	},
	"dahl": {
		"points": 400, "speed": MEDIUM, "chase": Chase.ROW, "wall_pass": false,
		"turn_min": 0.8, "turn_max": 3.2, "erratic": false, "flee": false,
		"unlock": 3, "retire": 42, "weight": 7, "sprite": "dahl",
	},
	"minvo": {
		"points": 800, "speed": FAST, "chase": Chase.BOTH, "wall_pass": false,
		"turn_min": 0.5, "turn_max": 2.0, "erratic": false, "flee": false,
		"unlock": 4, "retire": 99, "weight": 6, "sprite": "minvo",
	},
	"doria": {
		"points": 1000, "speed": SLOWEST, "chase": Chase.BOTH, "wall_pass": true,
		"turn_min": 2.0, "turn_max": 8.0, "erratic": false, "flee": false,
		"unlock": 7, "retire": 99, "weight": 4, "sprite": "doria",
	},
	"ovape": {
		"points": 2000, "speed": SLOW, "chase": Chase.BOTH, "wall_pass": true,
		"turn_min": 1.0, "turn_max": 4.0, "erratic": false, "flee": true,
		"unlock": 9, "retire": 99, "weight": 4, "sprite": "ovape",
	},
	"pass": {
		"points": 4000, "speed": FAST, "chase": Chase.BOTH, "wall_pass": false,
		"turn_min": 0.3, "turn_max": 1.2, "erratic": true, "flee": false,
		"unlock": 14, "retire": 99, "weight": 3, "sprite": "pass",
	},
	"pontan": {
		"points": 8000, "speed": FAST, "chase": Chase.BOTH, "wall_pass": true,
		"turn_min": 0.3, "turn_max": 1.0, "erratic": false, "flee": false,
		"unlock": 45, "retire": 99, "weight": 1, "sprite": "pontan",
	},
}

const ITEM_SPAWN := {
	PowerUp.Kind.FIRE: "onil",
	PowerUp.Kind.BOMB: "ballom",
	PowerUp.Kind.SPEED: "dahl",
	PowerUp.Kind.WALL_PASS: "minvo",
	PowerUp.Kind.BOMB_PASS: "ovape",
	PowerUp.Kind.DETONATOR: "doria",
	PowerUp.Kind.FLAMEPROOF: "pass",
	PowerUp.Kind.MYSTERY: "pontan",
}


static func stats(type_name: String) -> Dictionary:
	return TYPES[type_name]


static func available_for_level(level: int) -> Array[String]:
	var result: Array[String] = []
	for type_name in TYPES:
		var t: Dictionary = TYPES[type_name]
		if level >= t.unlock and level <= t.retire:
			result.append(type_name)
	return result


static func weight_for_level(type_name: String, level: int) -> float:
	var t: Dictionary = TYPES[type_name]
	var recency_bonus := clampf(1.0 + 0.15 * (level - t.unlock), 1.0, 2.5)
	return t.weight * recency_bonus
