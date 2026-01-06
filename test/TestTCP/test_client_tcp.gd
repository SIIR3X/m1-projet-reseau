extends Node

const PORT: int = 9111
const ADDRESS: String = "127.0.0.1"

var socket: StreamPeerTCP = StreamPeerTCP.new()

func _ready() -> void:
	socket.connect_to_host(ADDRESS, PORT)
	socket.poll()
	
	socket.put_string("Bonsoir")