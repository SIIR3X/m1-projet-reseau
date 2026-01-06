## Class that handles communications between the server (this object) and the different clients.
class_name ServerConnection extends ConnectionBase

# VARIABLES

## TCP server that receives connections.
var _tcp_server: TCPServer = TCPServer.new()

## UDP server that receives datagrams.
var _udp_server: UDPServer = UDPServer.new()

## Counter for IDs.
var _client_id: int = 0

## Stores all PacketPeerStream associated with the TCP server.
var _peers: Dictionary[int, ClientPeer] = {}

# SIGNALS

## A new connection was received.[br]
## - id : ID of the client.[br]
## - peer : received packet peer.
signal client_connected(id: int, peer: PacketPeerStream)

## A connection was terminated.[br]
## - id : ID of the client.[br]
## - peer : disconnected packet peer.
signal client_disconnected(id: int, peer: PacketPeerStream)

## A connection issued a message.[br]
## - id : ID of the client.[br]
## - peer : Connection whose message was sent through.[br]
## - message : received message.
signal message_received(id: int, peer: PacketPeer, message: ReceivedPacketMessage)

# CONSTRUCTION

func _init(server_address_: String, tcp_port_: int, udp_port_: int) -> void:
	super(server_address_, tcp_port_, udp_port_)
	
	# Sets up servers.
	_tcp_server.listen(tcp_port, server_address)
	_udp_server.listen(udp_port, server_address)
	
	output("Server setup on address %s\n- TCP port : %d\n- UDP port : %d\nReady to receive connections" % [
		server_address, tcp_port, udp_port
	])

# ENGINE

func _process(_delta: float) -> void:
	# Polling.
	_udp_server.poll()

	# New sockets handle.
	_handle_tcp_new_sockets()
	_handle_udp_new_sockets()
	
	# Disconnection handle.
	_handle_tcp_disconnections()
	
	# Message reception handle.
	_handle_tcp_new_packets()
	_handle_udp_new_packets()

# METHODS

## Determines whether the client is still registered.[br]
## - id : ID of the client.
## returns whether or not the client is still stored.
func is_client_registered(id: int) -> bool:
	return id in _peers

## Checks if a give client_id is still connected to the server.
func is_client_connected(id: int) -> bool:
	var client_peer: ClientPeer = _get_client_peer_from_id(id)
	
	# The client isn't registered.
	if client_peer == null:
		return false
	
	# If it still exists, checks the socket connection.
	return is_socket_still_connected(client_peer.tcp.stream_peer as StreamPeerTCP)

## Sends the given data to a dedicated client, using a specified method.
func send(packet: SendablePacketMessage, method: NetworkService.TransmissionMethod = NetworkService.TransmissionMethod.METHOD_TCP) -> Error:
	# Finds the proper client back.
	var client_peer: ClientPeer = _get_client_peer_from_id(packet.client_id)
	
	# Client doesn't exist.
	if client_peer == null:
		return Error.ERR_DOES_NOT_EXIST
	
	output("Sent message \"%s\" to client id = %d (Payload : %s)" % [str(packet.data), client_peer.id, str(packet.to_dictionary())])
	
	if method == NetworkService.TransmissionMethod.METHOD_TCP:
		# TCP
		var socket: StreamPeerTCP = client_peer.tcp.stream_peer
		
		# Polling.
		socket.poll()

		# Client is disconnected.
		if not is_socket_still_connected(socket):
			return Error.ERR_CONNECTION_ERROR
			
		return client_peer.tcp.put_packet(packet.to_utf8_buffer())
	else:
		# UDP
		return client_peer.udp.put_packet(packet.to_utf8_buffer())

# All TCP/UDP handles.

# New sockets

## Accepts new incoming TCP connections.
func _handle_tcp_new_sockets() -> void:
	while _tcp_server.is_connection_available():
		# Received socket for current connection.
		var socket: StreamPeerTCP = _tcp_server.take_connection()
		
		# Vraps the socket in a PacketPeerStream.
		var peer: PacketPeerStream = PacketPeerStream.new()
		peer.stream_peer = socket
		
		# Adds the connection at the proper id.
		var client_peer: ClientPeer = _create_client_peer(peer)
		_peers[client_peer.id] = client_peer
		
		# Sends ClientID to client.
		var client_id_transmission: SendablePacketMessage = SendablePacketMessage.new(
			NetworkService.REQUEST_CLIENT_ID_DISCOVER,
			client_peer.id,
			client_peer.id
		)
		
		send(client_id_transmission, NetworkService.TransmissionMethod.METHOD_TCP)
		
		# Emits the signal.
		output("New connection, client id = %d" % client_peer.id)
		client_connected.emit(client_peer.id, peer)
		
