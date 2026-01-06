class_name Party extends Node

# VARIABLES.

var creator: Player
var creator_name: String
var id: int
var password: String

# CONSTRUCTION

func _init(creator_name_: String, id_: int, password_: String = "") -> void:
	creator_name = creator_name_
	id = id_
	password = password_