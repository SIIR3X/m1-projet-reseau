## Service used to serialize & deserialize objects based on their class definition, alongside a context override
## system.[br]
## [br]
## Using the following class example :
## [codeblock]
## ## Standard class.
## class Person extends RefCounted:
## 	var name: String
## 	var surname: String
## 	var age: int
##
## 	## Serialization setting. The variable name "serialization_settings" is a magic variable in this context, and will not be
## 	## serialized. Every key in this dictionary are represented by constants that this class houses.
## 	var serialization_settings: Dictionary[String, Variant] = {
## 		SerializationService.SETTING_EXCLUDE: ["age"],
## 		SerializationService.SETTING_CLASSNAME: "Person",
## 	}
##
## 	func _init(name_: String, surname_: String, age_: int) -> void:
## 		name = name_
## 		surname = surname_
## 		age = age_
##
## ## Specialized class with inheritance.
## class WorkingPerson extends Person:
## 	var shift_duration: float
## 	var my_object: Object = Object.new()
## 	var my_array: Array[int] = [1, 2, 3, 4]
## 	var my_dict: Dictionary[String, Variant] = {
## 		"a": 1,
## 		"b": Object.new(),
## 		"c": [1, 2, "hey"],
## 	}
## 	var me_null: Object = null
## 	var self_reference: WorkingPerson = self
##	
## 	func _init(name_: String, surname_: String, age_: int, shift_duration_: float) -> void:
## 		super(name_, surname_, age_)
##
## 		shift_duration = shift_duration_
##
## 		# Don't forget to update the serialize_classname
## 		serialization_settings[SerializationService.SETTING_CLASSNAME] = "WorkingPerson"
## [/codeblock]
## To serialize any object :
## [codeblock]
## var person: Person = Person.new("Alice", "Pricia", 25)
## print( SerializerService.serialize(person) ) # Outputs {"name":"Alice","surname":"Pricia"}
##
## print( SerializerService.serialize(person, {
## 	SerializeService.SETTING_INCLUDE: ["age"]
## })
## # Outputs {"age":25,"name":"Alice","surname":"Pricia"}
## # The context overrides the class definition by re-allowing the age field to be serialized.
##
## var working_person: WorkingPerson = WorkingPerson.new("Bob", "Stanislas", 45, 35.0)
## print( SerializerService.serialize(working_person) )
## # Outputs {"me_null":null,"my_array":[1,2,3,4],"my_dict":{"a":1,"b":{},"c":[1,2,"hey"]},"my_object":{},"name":"Alice","self_reference":null,"shift_duration":8.0,"surname":"Timberton"}
## [/codeblock]
extends Node

# CONSTANTS

## Variable name for settings dictionary for objects.
const SERIALIZATION_SETTINGS: String = "serialization_settings"

## Setting name for the classname to use if needed. By default, the classname is automatically fetched, but for
## classes with no name, or inner classes, this field is necessary.[br]
## Expected type : [String].
const SETTING_CLASSNAME: String = "classname"

## Setting name for fields to exlude when serializing.[br]
## Expected type : [Array] of [String].
const SETTING_EXCLUDE: String = "exclude"

## Setting name for fields to include when serializing. By default, every fields are included.
## This field is useful when being used with context overrides.[br]
## Expected type : [Array] of [String].
const SETTING_INCLUDE: String = "include"

# VARIABLES

## Root of the chain of responsibility.
var _cor_root: SerializationCORRoot

# CONSTRUCTION

func _init() -> void:
	# COR pattern init.
	_cor_root = preload("uid://cwj83sqn57tgj").instantiate()
	add_child(_cor_root)

# METHODS

## Serializes an object. Uses the COR iterative pattern to serialize the object. Cross recursion is used, be advised
## to not serialize large objects. Cyclic references are taken into account : an object already serialized won't be serialized again.[br]
## - value : Value to transcribe in JSON.[br]
## - context_override : Dictionary of values overriding standard settings defined in classes.[br]
## returns the string representation of the value.
func serialize(value: Variant, context_override: Dictionary[String, Variant] = {}) -> String:
	return _cor_root.serialize(value, context_override)
