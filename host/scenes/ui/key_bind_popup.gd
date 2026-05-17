extends PopupPanel

signal key_selected(keycode: int)

@onready var label: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel
@onready var error_label: RichTextLabel = $MarginContainer/VBoxContainer/ErrorLabel

var used_keys: Dictionary[int, String] = {}
var current_action: String = ""

func _ready() -> void:
	hide()

func start_listening(action_name: String, current_used_keys: Dictionary[int, String]) -> void:
	current_action = action_name
	used_keys = current_used_keys
	error_label.text = ""

	label.text = (
		"[color=green]Press key for:[/color] " +
		"[color=#ff6b6b]" + action_name + "[/color]\n" +
		"[color=gray]Press ESC to cancel[/color]"
	)

	popup_centered()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var keycode: int = key_event.physical_keycode

		if keycode == KEY_ESCAPE:
			hide()
			get_viewport().set_input_as_handled()
			return

		if used_keys.has(keycode) and used_keys[keycode] != current_action:
			error_label.text = "[color=#ff6b6b]This key is already assigned to " + used_keys[keycode] + "[/color]"
			get_viewport().set_input_as_handled()
			return

		key_selected.emit(keycode)
		hide()
		get_viewport().set_input_as_handled()
