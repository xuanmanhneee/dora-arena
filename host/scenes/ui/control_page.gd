extends MarginContainer

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

@onready var ip_address_label: Label = %IpAddressLabel

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
	
	ip_address_label.text = get_lan_ip()
	
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

func get_lan_ip() -> String:
	# Lấy danh sách tất cả các địa chỉ IP của máy
	var addresses = IP.get_local_addresses()
	
	for ip in addresses:
		# 1. Kiểm tra xem có phải IPv4 không (có dấu chấm)
		# 2. Kiểm tra xem có phải địa chỉ nội bộ (localhost) không
		if "." in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			return ip
			
	return "127.0.0.1" # Trả về localhost nếu không thấy mạng LAN
