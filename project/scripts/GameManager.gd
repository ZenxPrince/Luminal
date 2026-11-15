extends Node

# GameManager.gd - autoload singleton
# Tracks level, score, moves across sessions

var current_level: int = 0
var total_moves: int = 0
var level_moves: Array = []

const LEVELS = [
	{
		"title": "FIRST LIGHT",
		"subtitle": "find the exit",
		"grid_size": Vector2i(8, 6),
		"emitter": Vector2i(1, 2),
		"emitter_dir": Vector2i(1, 0),  # right
		"exit": Vector2i(6, 2),
		"walls": [
			Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3),
		],
		"mirrors_available": 2,
		"par": 2,
	},
	{
		"title": "DEFLECTION",
		"subtitle": "angles matter",
		"grid_size": Vector2i(9, 7),
		"emitter": Vector2i(1, 1),
		"emitter_dir": Vector2i(1, 0),
		"exit": Vector2i(7, 5),
		"walls": [
			Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3),
			Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4),
		],
		"mirrors_available": 3,
		"par": 3,
	},
	{
		"title": "SPLIT",
		"subtitle": "one becomes two",
		"grid_size": Vector2i(10, 7),
		"emitter": Vector2i(1, 3),
		"emitter_dir": Vector2i(1, 0),
		"exit": Vector2i(8, 1),
		"exit2": Vector2i(8, 5),
		"walls": [
			Vector2i(3, 1), Vector2i(3, 2),
			Vector2i(3, 4), Vector2i(3, 5),
			Vector2i(6, 0), Vector2i(6, 1), Vector2i(6, 2),
			Vector2i(6, 4), Vector2i(6, 5), Vector2i(6, 6),
		],
		"mirrors_available": 4,
		"par": 4,
	},
	{
		"title": "THE LOOP",
		"subtitle": "don't get caught",
		"grid_size": Vector2i(10, 8),
		"emitter": Vector2i(1, 4),
		"emitter_dir": Vector2i(1, 0),
		"exit": Vector2i(8, 4),
		"walls": [
			Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
			Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
			Vector2i(3, 3), Vector2i(3, 4),
			Vector2i(7, 3), Vector2i(7, 4),
		],
		"mirrors_available": 4,
		"par": 4,
	},
	{
		"title": "ESCAPE",
		"subtitle": "final signal",
		"grid_size": Vector2i(11, 8),
		"emitter": Vector2i(1, 1),
		"emitter_dir": Vector2i(1, 0),
		"exit": Vector2i(9, 6),
		"walls": [
			Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3),
			Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5),
			Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6),
			Vector2i(2, 5), Vector2i(2, 6),
		],
		"mirrors_available": 5,
		"par": 5,
	},
]

func get_level_data(idx: int) -> Dictionary:
	if idx >= 0 and idx < LEVELS.size():
		return LEVELS[idx]
	return {}

func total_levels() -> int:
	return LEVELS.size()
