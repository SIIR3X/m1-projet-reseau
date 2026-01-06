## Result returned by various methods to signal success or failure. Stores both the validity of the translation of the object (if any). 
class_name SerializationResult extends RefCounted

# CONSTANTS

## Specific field for classname. Used for object serialization services.
const FIELD_CLASSNAME: String = "__class"

## Specific field for object ID. Used for replication services.
const FIELD_OBJECT_ID: String = "__object_id"

## All object-specific fields.
const OBJECT_FIELDS: Array[String] = [
	FIELD_CLASSNAME, FIELD_OBJECT_ID
]

# VARIABLES

## Describes the validity of the interaction.
var validity: Error

## Value obtained.
var value: Variant = null

# CONSTRUCTION

func _init(validity_: Error, value_: Variant) -> void:
	validity = validity_
	value = value_
