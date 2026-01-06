@abstract class_name ConnectionBase extends Node

# CONSTANTS

## Address of the server.
var server_address: String

## Port of the TCP server.
var tcp_port: int

## Port of the UDP server.
var udp_port: int

# CONSTRUCTION

func _init(server_address_: String, tcp_port_: int, udp_port_: int) -> void:
	server_address = server_address_
	tcp_port = tcp_port_
	udp_port = udp_port_

# METHODS

## Method of sending a message to a remote peer through a dedicated method.
@abstract func send(packet: SendablePacketMessage, method: NetworkService.TransmissionMethod) -> Error

## Determines whether a socket is still connected.
static func is_socket_still_connected(socket: StreamPeerTCP) -> bool:
	return socket.get_status() == StreamPeerTCP.STATUS_CONNECTED

## Gets the output prefix when outputting.
@abstract func _get_output_prefix() -> String

## Outputs a message with the context.
func _output(prt_fct: Callable, prefix: String, msg: String) -> void:
	if OS.is_debug_build():
		var t: Dictionary = Time.get_datetime_dict_from_system()
		
		prt_fct.call("[%s][%s - %d:%d:%d]: %s" % [
			_get_output_prefix(),
			prefix,
			t.hour, t.minute, t.second,
			msg
		])

## Outputs an info.
func output(msg: String) -> void:
	_output(print, "INFO", msg)

## Outputs an error.
func error(msg: String) -> void:
	_output(push_error, "ERROR", msg)
