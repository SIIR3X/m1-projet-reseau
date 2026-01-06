extends Resource
class_name Player

@export var name: String
@export var board: Board
@export var peer_id: int = -1

var is_logged_in: bool = false
var game: Game = null
var party: Party = null

signal played(coord: Vector2i)

func _init(_name: String = "Player", _peer_id: int = -1) -> void:
	name = _name
	peer_id = _peer_id
	board = Board.new()
	game = null


# Called by the Game when it's this player's turn.
# For a human player, nothing happends immediately.
# The Game will now WAIT until this player emits the "played" signal.
# (i.e. the game logic pauses here until the palyer chooses a target)
func play_turn(_enemy_board: Board) -> void:
	pass


# Called by the UI or client input when the player selects a cell to shoot.
# This emits the "played" signal with the chosen coordinate.
# Once this signal is emitted, the Game (which is connected to this signal)
# will continue processing the turn using that coordinate.
func hit(coord: Vector2i) -> void:
	emit_signal("played", coord)


func shoot_at(enemy_board: Board, coordinate: Vector2i) -> Dictionary:
	return enemy_board.register_shot(coordinate)


func has_lost() -> bool:
	return board.all_ships_sunk()


func leave_game() -> void:
	if game != null:
		game.remove_player(self)
		game = null
