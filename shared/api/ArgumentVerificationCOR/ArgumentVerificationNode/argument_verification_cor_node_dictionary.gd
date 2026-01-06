## COR class that translates dictionaries in JSON.
class_name ArgumentVerificationCORNodeDictionary extends ArgumentVerificationCORNode

# METHODS

## See [ArgumentVerificationCORNode].
func get_type(value: Variant) -> String:
	if typeof(value) == TYPE_DICTIONARY:
		# Check each field.
		for k: Variant in value:
			# If an object-only field was found, scrap the dictionary (is object)
			if k is String and k in SerializationResult.OBJECT_FIELDS:
				return ""
		
		return APIRegistry.API_TYPE_DICTIONARY

	# Not a success.
	return ""
