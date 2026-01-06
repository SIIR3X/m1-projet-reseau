extends Node

const SRC_PORT: int = 9333

const ADDRESS: String = "127.0.0.1"
const PORT: int = 9222

var client: PacketPeerUDP = PacketPeerUDP.new()

func _ready() -> void:
	# Connecting to host.
	client.connect_to_host(ADDRESS, PORT)

	# Sends the packets. This may fail as the server was not connected at the time it was sent.
	# Use a debounce pattern to determine whether or not a packet is/is not received.
	# This can be done if the server replies with a few bytes.
	client.put_packet("Hello this is my first message !".to_utf8_buffer())	
	client.put_packet("Hi, another packet".to_utf8_buffer())
	
	prints("Client sent the bytes !")