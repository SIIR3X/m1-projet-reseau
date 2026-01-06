extends Service

var games: Dictionary[int, Game] = {}  # id -> Game
var disconnected_players := {} # String name -> int game_id
var next_game_id: int = 0


func _ready() -> void:
	LobbyService.initiate_game.connect(_on_initiate_game)
	Players.player_removed.connect(_on_player_disconnected)


func _on_initiate_game(player1: Player, player2: Player) -> void:
	var game_id: int = create_game(player1)
	join_game(player2, game_id)

	# Start if both players are ready
	var game: Game = games[game_id]
	if game.is_ready():
		game.start()

	var p1_board_data = player1.board.to_network_array()
	var p2_board_data = player2.board.to_network_array()

	API.send(
		SendableAPIMessage.new(
			"Game.start",
			[
				float(game_id),
				player1.name,
				player2.name,
				float(player1.peer_id),
				game.player1_time_left,
				game.player2_time_left,
				p1_board_data
			]
		),
		player1.peer_id
	)

	API.send(
		SendableAPIMessage.new(
			"Game.start",
			[
				float(game_id),
				player1.name,
				player2.name,
				float(player1.peer_id),
				game.player1_time_left,
				game.player2_time_left,
				p2_board_data
			]
		),
		player2.peer_id
	)


func create_game(player: Player) -> int:
	# Increment the next game id
	var game_id: int = next_game_id
	next_game_id += 1

	# Create the game
	var game: Game = Game.new()
	games[game_id] = game

	add_child(game)

	# Add the player himself to the game
	game.add_player(player)

	# Connect signals
	_connect_game_signals(game, game_id)

	return game_id


func get_game_by_id(id: int) -> Game:
	return games.get(id)


func _get_game_for_peer_id(peer_id: int) -> Game:
	for id in games:
		var game := games[id]
		if (game.player1 and game.player1.peer_id == peer_id) or \
		   (game.player2 and game.player2.peer_id == peer_id):
			return game
	return null


func get_players_of_game(game_id: int) -> Array[Player]:
	var game: Game = games.get(game_id)
	if game == null:
		return []
	
	var players: Array[Player] = []

	if game.player1 != null:
		players.append(game.player1)
	if game.player2 != null:
		players.append(game.player2)

	return players


func destroy_game(id: int) -> void:
	if games.has(id):
		games.erase(id)


func join_game(player: Player, game_id: int) -> bool:
	var game: Game = games.get(game_id)
	if not game:
		return false

	if not game.add_player(player):
		return false

	return true

func _api_player_hit(player: Player, x: int, y: int) -> void:
	if player == null:
		return

	# Build the coordinate manually from x and y
	var coord: Vector2i = Vector2i(x, y)

	# Delegate to GameService
	GameService.player_hit(player, coord)


func _client_game_start(_game_id_f: float, p1_name: String, p2_name: String, p1_peer_f: float, p1_time: float, p2_time: float, board_data: Array) -> void:
	var my_peer_id: int = NetworkService.client_connection.client_id
	var player1_peer: int = int(p1_peer_f)
	var am_player1 := (my_peer_id == player1_peer)

	var packed_scene: PackedScene = load("res://client/scene/screen/online_game.tscn")
	get_tree().change_scene_to_packed(packed_scene)

	await get_tree().process_frame

	var scene := get_tree().current_scene
	if scene == null:
		return

	scene.setup_nodes()
	scene.initialize_names(p1_name, p2_name, am_player1)
	scene.initialize_timers(p1_time, p2_time)
	scene.update_label_backgrounds(am_player1)
	scene.load_own_board(board_data)


func _client_game_sync_state(
	_game_id_f: float,
	p1_name: String,
	p2_name: String,
	p1_peer_f: float,
	_p2_peer_f: float,
	p1_time: float,
	p2_time: float,
	board_data: Array,
	current_peer_f: float,
	shot_history: Array
) -> void:
	var my_peer := NetworkService.client_connection.client_id
	var p1_peer := int(p1_peer_f)
	var current_peer := int(current_peer_f)

	var am_player1 := (my_peer == p1_peer)
	var is_my_turn := (my_peer == current_peer)

	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_node("DisconnectedOverlay"):
		current_scene.get_node("DisconnectedOverlay").visible = false

	var packed_scene: PackedScene = load("res://client/scene/screen/online_game.tscn")
	get_tree().change_scene_to_packed(packed_scene)

	await get_tree().process_frame

	var scene := get_tree().current_scene
	if scene == null:
		return

	scene.setup_nodes()
	scene.initialize_names(p1_name, p2_name, am_player1)
	scene.initialize_timers(p1_time, p2_time)
	scene.load_own_board(board_data)
	scene.load_enemy_board(shot_history)

	scene.update_label_backgrounds(is_my_turn)


