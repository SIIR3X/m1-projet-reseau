extends Resource
class_name Ship

@export var id: int = -1
@export var name: String
@export var length: int
@export var coordinates: Array[Vector2i] = []
@export var hits: Array[Vector2i] = []


func _init(_name: String, _length: int, _id: int = -1) -> void:
	name = _name
	length = _length
	id = _id


func register_hit(coordinate: Vector2i) -> void:
	# Flag to track if the given coordinate exists in the list of valid coordinates
	var found: bool = false

	# Check if the given coordinate matches any of the stored coordinates
	for coord in coordinates:
		if coord == coordinate:
			found = true
			break

	# If the coordinate is not part of the valid coordinates, exit the function
	if not found:
		return

	# Check if this coordinate has already been recorded as a hit
	for hit in hits:
		if hit == coordinate:
			return

	# If it's a valid coordinate and not already hit, add it to the hits list
	hits.append(coordinate)


func is_sunk() -> bool:
	# Return true if all coordinates have been hit (the object is fully sunk)
	return hits.size() >= coordinates.size()


func place_on(start: Vector2i, orientation: int) -> void:
	# Clear any previous coordinates and hits before placing the object again
	coordinates.clear()
	hits.clear()

	# Initialize starting x and y positions
	var x: int = start.x
	var y: int = start.y

	# Generate the coordinates of the object based on its length and orientation
	for i in range(length):
		# Add the current position as a new coordinate
		coordinates.append(Vector2i(x, y))

		# Move horizontally or vertically depending on the orientation
		if orientation == Orientation.HORIZONTAL:
			x += 1
		else:
			y += 1


func remove() -> void:
	coordinates.clear()
	hits.clear()


# func to_dict() -> Dictionary:
# 	# Create an array to store serialized coordinate data
# 	var coords_data: Array = []
# 	for coord in coordinates:
# 		coords_data.append(coord.to_dict())

# 	# Create an array to store serialized hit data
# 	var hits_data: Array = []
# 	for hit in hits:
# 		hits_data.append(hit.to_dict())

# 	return {
# 		"name": name,
# 		"length": length,
# 		"coordinates": coords_data,
# 		"hits": hits_data
# 	}


# static func from_dict(data: Dictionary) -> Ship:
# 	var ship: Ship = Ship.new(data.get("name", ""), data.get("length", 0))

# 	# Rebuild the ship's coordinates from the saved data
# 	for coord in data.get("coordinates", []):
# 		ship.coordinates.append(Vector2i.from_dict(coord))

# 	# Rebuild the ship's hit data from the saved data
# 	for hit in data.get("hits", []):
# 		ship.hits.append(Vector2i.from_dict(hit))

# 	return ship
