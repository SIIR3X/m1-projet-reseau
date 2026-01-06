extends Player
class_name BotPlayer

signal bot_played(coord: Vector2i)


func _init(_name: String = "Bot", _peer_id: int = -1) -> void:
	super(_name, _peer_id)
	board.randomize_grid()


func play_turn(enemy_board: Board) -> void:
	# Pick a random coordinate
	var coord := _pick_random_target(enemy_board)

	# Shot at the coordinate
	emit_signal("bot_played", coord)


func _pick_random_target(target_board: Board) -> Vector2i:
	var possible_targets: Array[Vector2i] = []

	for y in range(target_board.height):
		for x in range(target_board.width):
			var cell := target_board.get_cell(x, y)
			if cell != null and not cell.has_been_shot():
				possible_targets.append(Vector2i(x, y))

	# If no possible target left → return (0,0) as fallback
	if possible_targets.is_empty():
		return Vector2i(0, 0)

	# Pick a random remaining target
	return possible_targets[randi() % possible_targets.size()]