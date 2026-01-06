class_name APIRegistry extends RefCounted

# CONSTANTS

## Type parameter for arrays.
const API_TYPE_ARRAY: String = "array"

## Type parameter for booleans.
const API_TYPE_BOOL: String = "bool"

## Type parameter for dictionaries.
const API_TYPE_DICTIONARY: String = "dictionary"

## Type parameter for floats.
const API_TYPE_FLOAT: String = "float"

## Type parameter for objects.
const API_TYPE_OBJECT: String = "object"

## Type parameter for strings.
const API_TYPE_STRING: String = "string"

# VARIABLES

## Callable to call for the API.
var callable: Callable

## Whether or not the call should be done only by logged-in users.
var secured: bool = true

## Type of arguments that should be received.
var _arguments_types: Array[String] = []

# CONSTRUCTION

func _init(callable_: Callable, arguments_types_: Array[String], secured_: bool = true) -> void:
	assert(callable_.get_object() != null, "Callable does not belong to any object")

	callable = callable_
	_arguments_types = arguments_types_
	secured = secured_

# METHODS

## Checks whether or not argument count matches.
func verify_arguments_count(args: Array[Variant]) -> bool:
	return _arguments_types.size() == args.size()
	
## Checks whether or not argument types match.
func verify_arguments_types_match(args: Array[Variant]) -> bool:
	# Argument count mismatch.
	if not verify_arguments_count(args):
		return false
	
	for i: int in range(args.size()):
		var arg: Variant = args[i]
		var type: String = API.get_argument_type(arg)
				
		# Type mismatch.
		if type != _arguments_types[i]:
			return false
	
	# Everything was correct.
	return true

## Executes the API command. Note that it does not verify argument types !
func execute(args: Array[Variant]) -> Variant:
	return callable.callv(args)
		
		
