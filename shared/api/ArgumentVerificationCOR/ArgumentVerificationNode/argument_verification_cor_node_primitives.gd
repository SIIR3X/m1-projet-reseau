## COR class that translates primitives in JSON.
class_name ArgumentVerificationCORNodePrimitives extends ArgumentVerificationCORNode

# CONSTANTS

const TYPE_MATCHING: Dictionary[Variant.Type, String] = {
	TYPE_BOOL: APIRegistry.API_TYPE_BOOL,
	TYPE_FLOAT: APIRegistry.API_TYPE_FLOAT,
	TYPE_STRING: APIRegistry.API_TYPE_STRING,
}

# METHODS

## See [ArgumentVerificationCORNode].
func get_type(value: Variant) -> String:
	if typeof(value) in TYPE_MATCHING:
		return TYPE_MATCHING[typeof(value)]
		
	# Not a success.
	return ""
