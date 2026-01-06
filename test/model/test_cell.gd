extends "res://addons/gut/test.gd"


# func test_to_dict() -> void:
# 	var coordinate: Coordinate = Coordinate.new(1,2)
# 	var cell: Cell = Cell.new(coordinate)
# 	var ship: Ship = Ship.new("destoyer", 3)
# 	cell.assign_ship(ship)
# 	var dict: Dictionary = cell.to_dict()

# 	assert_eq(dict.get("coordinate"), coordinate.to_dict())
# 	assert_eq(dict.get("was_shot"), cell.was_shot)
# 	assert_eq(dict.get("ship"), ship.to_dict())


# func test_from_dict() -> void:
# 	var data: Dictionary = {
# 		"coordinate": {"x": 1, "y": 2},
# 		"was_shot": true,
# 	}

# 	var cell = Cell.from_dict(data)
# 	assert_eq(cell.coordinate.x, 1)
# 	assert_eq(cell.coordinate.y, 2)
# 	assert_true(cell.was_shot)
