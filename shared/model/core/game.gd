extends Node
class_name Game

@export var player1: Player = null
@export var player2: Player = null
@export var current_player_index: int = 0
@export var is_running: bool = false
@export var total_timer_per_player: float = 300.0  # 5min/player
@export var use_timers: bool = true

var shot_history : Array = []

var turn_timer: Timer
var disconnect_timer: Timer

var player1_time_left: float = total_timer_per_player
var player2_time_left: float = total_timer_per_player

var disconnected_players: Array[Player] = []
var is_paused: bool = false

signal timers_updated(player1_time: float, player2_time: float)
signal shot_resolved(shooter: Player, targer: Player, coord: Vector2i, result: Shot.ShotResult, sunk_cells: Array, ship_id: int)
signal game_ended(winner: Player)
signal game_paused()
signal game_resumed()

func _init(_player1: Player = null, _player2: Player = null) -> void:
	if _player1:
		add_player(_player1)
	if _player2:
		add_player(_player2)


func _play_current_turn() -> void:
	var shooter: Player = get_current_player()
	var target: Player = get_opponent()

	if shooter is BotPlayer:
		_play_bot_turn(shooter, target)
	else:
		_play_human_turn(shooter, target)


func _play_human_turn(shooter: Player, target: Player) -> void:
	if shooter.is_connected("played", self._on_player_played):
		shooter.disconnect("played", self._on_player_played)

	shooter.connect("played", self._on_player_played, CONNECT_ONE_SHOT)
	shooter.play_turn(target.board)


func _play_bot_turn(bot: BotPlayer, target: Player) -> void:
	if bot.is_connected("bot_played", self._on_player_played):
		bot.disconnect("bot_played", self._on_player_played)

	bot.connect("bot_played", self._on_player_played, CONNECT_ONE_SHOT)

	var coord := bot._pick_random_target(target.board)

	_play_bot_delayed(bot, coord)


func _play_bot_delayed(bot: BotPlayer, coord: Vector2i) -> void:
	await get_tree().create_timer(2.0).timeout
	bot.emit_signal("bot_played", coord)


func _on_player_played(coord: Vector2i) -> void:
	var shooter: Player = get_current_player()
	var target: Player = get_opponent()

	# Shot at the target board
	var shot_data: Dictionary = shooter.shoot_at(target.board, coord)

	var shot_result: int = shot_data["result"]
	var sunk_cells: Array = []
	if shot_data.has("sunk_cells"):
		sunk_cells = shot_data["sunk_cells"]

	var ship_id: int = -1
	if shot_result == Shot.ShotResult.SUNK and shot_data.has("ship_id"):
		ship_id = int(shot_data["ship_id"])

	# Emit signal
	emit_signal("shot_resolved", shooter, target, coord, shot_result, sunk_cells, ship_id)

	# Check if the current player won the game
	if target.has_lost():
		_end_game(shooter)
		return

	# If the player has hit a ship, he can shoot again
	if shot_result == Shot.ShotResult.HIT:
		_play_current_turn()
		return

	_next_turn()
	_play_current_turn()


func _on_turn_timer_tick() -> void:
	if not is_running or not use_timers:
		return

	if current_player_index == 0:
		player1_time_left -= 1.0

		if player1_time_left <= 0:
			_end_game(player2)  # Player 1 lost
	else:
		player2_time_left -= 1.0

		if player2_time_left <= 0:
			_end_game(player1)  # Player 2 lost

	# Emit signal after update
	emit_signal("timers_updated", player1_time_left, player2_time_left)


func _end_game(winner: Player) -> void:
	is_running = false

	cleanup()

	if player1: player1.game = null
	if player2: player2.game = null

	emit_signal("game_ended", winner)


func _next_turn() -> void:
	current_player_index = 1 - current_player_index


func add_player(player: Player) -> bool:
	if player1 == null:
		player1 = player
	elif player2 == null:
		player2 = player
	else:
		return false
	
	player.game = self
	return true


func remove_player(player: Player) -> void:
	if player == null:
		return

	# Check if the player is part of this game
	if player1 == player:
		player1.game = null
		player1 = null
	elif player2 == player:
		player2.game = null
		player2 = null
	else:
		return

	# If the game was running and one player leaves, the other wins
	if is_running:
		var remaining_player: Player = player1 if player1 != null else player2

		if remaining_player != null:
			is_running = false
			emit_signal("game_ended", remaining_player)
		else:
			# No players left, nothing to do
			is_running = false


func is_ready() -> bool:
	return player1 != null and player2 != null


func start() -> void:
	if not is_ready():
		return

	# Randomize gplayer's grid
	player1.board.randomize_grid()
	player2.board.randomize_grid()

	is_running = true

	# Init timers
	player1_time_left = total_timer_per_player
	player2_time_left = total_timer_per_player

	if not use_timers:
		_play_current_turn()
		return

	# Create timer node (for the game)
	turn_timer = Timer.new()
	turn_timer.wait_time = 1.0
	turn_timer.autostart = true
	turn_timer.one_shot = false
	turn_timer.timeout.connect(_on_turn_timer_tick)
	add_child(turn_timer)

	# Create timer node (to handle disconnect signals)
	disconnect_timer = Timer.new()
	disconnect_timer.wait_time = 60.0
	disconnect_timer.one_shot = true
	disconnect_timer.timeout.connect(_on_disconnect_timer_timeout)
	add_child(disconnect_timer)

	_play_current_turn()


func get_current_player() -> Player:
	return (player1 if current_player_index == 0 else player2)


func get_opponent() -> Player:
	return (player2 if current_player_index == 0 else player1)


func has_ended() -> bool:
	return not is_running


func get_winner() -> Player:
	if not has_ended():
		return null
	return get_current_player()


func pause_game() -> void:
	if is_paused or not use_timers:
		return
	is_paused = true
	turn_timer.stop()
	emit_signal("game_paused")


func resume_game() -> void:
	if not is_paused or not use_timers:
		return
	is_paused = false
	turn_timer.start()
	emit_signal("game_resumed")


func on_player_disconnected(player: Player) -> void:
	if not use_timers:
		return

	if player not in disconnected_players:
		disconnected_players.append(player)
	
	pause_game()

	if disconnected_players.size() >= 1:
		disconnect_timer.stop()
		disconnect_timer.wait_time = 60.0
		disconnect_timer.start()


func on_player_reconnected(player: Player) -> void:
	if not use_timers:
		return

	if player in disconnected_players:
		disconnected_players.erase(player)

	if disconnected_players.is_empty():
		disconnect_timer.stop()
		disconnect_timer.wait_time = 60.0
		resume_game()


func _on_disconnect_timer_timeout() -> void:
	if not use_timers:
		return

	if not is_paused:
		return

	if disconnected_players.size() == 1:
		var disconnected: Player = disconnected_players[0]

		var winner: Player = null
		if disconnected == player1:
			winner = player2
		else:
			winner = player1

		_end_game(winner)
		return

	if disconnected_players.size() >= 2:
		_end_game(null)


func cleanup():
	# Stop timers
	if turn_timer:
		turn_timer.stop()
		turn_timer.queue_free()
		turn_timer = null

	if disconnect_timer:
		disconnect_timer.stop()
		disconnect_timer.queue_free()
		disconnect_timer = null

	if player1:
		if player1.is_connected("played", _on_player_played):
			player1.disconnect("played", _on_player_played)

	if player2:
		if player2.is_connected("played", _on_player_played):
			player2.disconnect("played", _on_player_played)

	current_player_index = 0
	is_running = false
	is_paused = false
	disconnected_players.clear()
	shot_history.clear()
