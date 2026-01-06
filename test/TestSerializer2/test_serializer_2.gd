extends Node

@export var resource: Board

# ENGINE

func _ready() -> void:
	# Instantiation of a worker
	var person: Person = Person.new("Bob", "Timbaland", 92)
	var worker: WorkingPerson = WorkingPerson.new("Alice", "Timberton", 25, 8.0)
	
	print(SerializationService.serialize(person))
	print(SerializationService.serialize(worker))

	print()
	print(SerializationService.serialize(person, {
		SerializationService.SETTING_INCLUDE: ["age"],
	}))
	
# INNER TEST CLASSES

## Test class containing all fields & methods that we want to serialize.
class Person extends RefCounted:
	var name: String
	var surname: String
	var age: int
	
	var serialization_settings: Dictionary[String, Variant] = {
		SerializationService.SETTING_EXCLUDE: ["age"],
		SerializationService.SETTING_CLASSNAME: "Person",
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
		serialization_settings[SerializationService.SETTING_CLASSNAME] = "WorkingPerson"
		
	func work() -> void:
		print("I am working for %.2f hours" % shift_duration)
