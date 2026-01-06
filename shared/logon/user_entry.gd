class_name UserEntry extends RefCounted

# VARIABLES

## Username.
var username: String

## Password.
var password_hash: String

# CONSTRUCTION

func _init(username_: String, password_hash_: String) -> void:
	username = username_
	password_hash = password_hash_

# METHODS

## Verifies whether or not login infos match.
func password_match(password_hash_: String) -> bool:
	return password_hash == password_hash_