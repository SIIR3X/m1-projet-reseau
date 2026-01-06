## COR class that translates objects in JSON.
class_name ArgumentVerificationCORNodeObject extends ArgumentVerificationCORNode

# METHODS

## See [ArgumentVerificationCORNode].
func get_type(value: Variant) -> String:
	if typeof(value) == TYPE_DICTIONARY:
		# Check each field.
		for k: Variant in value:
			# If an object-only field was not found, scrap the object (is dictionary)
			if k is String and not k in SerializationResult.OBJECT_FIELDS:
				return ""

		return APIRegistry.API_TYPE_OBJECT
		
	# Not a success.
	return ""
