extends Node

# CONSTANTS

## Creator name segment.
const PARTY_CREATOR_NAME: String = "creator_name"

## ID segment.
const PARTY_ID: String = "id"

## Required password segment.
const PARTY_PASSWORD_TYPE: String = "password_type"

## Required password.
const PASSWORD_TYPE_REQUIRED: String = "required"

## No password.
const PASSWORD_TYPE_NONE: String = "none"

# VARIABLES

## Stored parties.
var _parties: Dictionary[int, Party] = {}

## Next party ID.
var _next_game_id: int = 0

# SIGNALS

## Signal giving out all the parties.
signal party_list_received(list: Array[Party])

## Signal that tells the client the party was created.
signal created_party_status(is_created: bool)

## Signal giving out players that want to play together.
signal initiate_game(player1: Player, player2: Player)

# ENGINE

func _ready() -> void:
	Players.player_removed.connect(_server_remove_party)

# METHODS

## Client method to fetch lists.
func fetch_list() -> void:
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.get", [])
	API.send(ret)

## Client wants to create a party.
func create_party(party_code: String) -> void:
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.create", [party_code])
	API.send(ret)

## Client wants to join a party.
func join_party(party_id: int, party_code: String) -> void:
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.join", [party_id, party_code])
	API.send(ret)

## Client wants to remove the party.
func remove_party() -> void:
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.remove", [])
	API.send(ret)

## Server API command to fetch party list.
func _server_get_party_list(player: Player) -> void:
	# Serializing.
	var list: Array[Dictionary] = []
	
	for party: Party in _parties.values():
		if party.creator != player:
			list.append({
				PARTY_CREATOR_NAME: party.creator_name,
				PARTY_ID: party.id,
				PARTY_PASSWORD_TYPE: PASSWORD_TYPE_REQUIRED if not party.password.is_empty() else PASSWORD_TYPE_NONE,
			})
	
	# Sending.
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.get", [list])
	API.send(ret, player.peer_id)

## Server API command to create a party.
func _server_create_party(player: Player, party_code: String) -> void:
	# The player must have no ongoing party.
	if player.party:
		return
	
	var party_id: int = _next_game_id
	_next_game_id += 1
	
	var party: Party = Party.new(player.name, party_id, party_code)
	_parties[party_id] = party
	
	player.party = party
	party.creator = player
	
	# Returns success
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.partyStatus", [true])
	API.send(ret, player.peer_id)

## Server API command to join a party by owner's username.
func _server_join_party(player: Player, party_id: float, party_code: String) -> void:
	# The user can't be in a party creation state, so no party should be registered from them.
	if player.party or player.game:
		return
	
	# The party doesn't exist or has no creator.
	var party: Party = _parties.get(int(party_id))
	
	if not party or not party.creator:
		return
	
	# If password protected, verify password match.
	if not party.password.is_empty() and party.password != party_code:
		return
	
	# All good to go. Signal emission so that the GameService can eventually transform the current party.
	initiate_game.emit(party.creator, player)
	
	# Party removal (as it is already started).
	party.creator.party = null
	_parties.erase(party.id)
	

## Server API command to remove a party.
func _server_remove_party(player: Player) -> void:
	# The player must have a party.
	if not player.party:
		return
	
	# The player wants to delete another user's party.
	if player.party.creator != player:
		return
	
	# Remove the party from everywhere.
	var party: Party = player.party
	player.party = null
	_parties.erase(party.id)
	
	# Returns success
	var ret: SendableAPIMessage = SendableAPIMessage.new("Lobbies.partyStatus", [false])
	API.send(ret, player.peer_id)

## Client API command to fetch party lists.
func _client_get_party_list(list: Array) -> void:
	# Parses the parties.
	var res: Array[Party] = []
	
	for party_dict: Dictionary in list:
		var creator_name: String = party_dict.get(PARTY_CREATOR_NAME, "")
		var party_id: float = party_dict.get(PARTY_ID, -1.0)
		var password_type: String = party_dict.get(PARTY_PASSWORD_TYPE, "")
		
		# Invalid.
		if creator_name.is_empty() or party_id < 0 or password_type.is_empty():
			continue
		
		var party: Party = Party.new(creator_name, int(party_id), "" if password_type == PASSWORD_TYPE_NONE else "required")
		res.append(party)
	
	# Emission for further use.
	party_list_received.emit(res)

## Client API command to get party creation confirmation.
func _client_party_status(status: bool) -> void:
	created_party_status.emit(status)
