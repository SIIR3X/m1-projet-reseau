class_name Promise extends RefCounted

# VARIABLES

## Response received for the promise.
var response: Variant

## List of then clauses.
var _then_callbacks: Array[Callable] = []

## List of error clauses.
var _error_callback: Array[Callable] = []

# METHOD

## Adds a then clause to the promise.[br]
## callback : Function to run whenever the reponse was received.[br]
## returns the promise to chain subsequent clauses.
## Example :
## [codeblock]
## Promise.then(func(response: Variant):
## 	print("Received %s" % str(response))
## )
## [/codeblock]
## The callable can also generate an error in case something went wrong. The chain of then clauses will be discarded
## and the error chain will be called.
## [codeblock]
## Promise.then(func(response: Variant):
## 	return Error.FAILED
## ).error(func(error: Error):
## 	print("Caught an error")
## )
## [/codeblock] 
func then(callback: Callable) -> Promise:
	# Makes sure the callback has a valid format.
	assert(callback.get_argument_count() <= 1, "Callback for then clause should only contain one argument.")
	
	if not callback in _then_callbacks:
		_then_callbacks.append(callback)

	return self

## Adds an error clause to the promise.[br]
## callback : Function to run whenever an error was generated, either by the promise itself, or by a
## subsequent then clause.[br]
## returns the promise to chain subsequent clauses.
## Example :
## [codeblock]
## Promise.then(func(response: Variant):
## 	...
##
## ).error(func(error: Error)
## 	print("An error was caught")
## )
## [/codeblock]
## The callable can also return a boolean, describing whether or not the error was handled properly. In such case
## the chain of errors won't be called.
## [codeblock]
## Promise.then(func(response: Variant):
## 	...
## ).error(func(error: Error):
## 	print("Caught an error that was dealt with")
##
## 	# Indicates the error was dealt with.
## 	return true
##
## ).error(func(error: Error):
## 	print("I will never be called!")
## )
## [/codeblock] 
func error(callback: Callable) -> Promise:
	# Makes sure the callback has a valid format.
	assert(callback.get_argument_count() <= 1, "Callback for error clause should only contain one argument.")
	
	if not callback in _error_callback:
		_error_callback.append(callback)

	return self

## Executes the different then clauses in order with the awaited response.[br]
## res : Response value.
func execute_then(res: Variant) -> void:
	var err: Variant
	var is_error: bool = false
	
	# Overrides response field if necessary.
	if response != res:
		response = res

	# Calls every callable in order. If the callable returns an error, then the error is propagated in the "error" section.
	for callback: Callable in _then_callbacks:
		if callback.get_argument_count() == 0:
			err = callback.call()
		else:
			err = callback.call(response)
		
		# If an error occurs, runs error code callbacks.
		if err != null and err is Error and err != Error.OK:
			is_error = true
			break
			
	# Calls error exec if needed.
	if is_error:
		execute_error(err)

## Executes the different then clauses in order with the awaited response.[br]
## err : Received error code.
func execute_error(err: Error) -> void:
	var exit: bool = false

	# Calls every callable in errors in order. If the callable returns true, breaks the loop.
	for callback: Callable in _error_callback:
		if callback.get_argument_count() == 0:
			callback.call()
		else:
			callback.call(err)
	
		# Shortcircuits the error cycle.
		if exit == true:
			break
