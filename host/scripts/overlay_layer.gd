extends CanvasLayer

@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/CenterContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PauseOverlay/CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $PauseOverlay/CenterContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_hide_pause()
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if pause_overlay.visible:
			_hide_pause()
		else:
			_show_pause()

func _show_pause() -> void:
	get_tree().paused = true
	pause_overlay.visible = true

func _hide_pause() -> void:
	get_tree().paused = false
	pause_overlay.visible = false

func _on_resume_pressed() -> void:
	_hide_pause()

func _on_restart_pressed() -> void:
	_hide_pause()
	GameEvents.play_again_requested.emit()

func _on_main_menu_pressed() -> void:
	_hide_pause()
	GameEvents.return_main_menu_requested.emit()
	
