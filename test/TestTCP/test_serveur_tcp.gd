extends Node

const PORT: int = 9111
const ADDRESS: String = "127.0.0.1"

var server: TCPServer = TCPServer.new()
var sockets: Array[PacketPeerStream] = []

func _ready() -> void:
	# Listen to the desired port & address.
	server.listen(PORT, ADDRESS)

	prints("Server bound to port", PORT)
	prints("Attention! Requests sent before this line were discarded ==================")
	
func _process(_dt: float) -> void:
	# Takes all the connections (if any).
	while server.is_connection_available():
		var socket: StreamPeerTCP = server.take_connection()
		
		# To guarantee the reception of a packet, we can use PacketPeerStream. TCP sends raw bytes, and doesn't guarantee
		# the end of a received packet.
		var peer: PacketPeerStream = PacketPeerStream.new()
		peer.stream_peer = socket
		
		# We append the packet stream in the list.
		sockets.append(peer)
		
	# The strategy doesn't use threads here. We could parallelize each client to optimize a bit. Here each packet_stream
	# has to be polled, & we receive all data from it in case a packet exists.
	# For better efficiency, we can use the "interlocuteur" technique from Domic62.
	for peer: PacketPeerStream in sockets:
		var socket: StreamPeerTCP = peer.stream_peer as StreamPeerTCP
		
		# Polling to update the socket's status. Does not have the same effect than UDPServer.poll()
		socket.poll()

		# If any available FINISHED packets.
		while peer.get_available_packet_count() > 0:
			# We get the bytes of the packet
			var packed_bytes: PackedByteArray = peer.get_packet()
			
			print("Received packet from %s:%s : \"%s\"" % [socket.get_connected_host(), socket.get_connected_port(), packed_bytes.get_string_from_utf8()])
		
