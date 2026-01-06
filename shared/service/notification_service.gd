extends ServiceControl

# VARIABLES

## Panel created to store notifications.
var notification_panel: VBoxContainer = VBoxContainer.new()

## Template of the notification.
var notification_template: PackedScene = preload("uid://dryxohdi5imd1")

# ENGINE

func _ready() -> void:
	anchor_left = 0
	anchor_right = 1
	anchor_top = 0
	anchor_bottom = 1
	
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	notification_panel.anchor_left = .75
	notification_panel.anchor_right = 1
	notification_panel.anchor_top = 0
	notification_panel.anchor_bottom = .25
	
	add_child(notification_panel)

# METHODS

## Wraps request for the server.
func make_show_request(id: int, msg: String) -> void:
	var ret: SendableAPIMessage = SendableAPIMessage.new("Notification.send", [msg])
	API.send(ret, id)

## Shows a message to the client.
func show_message(msg: String) -> void:
	# Creates the template & adds it.
	var notif: Notification = notification_template.instantiate()
	notif.text_to_assign = msg
	
	notification_panel.add_child(notif)

# CALLBACKS

func _client_message_received(message: String) -> void:
	show_message(message)
