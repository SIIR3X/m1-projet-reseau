extends Control

# VARIABLES

@export_file("*.tscn") var return_scene: String
@export_file("*.tscn") var bot_mode_scene: String
@export_file("*.tscn") var pvp_mode_scene: String

@onready var return_button: Button = %ReturnButton
@onready var bot_mode_button: Button = %BotModeButton
@onready var pvp_mode_button: Button = %PvPModeButton

# ENGINE

func _ready() -> void:
	# Binding.
	return_button.pressed.connect(_on_return_button_pressed)
	
	bot_mode_button.pressed.connect(_on_bot_mode_selected)
	pvp_mode_button.pressed.connect(_on_pvp_mode_selected)

# CALLBACKS

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file(return_scene)

func _on_bot_mode_selected() -> void:
	API.send(
		SendableAPIMessage.new(
			"Game.startBot", []
		)
	)

func _on_pvp_mode_selected() -> void:
	get_tree().change_scene_to_file(pvp_mode_scene)