func _client_game_shot(_game_id_f: float, x_f: float, y_f: float, result_f: float, shooter_peer_f: float, _target_peer_f: float, sunk_cells: Array, ship_id: int) -> void:
	var x: int = int(x_f)
	var y: int = int(y_f)
	var shooter: int = int(shooter_peer_f)
	var result := int(result_f)

	# Player's peer id
	var my_peer_id: int = NetworkService.client_connection.client_id

	var game_ui:= get_tree().current_scene

	var change_turn := (
		result == Shot.ShotResult.MISS
		or result == Shot.ShotResult.SUNK
		or result == Shot.ShotResult.OUT_BOUNDS
		or result == Shot.ShotResult.ALREADY_SHOT
	)

	var my_turn: bool

	if change_turn:
		my_turn = (shooter != my_peer_id)
	else:
		my_turn = (shooter == my_peer_id)

	game_ui.update_label_backgrounds(my_turn)

	if shooter == my_peer_id:
		# I shot so i apply the shot on the enemy board
		game_ui.apply_shot_enemy_board(x, y, result, sunk_cells, ship_id)
	else:
		# He shot so i apply the shot on my board
		game_ui.apply_shot_own_board(x, y, result)


func _client_game_timers(_game_id: int, p1_time: float, p2_time: float, current_peer_f: float) -> void:
	var my_peer_id: int = NetworkService.client_connection.client_id
	var current_peer: int = int(current_peer_f)
	var am_player1: bool = (my_peer_id == current_peer)

	var scene := get_tree().current_scene
	if scene == null:
		return

	scene.update_timers(p1_time, p2_time, am_player1)
	scene.update_label_backgrounds((my_peer_id == current_peer))


func _client_game_ended(_game_id_f: float, winner_peer_f: float, reason: String) -> void:
	if reason == "resume_refused":
		return

	var my_peer := NetworkService.client_connection.client_id

	var scene_path := "res://client/scene/screen/end_victory.tscn" if winner_peer_f == my_peer else "res://client/scene/screen/end_defeat.tscn"
	get_tree().change_scene_to_file(scene_path)


