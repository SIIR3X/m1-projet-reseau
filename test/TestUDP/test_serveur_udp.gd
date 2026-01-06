extends Node

const ADDRESS: String = "127.0.0.1"
const PORT: int = 9222

var server: UDPServer = UDPServer.new()

var previous_peer: PacketPeerUDP = null

func _ready() -> void:
	# Put the PORT & address (optional)
	server.listen(PORT, ADDRESS)
	
	prints("Server bound to port", PORT)
	prints("Attention! Requests sent before this line were discarded ==================")
	
func _process(_dt: float) -> void:
	# Fetches all attempts to reach the server. If not present, the server will not actualize the packet reception list.
	server.poll()

	# If a packet was found (represented by a PacketPeerUDP, so it's the packet, not a connection)
	while server.is_connection_available():
		# Takes the packet associated to the packet received, in FIFO order. All peer info are kept
		var peer: PacketPeerUDP = server.take_connection()
		
		print("Difference between old peer (%s) and new peer (%s) : %s" % [
			"null" if not previous_peer else str(previous_peer.get_instance_id()),
			str(peer.get_instance_id()),
			str(is_same(previous_peer, peer))
		])
		
		previous_peer = peer
	
		# Takes the data as a PacketByteArray (array of bytes)
		while peer.get_available_packet_count() > 0:
			var packed_byte: PackedByteArray = peer.get_packet()
		
			print("Received packet from %s:%s : \"%s\"" % [peer.get_packet_ip(), peer.get_packet_port(), packed_byte.get_string_from_utf8()])
	
		peer.close()
	