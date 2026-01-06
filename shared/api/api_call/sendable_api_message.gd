class_name SendableAPIMessage extends APIMessage

# CONSTRUCTION

func _init(api_command_: String, arguments_: Array) -> void:
	api_command = api_command_
	arguments = arguments_

# METHODS

## Converts the data to a dictionary.
func to_dictionary() -> Dictionary[String, Variant]:
	return {
		SEGMENT_COMMAND: api_command,
		SEGMENT_ARGS: arguments,
	}

## Converts the data to string json.
func to_json() -> String:
	return JSON.stringify(to_dictionary())

## Converts the data to a PacketByteArray.
func to_utf8_buffer() -> PackedByteArray:
	return to_json().to_utf8_buffer()