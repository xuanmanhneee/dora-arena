# addons/event_bus/plugin.gd
@tool
extends EditorPlugin

const AUTOLOAD_NAME := "EventBus"
const AUTOLOAD_PATH := "res://addons/event_bus/event_bus.gd"


func _enable_plugin() -> void:
	# Tự động thêm Autoload — người dùng không cần làm thủ công
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("[EventBus] Plugin enabled — Autoload '%s' registered." % AUTOLOAD_NAME)


func _disable_plugin() -> void:
	# Dọn sạch khi tắt plugin
	remove_autoload_singleton(AUTOLOAD_NAME)
	print("[EventBus] Plugin disabled — Autoload removed.")
