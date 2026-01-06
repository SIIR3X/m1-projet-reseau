## COR class that translates dictionaries in JSON.
class_name SerializationCORNodeDictionary extends SerializationCORNode

# METHODS

## See [SerializationCORNode].
func serialize(value: Variant, context_override: Dictionary[String, Variant], referenced_objects_stack: Array[Object]) -> SerializationResult:
	if typeof(value) == TYPE_DICTIONARY:
		
		# Serializing a dictionary corresponds to serializing all of its values and associating them to the same keys.
		var res: Dictionary[String, Variant] = {}
		
		# We serialize all of the content.
		for k: String in value:
			res[k] = SerializationService._cor_root._serialize(value[k], context_override, referenced_objects_stack)
			
		return SerializationResult.new(Error.OK, res)
		
	# Not a success.
	return SerializationResult.new(Error.FAILED, null)
