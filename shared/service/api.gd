extends Service

# VARIABLES

## Root of the chain of responsibility.
var _cor_root: ArgumentVerificationCORRoot

## All calls.
var _calls: Dictionary[String, APIRegistry] = {}

## All temporary calls.
var _temporary_calls: Dictionary[String, APIRegistry] = {}

# CONSTRUCTION

func _init() -> void:
	# COR pattern init.
	_cor_root = preload("uid://ds8btlcii3kwc").instantiate()
	add_child(_cor_root)
	
func _ready() -> void:
	# We register commands.
	_register()
		
	# Listening to incoming messages.
	if is_server():
		NetworkService.server_connection.message_received.connect(_on_server_message_received)
	else:
		NetworkService.client_connection.message_received.connect(_on_client_message_received)

# METHODS

## Get the API-equivalent type for an argument.
func get_argument_type(arg: Variant) -> String:
	return _cor_root.get_type(arg)

## Sends an API call.
func send(api_call: SendableAPIMessage, client_id: int = -1, method: NetworkService.TransmissionMethod = NetworkService.TransmissionMethod.METHOD_TCP) -> void:
	if not NetworkService.is_server():
		client_id = NetworkService.client_connection.client_id

	# Wraps everything in a SendablePacketMessage.
	var msg: SendablePacketMessage = SendablePacketMessage.new(
		NetworkService.REQUEST_API_CALL,
		api_call.to_dictionary(),
		client_id,
	)
	
	# Sends the message.
	NetworkService.send(msg, method)

# Messages handles.

# Command registry.

## Registers all API commands.
func _register() -> void:
	# Example :
	# _register_command(LoginService.login, [APIRegistry.API_TYPE_STRING, APIRegistry.API_TYPE_STRING])

	if is_server():
		# Registers server commands.
		
		# Registers protected commands first.
		_register_commands(true, func():
			# Hosts API tests.
			_register_command("API.test1", test1, [])
			_register_command("API.test2", test2, [APIRegistry.API_TYPE_FLOAT, APIRegistry.API_TYPE_STRING])

			# Lobby.
			_register_command("Lobbies.get", LobbyService._server_get_party_list, [])
			_register_command("Lobbies.create", LobbyService._server_create_party, [APIRegistry.API_TYPE_STRING])
			_register_command("Lobbies.join", LobbyService._server_join_party, [APIRegistry.API_TYPE_FLOAT, APIRegistry.API_TYPE_STRING])
			_register_command("Lobbies.remove", LobbyService._server_remove_party, [])

			# Command: Player.hit with two integers (x, y)
			_register_command("Player.hit", GameService._api_player_hit, [
				APIRegistry.API_TYPE_FLOAT, # x is a number
				APIRegistry.API_TYPE_FLOAT  # y is a number
			])
		
			# Chat service.
			_register_command("Chat.send", Chat._server_message_received, [APIRegistry.API_TYPE_STRING])

			# Bot Game
			_register_command("Game.startBot", GameService._api_start_bot_game, [])
		)
		
		# Registers public commands afterwards.
		_register_commands(false, func():
			# Login service.
			_register_command("Login.login", LoginService._server_account_login, [APIRegistry.API_TYPE_STRING, APIRegistry.API_TYPE_STRING])
			_register_command("Login.signup", LoginService._server_account_signup, [APIRegistry.API_TYPE_STRING, APIRegistry.API_TYPE_STRING])
			_register_command("Login.logout", LoginService._server_account_logout, [])

			_register_command("Game.syncState", GameService._client_game_sync_state, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_STRING, # player1 name
				APIRegistry.API_TYPE_STRING, # player2 name
				APIRegistry.API_TYPE_FLOAT,  # player1 peer_id
				APIRegistry.API_TYPE_FLOAT,  # player2 peer_id
				APIRegistry.API_TYPE_FLOAT,  # p1_time
				APIRegistry.API_TYPE_FLOAT,  # p2_time
				APIRegistry.API_TYPE_ARRAY,  # board_data
				APIRegistry.API_TYPE_FLOAT,  # current_turn_peer_id
				APIRegistry.API_TYPE_ARRAY
			])

			_register_command("Game.resumeRequest", GameService._api_resume_request, [
				APIRegistry.API_TYPE_FLOAT  # game_id
			])

			_register_command("Game.resumeRefused", GameService._api_resume_refused, [
				APIRegistry.API_TYPE_FLOAT  # game_id
			])
		)

	else:
		# Registers client commands.
		_register_commands(false, func():
			# Chat service.
			_register_command("Chat.send", Chat._client_chat_received, [APIRegistry.API_TYPE_STRING, APIRegistry.API_TYPE_STRING])
			
			# Login service.
			_register_command("Login.login", LoginService._client_account_login, [APIRegistry.API_TYPE_STRING])

			# Lobby.
			_register_command("Lobbies.get", LobbyService._client_get_party_list, [APIRegistry.API_TYPE_ARRAY])
			_register_command("Lobbies.partyStatus", LobbyService._client_party_status, [APIRegistry.API_TYPE_BOOL])
			
			# Game start
			_register_command("Game.start", GameService._client_game_start, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_STRING, # player1 name
				APIRegistry.API_TYPE_STRING, # player2 name
				APIRegistry.API_TYPE_FLOAT,  # player1 peer_id
				APIRegistry.API_TYPE_FLOAT,  # player1 timer
				APIRegistry.API_TYPE_FLOAT,  # player2 timer
				APIRegistry.API_TYPE_ARRAY   # local player board
			])

			# Shot
			_register_command("Game.shot", GameService._client_game_shot, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_FLOAT,  # x
				APIRegistry.API_TYPE_FLOAT,  # y
				APIRegistry.API_TYPE_FLOAT,  # shot result
				APIRegistry.API_TYPE_FLOAT,  # shooter peer id
				APIRegistry.API_TYPE_FLOAT,  # target peer id
				APIRegistry.API_TYPE_ARRAY,  # sunk_cells
				APIRegistry.API_TYPE_FLOAT   # sunked ship_id
			])
			
			# Timers
			_register_command("Game.timers", GameService._client_game_timers, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_FLOAT,  # p1_time
				APIRegistry.API_TYPE_FLOAT,  # p2_time
				APIRegistry.API_TYPE_FLOAT   # current player peer_id
			])
			
			# Game end
			_register_command("Game.ended", GameService._client_game_ended, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_FLOAT,  # winner_peer_id
				APIRegistry.API_TYPE_STRING
			])

			# Player disconnected
			_register_command("Game.playerDisconnected", GameService._client_game_player_disconnected, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_FLOAT   # peer_id of disconnected player
			])

			# Game resume (player reconnected)
			_register_command("Game.resume", GameService._client_game_resume, [
				APIRegistry.API_TYPE_FLOAT   # game_id
			])

			# Offer resume
			_register_command("Game.offerResume", GameService._client_game_offer_resume, [
				APIRegistry.API_TYPE_FLOAT   # game_id
			])

			_register_command("Game.syncState", GameService._client_game_sync_state, [
				APIRegistry.API_TYPE_FLOAT,  # game_id
				APIRegistry.API_TYPE_STRING, # p1_name
				APIRegistry.API_TYPE_STRING, # p2_name
				APIRegistry.API_TYPE_FLOAT,  # p1_peer_id
				APIRegistry.API_TYPE_FLOAT,  # p2_peer_id
				APIRegistry.API_TYPE_FLOAT,  # p1_time
				APIRegistry.API_TYPE_FLOAT,  # p2_time
				APIRegistry.API_TYPE_ARRAY,  # board data
				APIRegistry.API_TYPE_FLOAT,  # current turn peer id
				APIRegistry.API_TYPE_ARRAY
			])
			
			# A notification is received
			_register_command("Notification.send", NotificationService._client_message_received, [APIRegistry.API_TYPE_STRING])
		)

