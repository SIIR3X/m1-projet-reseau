extends Service

# CONSTANTS

# File sections.

## Cfg file section for networking.
const INET_SECTION: String = "server"

## Server IP address value in the config file.
const SERVER_IP: String = "server_address"

## Server port for TCP server.
const SERVER_TCP_PORT: String = "tcp_port"

## Server port for UDP server.
const SERVER_UDP_PORT: String = "udp_port"

# Requests.

## API call.
const REQUEST_API_CALL: String = "api"

## Message with no structure. Used for testing purposes.
const UNSTRUCTURED_MESSAGE: String = "unstructured_message"

## Client ID discover.
const REQUEST_CLIENT_ID_DISCOVER: String = "client_id_discover"

## UDP initial response.
const REQUEST_UDP_INITIAL_HANDSHAKE: String = "udp_initial_handshake"

## UDP server response.
const REQUEST_UDP_ACKNOWLEDGE: String = "udp_acknowledge"

## List of excluded requests, those which should not be emitted.
const EXCLUDED_REQUEST_PROPAGATION: Array[String] = [
	REQUEST_CLIENT_ID_DISCOVER,
	REQUEST_UDP_INITIAL_HANDSHAKE,
	REQUEST_UDP_ACKNOWLEDGE,
]

# ENUMERATIONS

## Transmission method. Either TCP or UDP.
enum TransmissionMethod {
	## Use of TCP protocol.
	METHOD_TCP,
	
	## Use of UDP protocol.
	METHOD_UDP,
}

# VARIABLES

## Connection used to send, receive messages from the server perspective.
var server_connection: ServerConnection = null

## Connection used to send, receive messages from the client perspective.
var client_connection: ClientConnection = null

## IP address of the server.
var server_ip: String = "176.143.241.121"

## Port for TCP server.
var server_tcp_port: int = 9111

## Port for UDP server.
var server_udp_port: int = 9112

# CONSTRUCTION

func _init() -> void:
	# Opens config file if any.
	var cfg: ConfigFile = ConfigFile.new()
	var path: String = get_exec_dir().path_join("software_" + ("server" if is_server() else "client") + "_config.cfg")
	
	var err: Error = cfg.load(path)
	if err == Error.OK:
		server_ip = cfg.get_value(INET_SECTION, SERVER_IP, server_ip)
		server_tcp_port = cfg.get_value(INET_SECTION, SERVER_TCP_PORT, server_tcp_port)
		server_udp_port = cfg.get_value(INET_SECTION, SERVER_UDP_PORT, server_udp_port)
	
	# Generate the file if it does not exist. Avoids generating it if the project is ran in the editor.
	elif err == ERR_FILE_NOT_FOUND and not is_in_editor():
		cfg.set_value(INET_SECTION, SERVER_IP, server_ip)
		cfg.set_value(INET_SECTION, SERVER_TCP_PORT, server_tcp_port)
		cfg.set_value(INET_SECTION, SERVER_UDP_PORT, server_udp_port)
		
		cfg.save(path)

	if is_server():
		server_connection = ServerConnection.new(server_ip, server_tcp_port, server_udp_port)
	else:
		client_connection = ClientConnection.new(server_ip, server_tcp_port, server_udp_port)
	
	var connection: ConnectionBase = (server_connection as ConnectionBase) if server_connection else (client_connection as ConnectionBase)
	connection.name = "Connection"
	add_child(connection)

# METHODS

func send(packet: SendablePacketMessage, method: TransmissionMethod = TransmissionMethod.METHOD_TCP) -> Error:
	if is_server():
		return server_connection.send(packet, method)
		
	return client_connection.send(packet, method)
