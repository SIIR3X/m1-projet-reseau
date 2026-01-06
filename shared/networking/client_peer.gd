## Class that describes a peer definition.
## Contains all the necessary fields to map a TCP socket, a UDP packet, a timestamp and the associated ClientID.
class_name ClientPeer extends RefCounted

# VARIABLES

## The TCP socket.
var tcp: PacketPeerStream = null

## The associated latest UDP packet.
var udp: PacketPeerUDP = null

## The timestamp of the latest interaction.
var last_received: float = Time.get_unix_time_from_system()

## ClientID.
var id: int

# CONSTRUCTION

func _init(id_: int, tcp_: PacketPeerStream = null, udp_: PacketPeerUDP = null) -> void:
	tcp = tcp_
	udp = udp_
	id = id_

# METHODS

func close() -> void:
	# Closes the UDP socket.
	if udp:
		udp.close()
		
	# Closes the TCP socket if necessary.
	if tcp:
		var socket: StreamPeerTCP = tcp.stream_peer
	
		if not ConnectionBase.is_socket_still_connected(socket):
			socket.disconnect_from_host()