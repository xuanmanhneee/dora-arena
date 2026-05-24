extends Node

const DEFAULT_KEYS := {
	"p1_left": KEY_A,
	"p1_right": KEY_D,
	"p1_jump": KEY_W,
	"p1_shoot": KEY_F,
	"p1_skill": KEY_G,
}

func _ready() -> void:
	load_keybinds()

func load_keybinds() -> void:
	for action in DEFAULT_KEYS.keys():
		var keycode = SettingsManager.get_setting("input", action, DEFAULT_KEYS[action])
		apply_key(action, keycode)

func set_key(action: String, keycode: int) -> void:
	apply_key(action, keycode)
	SettingsManager.set_setting("input", action, keycode)

func apply_key(action: String, keycode: int) -> void:
	InputMap.action_erase_events(action)

	var event := InputEventKey.new()
	event.physical_keycode = keycode

	InputMap.action_add_event(action, event)
