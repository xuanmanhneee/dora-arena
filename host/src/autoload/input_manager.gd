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
	var input_defaults: Dictionary = SettingsManager.DEFAULTS["input"]

	for action in input_defaults:
		var keycode: int = SettingsManager.get_setting("input", action, input_defaults[action])
		apply_key(action, keycode)

func set_key(action: String, keycode: int) -> void:
	apply_key(action, keycode)
	SettingsManager.set_setting("input", action, keycode)

func apply_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		push_warning("Missing input action: " + action)
		return

	InputMap.action_erase_events(action)

	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key

	InputMap.action_add_event(action, event)
