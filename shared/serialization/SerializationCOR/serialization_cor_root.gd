## Root node which manages the list of COR serialization nodes. This COR method uses iterative approaches rather
## than a recursive one.[br/]
## The manager uses its children as a list mechanism to handle each type.
class_name SerializationCORRoot extends Node

# METHODS

## Method of serialization of an object. The context is useful in case there is a need to temporarily override.[br]
## - value : Value to transcribe in JSON.[br]
## - context_override : Dictionary of values overriding standard settings defined in classes.[br]
## returns the string representation of the value.
func serialize(value: Variant, context_override: Dictionary[String, Variant]) -> String:
	var referenced_objects_stack: Array[Object] = []

	return JSON.stringify(
		_serialize(value, context_override, referenced_objects_stack)
	)


## Method of serialization of an object. Uses an iterative approach. Caches already-inserted objects to avoid dependencies.[br]
## - value : Value to transcribe in JSON.[br]
## - context_override : Dictionary of values overriding standard settings defined in classes.[br]
## - referenced_objects_stack : Objects that were already referenced. Useful to avoid cyclic dependencies.[br]
## returns the string representation of the value.
func _serialize(value: Variant, context_override: Dictionary[String, Variant], referenced_objects_stack: Array[Object]) -> Variant:
	
	# We go through the children in order to test if the returned value is correct.
	for child: SerializationCORNode in get_children():
	
		# The result contains two keys: valid (bool that describes whether or not the value was transcribed in JSON) and the json value.
		var res: SerializationResult = child.serialize(value, context_override, referenced_objects_stack)
		
		if res.validity == Error.OK:
			return res.value
	
	# Nothing to return.
	return null
