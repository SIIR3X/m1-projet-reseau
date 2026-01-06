extends "res://addons/gut/test.gd"

var board: Board
var ship: Ship


func before_each() -> void:
	board = Board.new(10, 10)
	ship = Ship.new("destroyer", 3)


func test_init_board() -> void:
	assert_eq(board.width, 10)
	assert_eq(board.height, 10)
	assert_eq(board.grid.size(), 10)
	assert_eq(board.grid[0].size(), 10)
	assert_true(board.ships.is_empty())


func test_place_ship_successful() -> void:
	var start: Vector2i = Vector2i(1, 1)
	var placed: bool = board.place_ship(ship, start, Orientation.HORIZONTAL)

	assert_true(placed)
	assert_eq(board.ships.size(), 1)
	assert_true(board.get_cell(1, 1).has_ship())
	assert_true(board.get_cell(2, 1).has_ship())
	assert_true(board.get_cell(3, 1).has_ship())


func test_place_ship_rejects_overlap() -> void:
	var start: Vector2i = Vector2i(0, 0)
	board.place_ship(ship, start, Orientation.HORIZONTAL)

	var other: Ship = Ship.new("submarine", 3)
	var placed: bool = board.place_ship(other, start, Orientation.HORIZONTAL)

	assert_false(placed)
	assert_eq(board.ships.size(), 1)


func test_register_shot_miss() -> void:
	var coord: Vector2i = Vector2i(5, 5)
	var result: int = board.register_shot(coord)

	assert_eq(result, Shot.ShotResult.MISS)
	assert_true(board.get_cell(5, 5).has_been_shot())


func test_register_shot_hit() -> void:
	var start: Vector2i = Vector2i(1, 1)
	board.place_ship(ship, start, Orientation.HORIZONTAL)

	var coord: Vector2i = Vector2i(2, 1)
	var result: int = board.register_shot(coord)

	assert_eq(result, Shot.ShotResult.HIT)
	assert_true(board.get_cell(2, 1).has_been_shot())
	assert_eq(ship.hits.size(), 1)


func test_register_shot_sunk() -> void:
	var start: Vector2i = Vector2i(0, 0)
	board.place_ship(ship, start, Orientation.HORIZONTAL)

	board.register_shot(Vector2i(0, 0))
	board.register_shot(Vector2i(1, 0))
	var result: int = board.register_shot(Vector2i(2, 0))

	assert_eq(result, Shot.ShotResult.SUNK)
	assert_true(ship.is_sunk())


func test_register_shot_already_shot() -> void:
	var coord: Vector2i = Vector2i(4, 4)
	board.register_shot(coord)

	var result: int = board.register_shot(coord)
	assert_eq(result, Shot.ShotResult.ALREADY_SHOT)


# func test_to_dict() -> void:
# 	var start: Vector2i = Vector2i(2, 2)
# 	board.place_ship(ship, start, Orientation.HORIZONTAL)
# 	board.register_shot(Vector2i(2, 2))

# 	var data: Dictionary = board.to_dict()

# 	assert_true(data.has("width"))
# 	assert_true(data.has("height"))
# 	assert_true(data.has("grid"))
# 	assert_true(data.has("ships"))

# 	assert_eq(data["width"], board.width)
# 	assert_eq(data["height"], board.height)
# 	assert_eq(data["ships"].size(), 1)
# 	assert_eq(data["grid"].size(), board.grid.size())


# func test_from_dict() -> void:
# 	var data: Dictionary = {
# 		"width": 10,
# 		"height": 10,
# 		"ships": [
# 			{
# 				"name": "destroyer",
# 				"length": 3,
# 				"coordinates": [
# 					{"x": 1, "y": 1},
# 					{"x": 2, "y": 1},
# 					{"x": 3, "y": 1},
# 				],
# 				"hits": [
# 					{"x": 2, "y": 1},
# 				]
# 			}
# 		],
# 		"grid": []
# 	}

# 	var new_board: Board = Board.from_dict(data)

# 	assert_eq(new_board.width, 10)
# 	assert_eq(new_board.height, 10)
# 	assert_eq(new_board.ships.size(), 1)

# 	var new_ship: Ship = new_board.ships[0]
# 	assert_eq(new_ship.name, "destroyer")
# 	assert_eq(new_ship.length, 3)
# 	assert_eq(new_ship.coordinates.size(), 3)
# 	assert_eq(new_ship.hits.size(), 1)
