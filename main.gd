extends Node

@export_file("*.tscn") var client_start_uid: String

# ENGINE

func _ready() -> void:
	if not Context.is_server():
		# Loads using UID to avoid needing the reference for the server.
		get_tree().change_scene_to_file.call_deferred(client_start_uid)