class_name ClientConnection extends ConnectionBase

# CONSTANTS

const UDP_PACKET_TIMEOUT: float = 5.0

# VARIABLES

## Previous connection state. Defaults to false.
var _previous_connection_state: bool = false

## TCP socket used to connect to the server.
var _tcp_peer: PacketPeerStream = PacketPeerStream.new()

## UDP socket used to connect to the server.
var _udp_peer: PacketPeerUDP = PacketPeerUDP.new()

## Client ID.
var client_id: int = -1

## UDP handshake timer.
var _udp_handshake_timer: Timer = Timer.new()

## Describes whether or not the UDP handshake finalized.
var _is_udp_matched: bool = false

# SIGNALS

## The client just got connected to the server.
signal connected_to_server()

## The client got disconnected from the server.
signal disconnected_from_server()

## The server issued a message.[br]
## - message : received message.
signal message_received(message: ReceivedPacketMessage)

# CONSTRUCTION

func _init(server_address_: String, tcp_port_: int, udp_port_: int) -> void:
	super(server_address_, tcp_port_, udp_port_)
	
	# Sets up packets.
	var _sock: StreamPeerTCP = StreamPeerTCP.new()
	_tcp_peer.stream_peer = _sock
	
	# Sets up sockets.
	connect_to_server()

# ENGINE

func _ready() -> void:
	_udp_handshake_timer.name = "UDPHandshakeTimer"
	add_child(_udp_handshake_timer)
	
	# Sets it up.
	_udp_handshake_timer.wait_time = UDP_PACKET_TIMEOUT
	_udp_handshake_timer.one_shot = false

func _process(_delta: float) -> void:
	# Socket polling.
	(_tcp_peer.stream_peer as StreamPeerTCP).poll()

	# Connection state.
	_handle_connection_state()

	# Message reception handle.
	_handle_tcp_new_packets()
	_handle_udp_new_packets()

# METHODS

## Checks whether the client is still connected to the remote authority.
func is_client_connected() -> bool:
	# Checks the socket connection.
	return is_socket_still_connected(_tcp_peer.stream_peer as StreamPeerTCP)

## Ensures connection to the server.
func connect_to_server() -> Error:
	if is_client_connected():
		return Error.ERR_ALREADY_IN_USE

	# TCP connection.
	var err: Error = (_tcp_peer.stream_peer as StreamPeerTCP).connect_to_host(server_address, tcp_port)
	
	if err != Error.OK:
		return err
	
	# UDP connection.
	err = _udp_peer.connect_to_host(server_address, udp_port)
	
	return err

## Sends the given data to a dedicated client, using a specified method.
func send(packet: SendablePacketMessage, method: NetworkService.TransmissionMethod) -> Error:
	output("Sent message \"%s\" to server (Payload : %s)" % [str(packet.data), str(packet.to_dictionary())])

	if method == NetworkService.TransmissionMethod.METHOD_TCP:
		# TCP
		var socket: StreamPeerTCP = _tcp_peer.stream_peer
		
		# Polling.
		socket.poll()

		# Client is disconnected.
		if not is_socket_still_connected(socket):
			return Error.ERR_CONNECTION_ERROR
			
		return _tcp_peer.put_packet(packet.to_utf8_buffer())
	else:
		# UDP
		return _udp_peer.put_packet(packet.to_utf8_buffer())

# Connection state.

## Handles the connection state of the TCP socket.
func _handle_connection_state() -> void:
	# Polling for server disconnection.
	var current_state: bool = is_socket_still_connected(_tcp_peer.stream_peer as StreamPeerTCP)

	if _previous_connection_state != current_state and _is_udp_matched:
		_previous_connection_state = current_state
	
		# Disconnection.
		if current_state == false:
			# The peer is disconnected altogether.
			_udp_peer.close()
			
			output("Disconnected from server %s" % server_address)
			disconnected_from_server.emit()
			
		# Connection.
		else:
			output("Connected to server %s" % server_address)
			connected_to_server.emit()

# Incoming packets

## Accepts new incoming TCP packets.
func _handle_tcp_new_packets() -> void:
	var socket: StreamPeerTCP = _tcp_peer.stream_peer
	
	# If the client got suddenly disconnected, we skip.
	if not is_socket_still_connected(socket):
		return
	
	# Polling the socket.
	socket.poll()
	
	# We go through all the available packets.
	while _tcp_peer.get_available_packet_count() > 0:
		# Handles the message.
		_handle_new_packets(ReceivedPacketMessage.new(_tcp_peer.get_packet()))

## Accepts new incoming UDP packets.
func _handle_udp_new_packets() -> void:
	# Cycles through all the packets of this peer.
	while _udp_peer.get_available_packet_count() > 0:
		# Handles the message.
		_handle_new_packets(ReceivedPacketMessage.new(_udp_peer.get_packet()))

		
## Common message handle.
func _handle_new_packets(packet: ReceivedPacketMessage) -> void:
	# Message verification.
	if not packet.is_message_compliant():
		return
		
	# Computation.
	packet.compute()
	
	# ClientID attribution.
	match packet.type:
		# If the request is a discover.
		NetworkService.REQUEST_CLIENT_ID_DISCOVER:
			_attribute_client_id(packet)
	
		# If the request is a UDP ack.
		NetworkService.REQUEST_UDP_ACKNOWLEDGE:
			_finalize_connection()
		
		# All the rest.	
		_:
			output("Received message \"%s\" from server (Payload : %s)" % [str(packet.data), str(packet.message)])
			message_received.emit(packet)
	
# Client ID attribution.

## Attributes the client_id.
func _attribute_client_id(packet: ReceivedPacketMessage) -> void:
	# If unattributed.
	if client_id < 0  and packet.data >= 0:
		# Assigns the client_id
		client_id = packet.data
		output("Received client id from server, id = %d" % client_id)
		
		# Sends back answer & starts periodic timer.
		if not _is_udp_matched:
			_udp_handshake_timer.timeout.connect(_on_udp_handshake_timer_timeout)
			_on_udp_handshake_timer_timeout()
		
			_udp_handshake_timer.start()

func _finalize_connection() -> void:
	# If attributed & acknowledgment.
	if client_id >= 0:
		# Stops periodic sends.
		_udp_handshake_timer.stop()
		_udp_handshake_timer.timeout.disconnect(_on_udp_handshake_timer_timeout)
		
		# UDP is matched. This line will trigger the connection event on its own.
		_is_udp_matched = true

## Output prefix.
func _get_output_prefix() -> String:
	var id: int = NetworkService.client_connection.client_id
	
	if id >= 0:
		return "CLIENT %d" % id
		
	return "CLIENT"

# CALLBACKS

func _on_udp_handshake_timer_timeout() -> void:
	# Sends the UDP discover packet.
	var udp_transmission: SendablePacketMessage = SendablePacketMessage.new(
		NetworkService.REQUEST_UDP_INITIAL_HANDSHAKE,
		client_id,
		client_id,
	)
	
	send(udp_transmission, NetworkService.TransmissionMethod.METHOD_UDP)
