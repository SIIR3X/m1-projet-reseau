extends Node

# CONSTANTS

const SERIALIZATION_SETTINGS: String = "serialization_settings"

## Variable name for fields to exlude when serializing.
const SETTING_EXCLUDE: String = "exclude"

## Variable name for the classname to use if needed. By default, the classname is automatically fetched, but for
## classes with no name, or inner classes, this field is necessary.
const SETTING_CLASSNAME: String = "classname"

# ENGINE

func _ready() -> void:
	# Instantiation of a worker
	var person: Person = Person.new("Bob", "Timbaland", 92)
	var worker: WorkingPerson = WorkingPerson.new("Alice", "Timberton", 25, 8.0)
	
	print(serialize(person))
	print(serialize(worker))
	
	print(inst_to_dict(person))
	print(inst_to_dict(worker))
	
# METHODS

## Serializes a class. Takes all of its fields (except from "serializable_settings" and all excluded ones.
## The "referenced_objects" param allows the system to avoid redundency.
func _serialize_data_obj(obj: Object, referenced_objects: Array[Object]) -> Variant:
	# Checks if the object is already added. If so, we return null (already serialized so cyclic dependency)
	if obj in referenced_objects:
		return null
		
	# Adds object to the list
	referenced_objects.append(obj)

	# Fetches the list of properties & filters out engine properties alongside default settings
	var prop_list: Array = obj.get_property_list().filter(
		# Keeps defined fields only, and avoids the field "serializable_settings"
		func(v: Dictionary): return v.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and v.name != SERIALIZATION_SETTINGS
	).map(
		func(v: Dictionary): return v.name
	)
	
	# If the object has a serialize_exclude field, then we use it as a filter & clear it out
	var exclude: Array[String] = obj.get(SETTING_EXCLUDE) if obj.get(SETTING_EXCLUDE) != null else ([] as Array[String])
	
	if exclude:
		# Custom exclude in case some fields have to be excluded.
		prop_list = prop_list.filter(
			func(v): return not exclude.has(v)
		)
	
	# Serialization of the object
	var res: Dictionary[String, Variant] = {}
	
	for prop: String in prop_list:
		# Serializes & appends the property to the result
		res[prop] = _serialize( obj.get(prop), referenced_objects )
		
	return res
	
## Serializes dictionaries
func _serialize_data_dict(dict: Dictionary, referenced_objects: Array[Object]) -> Dictionary:
	var res: Dictionary = {}

	# Serialization of a dict is assinging to each existing key the serialized version of the pointed value.
	for key in dict:
		res[key] = _serialize(dict[key], referenced_objects)
		
	return res

## Serializes arrays
func _serialize_data_arr(arr: Array, referenced_objects: Array[Object]) -> Array:
	var res: Array = []
	
	# Serialization of an array is assinging to each existing index the serialized version of the pointed value.
	for val in arr:
		res.append( _serialize(val, referenced_objects) )
		
	return res

## Somewhat like a COR pattern. Decides which serialize function to use depending on the type
func _serialize(value: Variant, referenced_objects: Array[Object]) -> Variant:
	match typeof(value):
		TYPE_ARRAY:
			return _serialize_data_arr(value, referenced_objects)
				
		TYPE_DICTIONARY:
			return _serialize_data_dict(value, referenced_objects)
				
		TYPE_OBJECT:
			return _serialize_data_obj(value, referenced_objects)
			
		_:
			return value

## Serializes any kind of object. Takes all of its fields (except from "serializable_settings" and all excluded ones.
## Avoids to serialize the same object again.
func serialize(obj: Variant) -> String:
	var redundancy: Array[Object] = []
	
	return JSON.stringify(
		_serialize(obj, redundancy)
	)

# INNER TEST CLASSES

## Test class containing all fields & methods that we want to serialize.
class Person extends RefCounted:
	var name: String
	var surname: String
	var age: int
	
	var serialization_settings: Dictionary[String, Variant] = {
		SETTING_EXCLUDE: ["age"],
		SETTING_CLASSNAME: "Person"
	}
	
	func _init(name_: String, surname_: String, age_: int) -> void:
		assert(name_ != null and not name_.is_empty(), "Empty name")
		assert(surname_ != null and not surname_.is_empty(), "Empty surname")
	
		name = name_
		surname = surname_
		age = maxi(age_, 0)
		
	func present() -> void:
		print("I'm %s %s, and I'm %d years old" % [name, surname, age])
		
	func _to_string() -> String:
		return "[name = %s, surname = %s, age = %d]" % [name, surname, age]

## Test class inheriting from the upper class.
class WorkingPerson extends Person:
	var shift_duration: float
	var my_object: Object = Object.new()
	var my_array: Array[int] = [1, 2, 3, 4]
	var my_dict: Dictionary[String, Variant] = {
		"a": 1,
		"b": Object.new(),
		"c": [1, 2, "hey"],
	}
	var me_null: Object = null
	var self_reference: WorkingPerson = self
	
	func _init(name_: String, surname_: String, age_: int, shift_duration_: float) -> void:
		super(name_, surname_, age_)
		
		shift_duration = maxf(shift_duration_, 0)
		
		# Don't forget to update the serialize_classname
		serialization_settings[SETTING_CLASSNAME] = "WorkingPerson"
		
	func work() -> void:
		print("I am working for %.2f hours" % shift_duration)