extends Service

var players: Dictionary[int, Player] = {}  # peer_id -> Player

var is_logged_in: bool = false
var local_name: String

# Emitted when a new player joins the server
signal player_added(player: Player)

# Emitted when a player leaves or disconnects from the server
signal player_removed(player: Player)

func _init() -> void:
	players = {}

func _ready() -> void:
	if is_server():
		NetworkService.server_connection.client_connected.connect(_on_client_connected)
		NetworkService.server_connection.client_disconnected.connect(_on_client_disconnected)

func add_player(peer_id: int, plr_name: String = "") -> Player:
	# Prevent duplicate
	if players.has(peer_id):
		return players[peer_id]

	# Create a new 'Player'
	var player: Player = Player.new(plr_name if plr_name != "" else "Player_%d" % peer_id)
	player.peer_id = peer_id
	players[peer_id] = player

	emit_signal("player_added", player)
	return player

func remove_player(peer_id: int) -> void:
	# Ignore if the player doesn't exist
	if not players.has(peer_id):
		return
	
	# Remove the player from the dictionary
	var player: Player = players[peer_id]
	players.erase(peer_id)

	emit_signal("player_removed", player)

func get_player(peer_id: int) -> Player:
	return players.get(peer_id, null)

func get_player_by_username(username: String) -> Player:
	for plr: Player in players.values():
		if plr.name == username:
			return plr
	
	return null

func get_all_players() -> Array[Player]:
	return players.values()

# CALLBACKS

func _on_client_connected(id: int, _peer: PacketPeerStream) -> void:
	add_player(id)

func _on_client_disconnected(id: int, _peer: PacketPeerStream) -> void:
	remove_player(id)