func _client_game_player_disconnected(_game_id_f: float, _peer_id_f: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	
	scene.show_player_disconnected()


func _client_game_resume(_game_id_f: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	if scene.has_node("PopupDisconnected"):
		var p := scene.get_node("PopupDisconnected")
		p.hide()

	scene.enemy_board.enable_interactions()


func _client_game_offer_resume(game_id_f: float) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reprendre la partie"
	dialog.dialog_text = "Tu avais une partie en cours.\nVeux-tu la reprendre ?"

	add_child(dialog)
	dialog.popup_centered()

	dialog.get_ok_button().text = "Reprendre"

	dialog.get_cancel_button().text = "Annuler"
	dialog.get_cancel_button().visible = true

	dialog.confirmed.connect(func():
		API.send(
			SendableAPIMessage.new("Game.resumeRequest", [game_id_f])
		)
	)

	dialog.canceled.connect(func():
		API.send(
			SendableAPIMessage.new("Game.resumeRefused", [game_id_f])
		)
	)


func _api_resume_request(player: Player, game_id_f: float) -> void:
	var game_id: int = int(game_id_f)
	var game: Game = get_game_by_id(game_id)
	if game == null:
		return

	if game.player1 and game.player1.name == player.name:
		game.player1.peer_id = player.peer_id
		player = game.player1

	elif game.player2 and game.player2.name == player.name:
		game.player2.peer_id = player.peer_id
		player = game.player2

	var p1 := game.player1
	var p2 := game.player2

	for p in get_players_of_game(game_id):
		API.send(
			SendableAPIMessage.new(
				"Game.syncState",
				[
					float(game_id),
					p1.name,
					p2.name,
					float(p1.peer_id),
					float(p2.peer_id),
					game.player1_time_left,
					game.player2_time_left,
					p.board.to_network_array(),
					float(game.get_current_player().peer_id),
					game.shot_history
				]
			),
			p.peer_id
		)

	game.resume_game()


func _api_resume_refused(player: Player, game_id_f: float) -> void:
	var game_id: int = int(game_id_f)
	var game: Game = get_game_by_id(game_id)
	if game == null:
		return

	var winner: Player = game.player2 if (player == game.player1) else game.player1

	_on_game_ended(game_id, winner, "resume_refused")


func leave_game(player: Player) -> void:
	if player.game == null:
		return
	
	var game: Game = player.game
	var game_id: int = _find_game_id(game)

	game.remove_player(player)

	if game.has_ended() and game_id:
		destroy_game(game_id)


func _find_game_id(game: Game) -> int:
	for key: int in games:
		if games[key] == game:
			return key
	return -1  # No match found


func player_hit(player: Player, coord: Vector2i) -> void:
	if player.game == null:
		return
	player.hit(coord)


func _connect_game_signals(game: Game, game_id: int) -> void:
	game.game_ended.connect(func(winner): _on_game_ended(game_id, winner))

	game.shot_resolved.connect(func(shooter, target, coord, result, sunk_cells, ship_id):
		_on_shot(game_id, shooter, target, coord, result, sunk_cells, ship_id)
	)
	game.timers_updated.connect(func(p1, p2):
		_on_timers(game_id, p1, p2)
	)


func _on_shot(game_id: int, shooter: Player, target: Player, coord: Vector2i, result: Shot.ShotResult, sunk_cells: Array, ship_id: int) -> void:
	var game: Game = get_game_by_id(game_id)
	
	game.shot_history.append({
		"shooter": shooter.peer_id,
		"x": coord.x,
		"y": coord.y,
		"result": result,
		"sunk_cells": sunk_cells,
		"ship_id": ship_id,
		"shooter_name": shooter.name
	})
	
	for player in get_players_of_game(game_id):
		# Send the event to each player in the game
		API.send(
			SendableAPIMessage.new(
				"Game.shot",
				[
					float(game_id),
					float(coord.x),
					float(coord.y),
					float(result),       	  # shot result
					float(shooter.peer_id),   # who fired
					float(target.peer_id ),   # who was targeted
					sunk_cells,				  # if the boat has sunk, his cells
					float(ship_id) 			  # id of the sunked ship or -1
				]
			),
			player.peer_id
		)


func _on_timers(game_id: int, p1_time: float, p2_time: float) -> void:
	var game: Game = get_game_by_id(game_id)
	if game == null:
		return

	var current_player: Player = game.get_current_player()
	var current_peer_id: int = current_player.peer_id

	for player in get_players_of_game(game_id):
		# Send the updated timer values to each player
		API.send(
			SendableAPIMessage.new(
				"Game.timers",
				[
					float(game_id),
					p1_time,
					p2_time,
					float(current_peer_id)
				]
			),
			player.peer_id
		)


func _on_game_ended(game_id: int, winner: Player, reason: String = "normal") -> void:
	var game := get_game_by_id(game_id)
	var players := get_players_of_game(game_id)

	for player in players:
		var winner_peer: int = (winner.peer_id if winner != null else -1)
		var player_reason := reason

		if reason == "resume_refused":
			if player == winner:
				player_reason = "normal"
			else:
				player_reason = "resume_refused"

		API.send(
			SendableAPIMessage.new(
				"Game.ended",
				[
					float(game_id),
					float(winner_peer),
					player_reason
				]
			),
			player.peer_id
		)

	for p in players:
		if p == null:
			continue

		p.game = null

		if p.is_connected("played", game._on_player_played):
			p.disconnect("played", game._on_player_played)

	if game.has_method("cleanup"):
		game.cleanup()

	destroy_game(game_id)


func _on_player_disconnected(player: Player) -> void:
	if player == null:
		return

	var game: Game = player.game
	if game == null:
		return
	
	var game_id: int = _find_game_id(game)
	if game_id == -1:
		return

	disconnected_players[player.name] = game_id

	var players := get_players_of_game(game_id)

	var all_disconnected := true
	for p in players:
		if not disconnected_players.has(p.name):
			all_disconnected = false
			break

	if all_disconnected:
		game._end_game(null)
		destroy_game(game_id)
		for p in players:
			disconnected_players.erase(p.name)
		return

	game.on_player_disconnected(player)

	for p in players:
		if p != player:
			API.send(
				SendableAPIMessage.new(
					"Game.playerDisconnected",
					[
						float(game_id),
						float(player.peer_id)
					]
				),
				p.peer_id
			)


func on_player_reconnected(new_player: Player) -> void:
	if not disconnected_players.has(new_player.name):
		return

	var game_id: int = disconnected_players[new_player.name]
	var game := get_game_by_id(game_id)
	if game == null:
		return

	var old_player: Player = null

	if game.player1 and game.player1.name == new_player.name:
		old_player = game.player1
		game.player1 = new_player

	elif game.player2 and game.player2.name == new_player.name:
		old_player = game.player2
		game.player2 = new_player

	if old_player == null:
		return

	new_player.board = old_player.board
	new_player.game = game
	new_player.party = old_player.party

	if new_player.is_connected("played", game._on_player_played):
		new_player.disconnect("played", game._on_player_played)

	new_player.connect("played", game._on_player_played)

	disconnected_players.erase(new_player.name)

	game.on_player_reconnected(new_player)

	API.send(
		SendableAPIMessage.new(
			"Game.offerResume",
			[ float(game_id) ]
		),
		new_player.peer_id
	)


func start_bot_game(player: Player) -> void:
	var game_id := next_game_id
	next_game_id += 1

	var game := Game.new()
	game.use_timers = false
	games[game_id] = game
	add_child(game)

	game.add_player(player)

	var bot := BotPlayer.new("BOT", -1)
	game.add_player(bot)

	_connect_game_signals(game, game_id)

	game.start()

	var board_data := player.board.to_network_array()

	API.send(
		SendableAPIMessage.new(
			"Game.start",
			[
				float(game_id),
				player.name,
				"BOT",
				float(player.peer_id),
				0.0,
				0.0,
				board_data
			]
		),
		player.peer_id
	)


func _api_start_bot_game(player: Player) -> void:
	start_bot_game(player)
