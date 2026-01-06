extends Resource
class_name Cell

@export var coordinate: Vector2i
@export var ship: Ship = null
@export var was_shot: bool = false


func _init(_coordinate: Vector2i) -> void:
	coordinate = _coordinate


func has_ship() -> bool:
	return ship != null


func has_been_shot() -> bool:
	return was_shot


func mark_shot() -> void:
	was_shot = true


func assign_ship(_ship: Ship) -> void:
	ship = _ship


# func to_dict() -> Dictionary:
# 	var data: Dictionary = {
# 		"coordinate": coordinate.to_dict(),
# 		"was_shot": was_shot,
# 	}

# 	if ship != null:
# 		data["ship"] = ship.to_dict()

# 	return data


# static func from_dict(data: Dictionary) -> Cell:
# 	var cell = Cell.new(Vector2i.from_dict(data.get("coordinate", {})))
# 	cell.was_shot = data.get("was_shot", false)
# 	return cell
