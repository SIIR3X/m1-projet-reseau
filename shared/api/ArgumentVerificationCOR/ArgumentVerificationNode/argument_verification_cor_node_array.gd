## COR class that translates arrays in JSON.
class_name ArgumentVerificationCORNodeArray extends ArgumentVerificationCORNode

# CONSTANTS

## List of array types.
const TYPE_ARRAYS: Array[Variant.Type] = [
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

## See [ArgumentVerificationCORNode].
func get_type(value: Variant) -> String:
	if typeof(value) in TYPE_ARRAYS:
		return APIRegistry.API_TYPE_ARRAY
		
	# Not a success.
	return ""
