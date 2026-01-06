## COR class that translates primitives in JSON.
class_name SerializationCORNodePrimitive extends SerializationCORNode

# CONSTANTS

## List of primitive types.
const TYPE_PRIMITIVES: Array[int] = [
	TYPE_AABB,
	TYPE_BASIS,
	TYPE_BOOL,
	TYPE_COLOR,
	TYPE_FLOAT,
	TYPE_INT,
	TYPE_NIL,
	TYPE_NODE_PATH,
	TYPE_PLANE,
	TYPE_PROJECTION,
	TYPE_QUATERNION,
	TYPE_RECT2I,
	TYPE_STRING,
	TYPE_STRING_NAME,
	TYPE_TRANSFORM2D,
	TYPE_TRANSFORM3D,
	TYPE_VECTOR2,
	TYPE_VECTOR2I,
	TYPE_VECTOR3,
	TYPE_VECTOR3I,
	TYPE_VECTOR4,
	TYPE_VECTOR4I,
]

# METHODS

## See [SerializationCORNode].
func serialize(value: Variant, _context_override: Dictionary[String, Variant], _referenced_objects_stack: Array[Object]) -> SerializationResult:
	if typeof(value) in TYPE_PRIMITIVES:
		
		# We just return the value.
		return SerializationResult.new(Error.OK, value)
		
	# Not a success.
	return SerializationResult.new(Error.FAILED, null)
