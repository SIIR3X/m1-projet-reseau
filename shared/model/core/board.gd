extends Resource
class_name Board


@export var width: int
@export var height: int
@export var grid: Array[Array] = []
@export var ships: Array[Ship] = []


func _init(_width: int = 10, _height: int = 10) -> void:
	width = _width
	height = _height
	_initialize_grid()


func _initialize_grid() -> void:
	grid.clear()

	# Create a 2D array (height x width) filled with Cell instances
	for y in range(height):
		var row: Array = []

		for x in range(width):
			row.append(Cell.new(Vector2i(x, y)))
		
		grid.append(row)


func _can_place_ship(ship: Ship, start: Vector2i, orientation: int) -> bool:
	var x: int = start.x
	var y: int = start.y

	for i in range(ship.length):
		# Check bounds
		if x < 0 or x >= width or y < 0 or y >= height:
			return false

		# Check if a ship already occupies this cell
		var cell: Cell = get_cell(x, y)
		if cell == null or cell.has_ship():
			return false

		# Move in the correct direction
		if orientation == Orientation.HORIZONTAL:
			x += 1
		else:
			y += 1

	return true


func randomize_grid() -> void:
	# Reset the grid and clear existing ships
	_initialize_grid()
	ships.clear()

	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.randomize()

	# Parameters
	var ship_count: int = 5
	var min_ship_size: int = 2
	var max_ship_size = 5
	var max_attemps_per_ship: int = 100
	var ship_id: int = 1

	for i: int in range(ship_count):
		var length: int = generator.randi_range(min_ship_size, max_ship_size)
		var ship: Ship = Ship.new("", length, ship_id)
		ship_id += 1

		var ship_placed: bool = false
		var attemps: int = 0

		# Try to place current ship
		while not ship_placed and attemps < max_attemps_per_ship:
			attemps += 1

			# Generation random orientation
			var orientation: int = generator.randi_range(0, 1)

			# Generating random starting coordinates
			var start_x: int
			var start_y: int

			if orientation == Orientation.HORIZONTAL:
				start_x = generator.randi_range(0, width - ship.length)
				start_y = generator.randi_range(0, height - 1)
			else:
				start_x = generator.randi_range(0, width - 1)
				start_y = generator.randi_range(0, height - ship.length)

			var start: Vector2i = Vector2i(start_x, start_y)
			if place_ship(ship, start, orientation):
				ship_placed = true
		

func get_cell(x: int, y: int) -> Cell:
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	return grid[y][x]


func place_ship(ship: Ship, start: Vector2i, orientation: int) -> bool:
	# Try to place a ship starting from the given coordinate
	if not _can_place_ship(ship, start, orientation):
		return false

	# Place the ship on valid cells
	ship.place_on(start, orientation)

	# Assign the ship on each cell
	for coord in ship.coordinates:
		get_cell(coord.x, coord.y).assign_ship(ship)

	ships.append(ship)
	return true


func register_shot(coordinate: Vector2i) -> Dictionary:
	var cell: Cell = get_cell(coordinate.x, coordinate.y)

	# If the coordinate is outside the board -> out of bounds
	if cell == null:
		return {
			"result": Shot.ShotResult.OUT_BOUNDS
		}

	# If this cell has already been shot at -> ignore
	if cell.has_been_shot():
		return {
			"result": Shot.ShotResult.ALREADY_SHOT
		}

	# Mark the cell as shot
	cell.mark_shot()

	# Check if the cell contains a ship
	if cell.has_ship():
		# Notify the ship that it has been hit at this coordinate
		cell.ship.register_hit(coordinate)

		# If the hit caused the ship to be completely destroyed -> SUNK
		if cell.ship.is_sunk():

			# Collect all coordinates belonging to this sunk ship
			var coords: Array = []
			for c in cell.ship.coordinates:
				coords.append([c.x, c.y])

			return {
				"result": Shot.ShotResult.SUNK,
				"sunk_cells": coords,
				"ship_id": cell.ship.id
			}

		# Otherwise it's a regular HIT
		return {
			"result": Shot.ShotResult.HIT
		}

	# If there was no ship on this cell -> MISS
	return {
		"result": Shot.ShotResult.MISS
	}


func all_ships_sunk() -> bool:
	# Return true if all ships on the board are sunk
	for ship in ships:
		if not ship.is_sunk():
			return false

	return true


func to_network_array() -> Array:
	var data: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var cell := get_cell(x, y)
			
			if cell.ship == null:
				row.append(0) # eau
			else:
				row.append(ships.find(cell.ship) + 1)
			
		data.append(row)
	return data
