## COR class that translates objects in JSON.
class_name SerializationCORNodeObject extends SerializationCORNode

# METHODS

## Fetches the classname from an object.
func fetch_classname(obj: Object, context_override: Dictionary[String, Variant]) -> String:
	var res: String = context_override.get(SerializationService.SETTING_CLASSNAME, "")

	# Context has a classname property.
	if not res.is_empty():
		return res
		
	# This is the settings field. Its existence isn't guaranteed, so an empty dictionary will be used in case it does not.
	# An empty dictionary being of type Dictionary[String, Nil], a cast is needed to force it to Array[String, Variant]).
	var tmp: Variant = obj.get(SerializationService.SERIALIZATION_SETTINGS)
	var settings: Dictionary[String, Variant] = tmp if tmp else ({} as Dictionary[String, Variant])
	
	# If settings has a classname property.
	res = settings.get(SerializationService.SETTING_CLASSNAME, "")
	
	if not res.is_empty():
		return res

	# Object has an attached script.
	if obj.get_script():
		res = (obj.get_script() as Script).get_global_name()
	
	# No script attached, this is a core object.	
	else:
		res = obj.get_class()
	
	return res

## Fetches the property list after inclusion/exclusion rules provided by the context_override argument, and the object's
## class definition.[br]
## - obj : Object whose properties are to be fetched.[br]
## - context_override : Dictionary representing serialization settings to override.[br]
## returns the list of properties to list.
func fetch_custom_property_list(obj: Object, context_override: Dictionary[String, Variant]) -> Array:

	# Fetches the list of properties & filters out engine properties alongside default settings
	var res: Array = obj.get_property_list().filter(
	
		# Keeps defined fields only, and avoids the field "serializable_settings"
		func(v: Dictionary): return v.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and v.name != SerializationService.SERIALIZATION_SETTINGS
	).map(
	
		# Only keeps the name out of it.
		func(v: Dictionary): return v.name
	)
	
	# This is the settings field. Its existence isn't guaranteed, so an empty dictionary will be used in case it does not.
	# An empty dictionary being of type Dictionary[String, Nil], a cast is needed to force it to Array[String, Variant]).
	var tmp: Variant = obj.get(SerializationService.SERIALIZATION_SETTINGS)
	var settings: Dictionary[String, Variant] = tmp if tmp else ({} as Dictionary[String, Variant])
	
	# We take exclusion settings from the context & the object to union them.
	var exclude: Array = context_override.get(SerializationService.SETTING_EXCLUDE, [])
	
	# Exclusion of the object.
	var exclude_object: Array = settings.get(SerializationService.SETTING_EXCLUDE, [])
	
	# We take inclusion settings from the context to use for exclusion.
	var include: Array = context_override.get(SerializationService.SETTING_INCLUDE, [])
	
	# We merge the exclusion : duplicates won't be added !
	if exclude_object.size() > 0:
		exclude.append_array(
			exclude_object.filter(func(v: Variant): return not v in exclude)
		)
	
	# We diff the two arrays.
	if include.size() > 0:
		exclude = exclude.filter(func(v: Variant): return not v in include)
	
	# We filter out the res based on the exclude.
	if exclude.size() > 0:
		res = res.filter(func(v: Variant): return not v in exclude)
	
	return res

## See [SerializationCORNode].
func serialize(value: Variant, context_override: Dictionary[String, Variant], referenced_objects_stack: Array[Object]) -> SerializationResult:
	if typeof(value) == TYPE_OBJECT:
	
		# Checks if the object is already added. If so, we return null (already serialized so cyclic dependency)
		if value in referenced_objects_stack:
			return SerializationResult.new(Error.OK, null)
		
		# Adds object to the list in a .
		referenced_objects_stack.append(value)
		
		# We fetch the property list.
		var prop_list: Array = fetch_custom_property_list(value, context_override)
		
		# Serialization of the object.
		var res: Dictionary[String, Variant] = {}
		
		for prop: String in prop_list:
			# Serializes & appends the property to the result.
			# An empty board is passed because lower levels should not get the context filter, in case of collisions.
			res[prop] = SerializationService._cor_root._serialize(value.get(prop), {}, referenced_objects_stack)
			
		# Adds specific fields (__object_id and __class).
		res[SerializationResult.FIELD_OBJECT_ID] = value.get_instance_id()
		res[SerializationResult.FIELD_CLASSNAME] = fetch_classname(value, context_override)
		
		# Removes the object from LIFO. At that point, the object should be last.
		referenced_objects_stack.pop_back()
		
		return SerializationResult.new(Error.OK, res)
		
	# Not a success.
	return SerializationResult.new(Error.FAILED, null)
