# addons/event_bus/event_bus.gd
extends Node

var _listeners: Dictionary = {}


func subscribe(event: String, callable: Callable) -> void:
	if not _listeners.has(event):
		_listeners[event] = []
	if callable not in _listeners[event]:
		_listeners[event].append(callable)


func unsubscribe(event: String, callable: Callable) -> void:
	if not _listeners.has(event):
		return
	_listeners[event].erase(callable)


func emit(event: String, args: Array = []) -> void:
	if not _listeners.has(event):
		return
	for callable in _listeners[event].duplicate():
		if callable.is_valid():
			callable.callv(args)
		else:
			_listeners[event].erase(callable)


func clear(event: String) -> void:
	_listeners.erase(event)


func debug_print() -> void:
	for event in _listeners:
		print("[EventBus] '%s' → %d listener(s)" % [event, _listeners[event].size()])
