class_name ChatController extends PanelContainer

# CONSTANTS

const MAX_CHILD_COUNT: int = 100

# VARIABLES

@export var chat_template: PackedScene

@onready var send_button: Button = %SendButton
@onready var chat_box: LineEdit = %Box

@onready var chat_list: VBoxContainer = %Content

# ENGINE

func _ready() -> void:
	Chat.chat_received.connect(_on_chat_received)
	send_button.pressed.connect(_on_chat_send)

# CALLBACKS

func _on_chat_received(player_name: String, message: String) -> void:
	var msg_label: Label = chat_template.instantiate()
	
	# Formats the msg.
	msg_label.text = "[%s]: %s" % [player_name, message]
	
	# Adds the message in the feed.
	chat_list.add_child(msg_label)
	
	# If the list goes beyond a certain size, remove early children.
	if chat_list.get_child_count() > MAX_CHILD_COUNT:
		# Deletes the topmost one.
		chat_list.get_child(0).queue_free()
	
func _on_chat_send() -> void:
	# Content check.
	if chat_box.text.is_empty():
		return
	
	# Sends API request to server.
	var api_call: SendableAPIMessage = SendableAPIMessage.new(
		"Chat.send", [chat_box.text]
	)
	API.send(api_call)
	
	# Clears box.
	chat_box.text = ""