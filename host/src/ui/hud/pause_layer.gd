class_name PauseLayer
extends CanvasLayer

@onready var root_control: Control = $Control
@onready var pause_label: Label = $Control/CenterContainer/VBoxContainer/PauseLabel
@onready var resume_button: Button = $Control/CenterContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $Control/CenterContainer/VBoxContainer/ExitButton

var _is_open := false
var _blocked := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)

	root_control.visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	EventBus.subscribe("game_over", _on_game_over)
	EventBus.subscribe("game_restarted", _on_game_restarted)
	EventBus.subscribe("locale_changed", _update_locale)

	_update_locale()

func _unhandled_input(event: InputEvent) -> void:
	if _blocked:
		return

	if event.is_action_pressed("ui_cancel"):
		if _is_open:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	_is_open = true
	root_control.visible = true
	get_tree().paused = true
	AnimatedCursor.show_cursor()

func _resume_game() -> void:
	_is_open = false
	get_tree().paused = false
	root_control.visible = false
	AnimatedCursor.hide_cursor()

func _force_close() -> void:
	_is_open = false
	get_tree().paused = false
	root_control.visible = false
	AnimatedCursor.hide_cursor()

func _on_resume_pressed() -> void:
	_resume_game()

func _on_exit_pressed() -> void:
	_force_close()
	EventBus.emit("return_main_menu_requested")

func _on_game_over(_winner: Enums.Team) -> void:
	_blocked = true
	_force_close()

func _on_game_restarted() -> void:
	_blocked = false

func _update_locale() -> void:
	pause_label.text = Localization.text("pause_title")
	resume_button.text = Localization.text("pause_resume")
	exit_button.text = Localization.text("pause_exit_game")
