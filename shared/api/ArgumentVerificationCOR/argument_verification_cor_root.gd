class_name ArgumentVerificationCORRoot extends Node

# METHODS

## Method of type verification.
func get_type(value: Variant) -> String:
	return _get_type(value)

## Method of type verification for any variablt. Uses an iterative approach.
func _get_type(value: Variant) -> String:
	
	# We go through the children in order to test if the returned value is correct.
	for child: ArgumentVerificationCORNode in get_children():
	
		# The result contains two keys: valid (bool that describes whether or not the value was transcribed in JSON) and the json value.
		var res: String = child.get_type(value)
		
		if not res.is_empty():
			return res
	
	# Nothing to return.
	return ""
