extends Service

# SIGNALS

## A message was received.
signal chat_received(player_name: String, message: String)

# METHODS

## The server received a message.
func _server_message_received(player: Player, message: String) -> void:
	# Checks if the player is within a game.
	if not player.game:
		return

	# Emits message.
	chat_received.emit(player.name, message)

	# Fires to all clients in the game.
	for plr: Player in [player.game.player1, player.game.player2]:
		var msg: SendableAPIMessage = SendableAPIMessage.new(
			"Chat.send", [player.name, message]
		)
	
		API.send(msg, plr.peer_id)

## The client received a message.
func _client_chat_received(player_name: String, message: String) -> void:
	# Emits message.
	chat_received.emit(player_name, message)