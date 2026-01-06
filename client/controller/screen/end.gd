extends Control

# VARIABLES

@export_file("*.tscn") var return_scene: String

@onready var return_button: Button = %ReturnButton

# ENGINE

func _ready() -> void:
	return_button.pressed.connect(_on_return_button_pressed)

# CALLBACKS

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file(return_scene)
