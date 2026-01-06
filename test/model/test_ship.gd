extends "res://addons/gut/test.gd"

var ship: Ship


func before_each() -> void:
	ship = Ship.new("destroyer", 3)


func test_init() -> void:
	assert_eq(ship.name, "destroyer")
	assert_eq(ship.length, 3)
	assert_true(ship.coordinates.is_empty())
	assert_true(ship.hits.is_empty())


func test_place_on_horizontal() -> void:
	var start: Vector2i = Vector2i(2, 2)
	ship.place_on(start, Orientation.HORIZONTAL)

	assert_eq(ship.coordinates.size(), 3)
	assert_eq(ship.coordinates[0].x, 2)
	assert_eq(ship.coordinates[1].x, 3)
	assert_eq(ship.coordinates[2].x, 4)
	assert_eq(ship.coordinates[0].y, 2)
	assert_eq(ship.coordinates[1].y, 2)
	assert_eq(ship.coordinates[2].y, 2)
	assert_true(ship.hits.is_empty())


func test_place_on_vertical() -> void:
	var start: Vector2i = Vector2i(5, 1)
	ship.place_on(start, Orientation.VERTICAL)

	assert_eq(ship.coordinates.size(), 3)
	assert_eq(ship.coordinates[0].x, 5)
	assert_eq(ship.coordinates[1].x, 5)
	assert_eq(ship.coordinates[2].x, 5)
	assert_eq(ship.coordinates[0].y, 1)
	assert_eq(ship.coordinates[1].y, 2)
	assert_eq(ship.coordinates[2].y, 3)
	assert_true(ship.hits.is_empty())


func test_remove_clears_coordinates() -> void:
	var start: Vector2i = Vector2i(0, 0)
	ship.place_on(start, Orientation.HORIZONTAL)
	ship.remove()

	assert_true(ship.coordinates.is_empty())
	assert_true(ship.hits.is_empty())


func test_register_hit_increase() -> void:
	var start: Vector2i = Vector2i(1, 1)
	ship.place_on(start, Orientation.HORIZONTAL)

	var target: Vector2i = Vector2i(2, 1)
	ship.register_hit(target)

	assert_eq(ship.hits.size(), 1)
	assert_false(ship.is_sunk())


func test_register_hit_idempotent() -> void:
	var start: Vector2i = Vector2i(0, 0)
	ship.place_on(start, Orientation.HORIZONTAL)

	var target: Vector2i = Vector2i(0, 0)
	ship.register_hit(target)
	var first_hits: int = ship.hits.size()
	ship.register_hit(target)

	assert_eq(ship.hits.size(), first_hits)


func test_register_hit_ignores_miss() -> void:
	var start: Vector2i = Vector2i(0, 0)
	ship.place_on(start, Orientation.HORIZONTAL)

	var miss: Vector2i = Vector2i(10, 10)
	ship.register_hit(miss)

	assert_eq(ship.hits.size(), 0)


func test_is_sunk_when_all_hits() -> void:
	var start: Vector2i = Vector2i(0, 0)
	ship.place_on(start, Orientation.HORIZONTAL)

	for coord in ship.coordinates:
		ship.register_hit(coord)

	assert_true(ship.is_sunk())


# func test_to_dict() -> void:
# 	var start: Vector2i = Vector2i(3, 3)
# 	ship.place_on(start, Orientation.HORIZONTAL)
# 	ship.register_hit(Vector2i(3, 3))
# 	ship.register_hit(Vector2i(4, 3))

# 	var data: Dictionary = ship.to_dict()

# 	assert_eq(data.get("name"), ship.name)
# 	assert_eq(data.get("length"), ship.length)
# 	assert_true(data.has("coordinates"))
# 	assert_true(data.has("hits"))
# 	assert_eq(data["coordinates"].size(), 3)
# 	assert_eq(data["hits"].size(), 2)


# func test_from_dict() -> void:
# 	var data: Dictionary = {
# 		"name": "destroyer",
# 		"length": 3,
# 		"coordinates": [
# 			{"x": 1, "y": 1},
# 			{"x": 2, "y": 1},
# 			{"x": 3, "y": 1},
# 		],
# 		"hits": [
# 			{"x": 2, "y": 1},
# 			{"x": 3, "y": 1},
# 		]
# 	}

# 	var new_ship: Ship = Ship.from_dict(data)

# 	assert_eq(new_ship.name, "destroyer")
# 	assert_eq(new_ship.length, 3)
# 	assert_eq(new_ship.coordinates.size(), 3)
# 	assert_eq(new_ship.hits.size(), 2)
# 	assert_eq(new_ship.coordinates[0].x, 1)
# 	assert_eq(new_ship.coordinates[2].y, 1)
