class_name ReceivedAPIMessage extends APIMessage

# CONSTRUCTION

func _init(from: PacketMessage) -> void:
	packet_message = from
	
	# Assumes all proper verifications & computations were made.
	data = from.data

# METHODS

## Describes whether or not the data segment is compliant.
func is_data_compliant() -> bool:
	return SEGMENT_COMMAND in data \
		and SEGMENT_ARGS in data

## Computes values based on the attached packet. Not done automatically.
func compute() -> void:
	_compute_api_command()
	_compute_args()
	
func _compute_api_command() -> void:
	api_command = data.get(SEGMENT_COMMAND, "")

func _compute_args() -> void:
	arguments = data.get(SEGMENT_ARGS, [])
