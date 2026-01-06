class_name ReceivedPacketMessage extends PacketMessage

# VARIABLES

## Received packet.
var packet_content: PackedByteArray

## Produced message.
var message: Variant = null

## Whether or not the message parsing was a success.
var parsing_error: Error = Error.FAILED

# CONSTRUCTION

func _init(packet_content_: PackedByteArray) -> void:
	packet_content = packet_content_
	
	var json_parse: JSON = JSON.new()
	parsing_error = json_parse.parse( packet_content.get_string_from_utf8() )		
	
	if parsing_error == Error.OK:
		message = json_parse.get_data()

# METHODS

func is_parsing_valid() -> bool:
	return parsing_error == Error.OK

## Whether the message is a valid Godot dictionary or not.
func is_message_dict() -> bool:
	return is_parsing_valid() and message is Dictionary

## Whether or not the message has [constant SEGMENT_REQUEST_TYPE] and [constant SEGMENT_DATA].
func is_message_compliant() -> bool:
	return is_message_dict() \
		and SEGMENT_REQUEST_TYPE in message \
		and SEGMENT_DATA in message

## Whether or not the message has [constant SEGMENT_CLIENT_ID], [constant SEGMENT_REQUEST_TYPE] and [constant SEGMENT_DATA] fields.
func is_message_server_compliant() -> bool:
	return is_message_compliant() \
		and SEGMENT_CLIENT_ID in message

# Computations.

## Computes all basic fields of a message.
func compute() -> void:
	# Commons.
	_compute_request_type_segment()
	_compute_data_segment()

	if Context.is_server():
		# Server side.
		_compute_client_id()

## Grabs the data segment.
func _compute_data_segment() -> void:
	data = message.get(SEGMENT_DATA)
	
func _compute_request_type_segment() -> void:
	type = message.get(SEGMENT_REQUEST_TYPE, "")

## Meant for server usage only. Is used when the message structure follows a client->server communication.
func _compute_client_id() -> void:
	if client_id < 0:
		var id: Variant = message.get(SEGMENT_CLIENT_ID, -1)
	
		if id is float or id is int:
			client_id = int(id)