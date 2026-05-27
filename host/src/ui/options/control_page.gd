extends MarginContainer

@onready var key_label: Label = $TwoPlayer/MarginContainer/TwoPlayers/Header/KeyLabel
@onready var two_players_label: Label = $TwoPlayer/MarginContainer/TwoPlayers/Label
@onready var four_players_label: Label = $TwoPlayer/FourPlayers/Label

@onready var left_label: Label = $TwoPlayer/MarginContainer/TwoPlayers/MoveLeftRow/LeftLabel
@onready var right_label: Label = $TwoPlayer/MarginContainer/TwoPlayers/MoveRightRow/RightLabel
@onready var jump_label: Label = $TwoPlayer/MarginContainer/TwoPlayers/JumpRow/JumpLabel
@onready var shoot_label: Label = $TwoPlayer/MarginContainer/TwoPlayers/ShootRow/ShootLabel

@onready var step_1_label: Label = $TwoPlayer/FourPlayers/ScrollContainer/MarginContainer/VBoxContainer/Step1Label
@onready var step_2_label: Label = $TwoPlayer/FourPlayers/ScrollContainer/MarginContainer/VBoxContainer/Step2Label
@onready var step_3_label: Label = $TwoPlayer/FourPlayers/ScrollContainer/MarginContainer/VBoxContainer/Step3Label
@onready var step_4_label: Label = $TwoPlayer/FourPlayers/ScrollContainer/MarginContainer/VBoxContainer/Step4Label
@onready var host_ip_label: Label = $TwoPlayer/FourPlayers/ScrollContainer/MarginContainer/VBoxContainer/HostIpLabel

@onready var p1_left_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/MoveLeftRow/P1Button
@onready var p1_right_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/MoveRightRow/P1Button
@onready var p1_jump_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/JumpRow/P1Button
@onready var p1_shoot_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/ShootRow/P1Button

@onready var p2_left_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/MoveLeftRow/P2Button
@onready var p2_right_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/MoveRightRow/P2Button
@onready var p2_jump_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/JumpRow/P2Button
@onready var p2_shoot_button: Button = $TwoPlayer/MarginContainer/TwoPlayers/ShootRow/P2Button

@onready var reset_button: Button = %ResetButton
@onready var key_popup: PopupPanel = $KeyBindPopup

@onready var host_ip_value_label: Label = %HostIpValueLabel

var button_actions: Dictionary[Button, String]

var listening_action: String = ""
var listening_button: Button = null

func _ready() -> void:
	button_actions = {
		p1_left_button: "p1_left",
		p1_right_button: "p1_right",
		p1_jump_button: "p1_jump",
		p1_shoot_button: "p1_shoot",

		p2_left_button: "p2_left",
		p2_right_button: "p2_right",
		p2_jump_button: "p2_jump",
		p2_shoot_button: "p2_shoot",
	}

	for button in button_actions:
		button.pressed.connect(_on_key_button_pressed.bind(button))
	
	reset_button.pressed.connect(_on_reset_button_pressed)
	key_popup.key_selected.connect(_on_key_selected)
	
	EventBus.subscribe("locale_changed", _update_locale)

	host_ip_value_label.text = Utils.get_lan_ip()
	_update_locale()
	update_button_texts()

func update_button_texts() -> void:
	for button in button_actions:
		var action: String = button_actions[button]
		var keycode: int = SettingsManager.get_setting(
			"input",
			action,
			SettingsManager.DEFAULTS["input"][action]
		)

		button.text = OS.get_keycode_string(keycode as Key)

func _on_key_button_pressed(button: Button) -> void:
	listening_button = button
	listening_action = button_actions[button]
	
	key_popup.start_listening(listening_action, get_used_keys())
	
func _on_key_selected(keycode: int) -> void:
	InputManager.set_key(listening_action, keycode)

	listening_button.text = OS.get_keycode_string(keycode)

	listening_action = ""
	listening_button = null

func _on_reset_button_pressed() -> void:
	for action in SettingsManager.DEFAULTS["input"]:
		var keycode: int = SettingsManager.DEFAULTS["input"][action]
		InputManager.set_key(action, keycode)

	update_button_texts()
	

func get_used_keys() -> Dictionary[int, String]:
	var result: Dictionary[int, String] = {}

	for action in button_actions.values():
		var keycode: int = SettingsManager.get_setting(
			"input",
			action,
			SettingsManager.DEFAULTS["input"][action]
		)

		result[keycode] = action

	return result

func _update_locale() -> void:
	key_label.text = Localization.text("control_key")
	two_players_label.text = Localization.text("control_2_players")
	four_players_label.text = Localization.text("control_4_players")
	
	left_label.text = Localization.text("control_key_left")
	right_label.text = Localization.text("control_key_right")
	jump_label.text = Localization.text("control_key_jump")
	shoot_label.text = Localization.text("control_key_shoot")
	
	reset_button.text = Localization.text("control_reset_defaut_control")
	
	step_1_label.text = Localization.text("control_step_1")
	step_2_label.text = Localization.text("control_step_2")
	step_3_label.text = Localization.text("control_step_3")
	step_4_label.text = Localization.text("control_step_4")
	host_ip_label.text = Localization.text("control_host_ip")
