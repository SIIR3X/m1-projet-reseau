extends Control

@export_category("UI-related elements")
@export_group("global")
@export var status_label: Label
@export var send_button: Button
@export var client_id: LineEdit
@export var output: TextEdit
@export var method: OptionButton

@onready var tab_container: TabContainer = $TabContainer

@export_group("packet")
@export var packet_input: TextEdit

@export_group("api")
@export var api_command: LineEdit
@export var api_arguments: Array[LineEdit] = []

var text_to_method: Dictionary[String, NetworkService.TransmissionMethod] = {
	"TCP": NetworkService.TransmissionMethod.METHOD_TCP,
	"UDP": NetworkService.TransmissionMethod.METHOD_UDP
}

func _ready() -> void:
	send_button.pressed.connect(_send)
	
	_update_status_label()
	NetworkService.client_connection.connected_to_server.connect(_update_status_label)
	NetworkService.client_connection.disconnected_from_server.connect(_update_status_label)
	
	NetworkService.client_connection.message_received.connect(func(packet: ReceivedPacketMessage):
		if not packet.is_message_compliant:
			_output("Error upon receiving server packet")
			return
			
		packet.compute()
		
		_output("Received message \"%s\" from server\n(Payload : %s)" % [packet.data, packet.message])
	)
	
	client_id.text = str(NetworkService.client_connection.client_id) if NetworkService.client_connection.client_id >= 0 else ""

func _update_status_label() -> void:
	status_label.text = "Connected" if NetworkService.client_connection.is_client_connected() else "Disconnected"

func _send() -> void:
	if not NetworkService.client_connection.is_client_connected():
		_output("Cannot send message : disconnected from servier")
		return
		
	if not client_id.text.is_valid_int():
		_output("No valid Client ID filled")
		return
		
	if not method.text in text_to_method:
		_output("No valid transmission method filled")
		return
		
	var id: int = int(client_id.text)
	var used_method: NetworkService.TransmissionMethod = text_to_method.get(method.text)
		
	match tab_container.current_tab:
		0:
			send_packet(id, used_method)
			
		1:
			send_api_call(id, used_method)
			
		_:
			_output("No communication selected")

func send_packet(id: int, used_method: NetworkService.TransmissionMethod) -> void:
	var content: String = packet_input.text
	
	if content.is_empty():
		_output("Cannot send empty packet")
		return

	var to_send: SendablePacketMessage = SendablePacketMessage.new(NetworkService.UNSTRUCTURED_MESSAGE, content, id)

	NetworkService.send(to_send, used_method)
	_output("Sent packet \"%s\" to server with client id %d\n(Payload : %s)" % [content, id, to_send.to_json()])

## Parses the args in the give LineEdit board.
func _parse_args(lines: Array[LineEdit]) -> Array:
	var args: Array[Variant] = []
	
	for arg_input: LineEdit in lines:
		if arg_input.text.is_empty():
			break # No further args
		
		if arg_input.text == "false":
			args.append(false)
			
		elif arg_input.text == "true":
			args.append(true)
			
		elif arg_input.text == "null":
			args.append(null)
		
		elif arg_input.text.is_valid_int():
			args.append(float(arg_input.text))
		
		elif arg_input.text.is_valid_int():
			args.append(int(arg_input.text))
		
		else:
			args.append(arg_input.text)
	
	return args

func send_api_call(id: int, used_method: NetworkService.TransmissionMethod) -> void:
	var cmd: String = api_command.text
	
	
	if cmd.is_empty():
		_output("Command cannot be empty")
	
	var args: Array = _parse_args(api_arguments)
	var to_send: SendableAPIMessage = SendableAPIMessage.new(cmd, args)
	
	API.send(to_send, -1, used_method)
	_output("Sent API request \"%s\" to server with args \"%s\" with client id %d\n(Payload : %s)" % [cmd, str(args), id, to_send.to_json()])

func _output(msg: String) -> void:
	var t: Dictionary = Time.get_datetime_dict_from_system()

	output.text = "%s\n[%d:%d:%d]: %s" % [
		output.text,
		t.hour, t.minute, t.second,
		msg
	]