func _register_commands(secured: bool, callable: Callable) -> void:
	# Runs everything.
	callable.call()
	
	# Puts security level accordingly.
	for cmd: String in _temporary_calls:
		_temporary_calls[cmd].secured = secured
	
	# Migrates.
	_calls.merge(_temporary_calls, true)
	
	# Clears tmp.
	_temporary_calls.clear()

## Registers a single API command.
func _register_command(command: String, callable: Callable, args_types: Array[String]) -> void:
	_temporary_calls[command] = APIRegistry.new(callable, args_types)

# Tests.

## Test method 1.
func test1(player: Player) -> void:
	print("Test API call received from client %d" % player.peer_id)

## Test method 2.
func test2(player: Player, a: float, b: String) -> void:
	print("Test API call received from client %d with a = %d and b = %s" % [player.peer_id, a, b])

func _create_api_message(message: ReceivedPacketMessage) -> ReceivedAPIMessage:
	# Gets segments.
	var api_call: ReceivedAPIMessage = ReceivedAPIMessage.new(message)
	
	# If invalid, denies it.
	if not api_call.is_data_compliant():
		return null
	
	# Computations.
	api_call.compute()
	
	return api_call

## Returns the associated registry with argument type check.
func _get_api_registry(api_call: ReceivedAPIMessage) -> APIRegistry:
	# Checks key existence.
	var registry: APIRegistry = _calls.get(api_call.api_command)
	
	if not registry:
		return null
	
	# Checks args validity.
	if not registry.verify_arguments_types_match(api_call.arguments):
		return null
	
	return registry

# CALLBACKS

## Handles received messages from the server.
func _on_server_message_received(_id: int, _peer: PacketPeer, message: ReceivedPacketMessage) -> void:
	# Checks message. At that point the message is guaranteed to be a valid format, at least for the root of it.
	if message.type != NetworkService.REQUEST_API_CALL:
		return
		
	# Grabs player.
	var player: Player = null
	player = Players.get_player(message.client_id)
	
	# The player does not exist : invalid socket connection.
	if not player:
		return
	
	# Gets segments.
	var api_call: ReceivedAPIMessage = _create_api_message(message)
	
	# If invalid format.
	if not api_call:
		return
	
	# Grabs command.
	var registry: APIRegistry = _get_api_registry(api_call)
	
	# Did not match any command.
	if not registry:
		return
	
	# Check account connection based on the registry's capabilities.
	if registry.secured and not player.is_logged_in:
		return
	
	# Put player as first to arglist if on server.
	api_call.arguments.push_front(player)
	
	# Calls the provided API command.
	registry.execute(api_call.arguments)

## Incoming API calls received by the client.
func _on_client_message_received(message: ReceivedPacketMessage) -> void:
	# Checks message. At that point the message is guaranteed to be a valid format, at least for the root of it.
	if message.type != NetworkService.REQUEST_API_CALL:
		return
		
	# Gets segments.
	var api_call: ReceivedAPIMessage = _create_api_message(message)
	
	# If invalid format.
	if not api_call:
		return
	
	# Grabs command.
	var registry: APIRegistry = _get_api_registry(api_call)
	
	# Did not match any command.
	if not registry:
		return
	
	# Calls the provided API command.
	registry.execute(api_call.arguments)
