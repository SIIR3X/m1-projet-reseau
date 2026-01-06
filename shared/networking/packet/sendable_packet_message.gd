class_name SendablePacketMessage extends PacketMessage

# CONSTRUCTION

func _init(type_: String, data_: Variant, client_id_: int = -1) -> void:
	type = type_
	data = data_
	client_id = client_id_

# METHODS

## Converts the data to a dictionary.
func to_dictionary() -> Dictionary[String, Variant]:
	if Context.is_server():
		# Returns a server message.
		return {
			SEGMENT_REQUEST_TYPE: type,
			SEGMENT_DATA: data,
		}

	# Returns a client message.
	return {
		SEGMENT_CLIENT_ID: client_id,
		SEGMENT_REQUEST_TYPE: type,
		SEGMENT_DATA: data,
	}

## Converts the data to string json.
func to_json() -> String:
	return JSON.stringify(to_dictionary())

## Converts the data to a PacketByteArray.
func to_utf8_buffer() -> PackedByteArray:
	return to_json().to_utf8_buffer()