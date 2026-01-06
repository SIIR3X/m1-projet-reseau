## Node that has translation capabilities of a value into JSON.
@abstract class_name SerializationCORNode extends Node

# METHODS

## Method used to translate a set of values in JSON.[br]
## - value : Value to translate in JSON.[br]
## - context_override : Dictionary representing serialization settings to override.[br]
## - referenced_objects_stack : Objects that were already referenced. Useful to avoid cyclic dependencies.[br]
## returns the JSON-equivalent representation of value.
@abstract func serialize(value: Variant, context_override: Dictionary[String, Variant], referenced_objects_stack: Array[Object]) -> SerializationResult
