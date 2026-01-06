extends "res://addons/gut/test.gd"

var promise: Promise
var state: Dictionary

func before_each() -> void:
	promise = Promise.new()
	state = {
		"state": false,
	}
	
func test_then() -> void:
	promise.then(func(): pass).then(func(): pass).error(func(): pass)
	assert_eq(promise._then_callbacks.size(), 2)
	
func test_error() -> void:
	promise.then(func(): pass).error(func(): pass).error(func(): pass)
	assert_eq(promise._error_callback.size(), 2)
	
func test_valid_then() -> void:
	promise.then(func():
		state.valid = true
	)
	promise.execute_then(null)
	
	assert_true(state.valid)
	
func test_valid_then_returns_error_fallback() -> void:
	promise.then(func(): pass).then(func(): return Error.FAILED).error(func():
		state.valid = true
	)
	promise.execute_then(null)
	
	# The error did not fire.
	assert_true(state.valid)

func test_error_short_circuit() -> void:
	promise.error(func(): return true).error(func():
		state.valid = true
	)
	promise.execute_error(Error.FAILED)
	
	# The short circuit worked.
	assert_true(state.valid)