## Accepts new incoming UDP sockets.
func _handle_udp_new_sockets() -> void:
	while _udp_server.is_connection_available():
		# Receives peer.
		var peer: PacketPeerUDP = _udp_server.take_connection()
				
		# Finds the ClientPeer object (if any) to make attribution.
		var client_peer: ClientPeer = _handle_udp_socket_attribution(peer)
		
		if client_peer and client_peer.udp == null:
			# We hand out the udp socket if none exists.
			client_peer.udp = peer
			output("Associated new UDP socket for client id = %d" % client_peer.id)
			
			# Sends ACK.
			var ret: SendablePacketMessage = SendablePacketMessage.new(NetworkService.REQUEST_UDP_ACKNOWLEDGE, "", client_peer.id)
			send(ret)
		else:
			# We close the received peer.
			peer.close()
			
## Matches the current unknown udp socket with a potential open TCP socket through ClientID matching. The
## UDP socket should output a valid ClientID.
func _handle_udp_socket_attribution(peer: PacketPeerUDP) -> ClientPeer:
	# We go through all the packets received.
	while peer.get_available_packet_count() > 0:
		# Parses the message.
		var packet: ReceivedPacketMessage = ReceivedPacketMessage.new(peer.get_packet())
		
		# If incorrect, skip the packet.
		if not packet.is_message_server_compliant():
			continue
			
		# Computation.
		packet.compute()
		
		# If not meant for UDP handshake, the request is discarded.
		if packet.type != NetworkService.REQUEST_UDP_INITIAL_HANDSHAKE:
			continue 
			
		# Matches through ClientID.
		var client_peer: ClientPeer = _get_client_peer_from_id(packet.client_id)
		
		if client_peer:
			# A peer was found with matching client.
			return client_peer
			
	# No result.
	return null
		
# Disconnections/cleanups

## Handles cases where TCP clients get disconnected.	
func _handle_tcp_disconnections() -> void:
	for id: int in _peers:
		var client_peer: ClientPeer = _get_client_peer_from_id(id)
		var socket: StreamPeerTCP = client_peer.tcp.stream_peer
		
		# Polling.
		socket.poll()
		
		# If no longer considered connected, we remove the entry.
		if not is_socket_still_connected(client_peer.tcp.stream_peer as StreamPeerTCP):
			# Closes everything.
			client_peer.close()
			
			# Deletion from the dictionary.
			_peers.erase(id)
			
			# Emits the signal.
			output("Client id = %d disconnected" % id)
			client_disconnected.emit(id, client_peer.tcp)

# Incoming packets

## Accepts new incoming TCP packets.
func _handle_tcp_new_packets() -> void:
	for id: int in _peers:
		var client_peer: ClientPeer = _get_client_peer_from_id(id)
		
		# The TCP part should exist as TCP peers determine the existence of such object.
		var peer: PacketPeerStream = client_peer.tcp
		var socket: StreamPeerTCP = peer.stream_peer
	
		# Polling the socket.
		socket.poll()
	
		# If the client got suddenly disconnected, we skip.
		if not is_socket_still_connected(socket):
			continue
	
		# We go through all the available packets.
		while peer.get_available_packet_count() > 0:
			# Handles the message.
			_handle_new_packets(peer, client_peer, ReceivedPacketMessage.new(peer.get_packet()))

## Accepts new incoming UDP packets.
func _handle_udp_new_packets() -> void:
	for id: int in _peers:
		var client_peer: ClientPeer = _get_client_peer_from_id(id)
		
		# The UDP part is checked.
		var peer: PacketPeerUDP = client_peer.udp
		
		# If the UDP socket isn't registered, we skip.
		if peer == null:
			continue
		
		# Cycles through all the packets of this peer.
		while peer.get_available_packet_count() > 0:
			# Handles the message.
			_handle_new_packets(peer, client_peer, ReceivedPacketMessage.new(peer.get_packet()))

## Common segment for message handle.	
func _handle_new_packets(peer: PacketPeer, client_peer: ClientPeer, packet: ReceivedPacketMessage) -> void:
	# If incorrect, skip the packet.
	if not packet.is_message_server_compliant():
		return
		
	# Computation.
	packet.compute()
	
	# ID matching.
	if packet.client_id != client_peer.id:
		return
	
	# Message is emitted.
	_message_received(packet, client_peer, peer)

# Utility methods.

## Creates a ClientPeer with the proper ID.
func _create_client_peer(peer: PacketPeer) -> ClientPeer:
	var id: int = _client_id
	_client_id += 1

	if peer is PacketPeerStream:
		return ClientPeer.new(id, peer, null)
	else:
		return ClientPeer.new(id, null, peer)
	
## Gets the associated PeerDefinition.
func _get_client_peer_from_id(id: int) -> ClientPeer:
	return _peers.get(id)

## Logic of message sending.
func _message_received(packet: ReceivedPacketMessage, client_peer: ClientPeer, peer: PacketPeer) -> void:
	# Update the timestamp.
	client_peer.last_received = Time.get_unix_time_from_system()
	
	# We emit the message if not excluded.
	if not packet.type in NetworkService.EXCLUDED_REQUEST_PROPAGATION:
		output("Received message \"%s\" from client id = %d (Payload : %s)" % [str(packet.data), client_peer.id, str(packet.message)])
		message_received.emit(client_peer.id, peer, packet)

## Output prefix.
func _get_output_prefix() -> String:
	return "SERVER"