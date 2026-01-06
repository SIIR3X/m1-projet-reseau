extends Control

# VARIABLES

@export_file("*.tscn") var return_scene: String

@onready var return_button: Button = %ReturnButton

# ENGINE

func _ready() -> void:
	# Bindings.
	return_button.pressed.connect(_on_return_button_pressed)
	LobbyService.created_party_status.connect(_on_party_removed)

# CALLBACKS

func _on_return_button_pressed() -> void:
	LobbyService.remove_party()

func _on_party_removed(status: bool) -> void:
	# False means deleted
	if not status:
		get_tree().change_scene_to_file(return_scene)