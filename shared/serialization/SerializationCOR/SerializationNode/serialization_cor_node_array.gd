## COR class that translates arrays in JSON.
class_name SerializationCORNodeArray extends SerializationCORNode

# CONSTANTS

## List of array types.
const TYPE_ARRAYS: Array[int] = [
	TYPE_ARRAY,
	TYPE_PACKED_BYTE_ARRAY,
	TYPE_PACKED_COLOR_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY,
	TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_INT32_ARRAY,
	TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY,
	TYPE_PACKED_VECTOR3_ARRAY,
	TYPE_PACKED_VECTOR4_ARRAY,
]

# METHODS

## See [SerializationCORNode].
func serialize(value: Variant, context_override: Dictionary[String, Variant], referenced_objects_stack: Array[Object]) -> SerializationResult:
	if typeof(value) in TYPE_ARRAYS:
		
		# Serializing an array corresponds to serializing all of its content and wrapping it within an array.
		var res: Array = []
		
		# We serialize all of the content.
		for v: Variant in value:
			res.append( SerializationService._cor_root._serialize(v, context_override, referenced_objects_stack) )
			
		return SerializationResult.new(Error.OK, res)
		
	# Not a success.
	return SerializationResult.new(Error.FAILED, null)
