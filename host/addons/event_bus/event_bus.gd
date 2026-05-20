# addons/event_bus/event_bus.gd
extends Node

var _listeners: Dictionary[String, Array] = {}


func subscribe(event: String, callable: Callable) -> void:
	if event.is_empty():
		push_warning("[EventBus] Cannot subscribe empty event.")
		return

	if not callable.is_valid():
		push_warning("[EventBus] Cannot subscribe invalid callable.")
		return

	if not _listeners.has(event):
		_listeners[event] = []

	if not _listeners[event].has(callable):
		_listeners[event].append(callable)


func unsubscribe(event: String, callable: Callable) -> void:
	if not _listeners.has(event):
		return

	_listeners[event].erase(callable)

	if _listeners[event].is_empty():
		_listeners.erase(event)


func emit(event: String, args: Array = []) -> void:
	if not _listeners.has(event):
		return

	for callable: Callable in _listeners[event].duplicate():
		if callable.is_valid():
			callable.callv(args)
		else:
			_listeners[event].erase(callable)

	if _listeners.has(event) and _listeners[event].is_empty():
		_listeners.erase(event)


func emit_deferred(event: String, args: Array = []) -> void:
	if not _listeners.has(event):
		return

	for callable: Callable in _listeners[event].duplicate():
		if callable.is_valid():
			call_deferred("_call_listener", callable, args)
		else:
			_listeners[event].erase(callable)


func _call_listener(callable: Callable, args: Array) -> void:
	if callable.is_valid():
		callable.callv(args)


func clear(event: String) -> void:
	_listeners.erase(event)


func clear_all() -> void:
	_listeners.clear()


func has_listener(event: String, callable: Callable) -> bool:
	if not _listeners.has(event):
		return false

	return _listeners[event].has(callable)


func debug_print() -> void:
	if _listeners.is_empty():
		print("[EventBus] No listeners.")
		return

	for event: String in _listeners:
		print("[EventBus] '%s' -> %d listener(s)" % [event, _listeners[event].size()])
