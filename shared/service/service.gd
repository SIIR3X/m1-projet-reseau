class_name Service extends Node

# METHODS

## Determines whether the current executable is running player or server mode.
func is_server() -> bool:
	return OS.has_feature("dedicated_server")

## Returns the executable directory.
func get_exec_dir() -> String:
	return OS.get_executable_path().get_base_dir()

## Determines whether or not the current script is running in-editor. No proper method were added so we base ourselves on the executable's name.
func is_in_editor() -> bool:
	return OS.get_executable_path().begins_with("Godot")