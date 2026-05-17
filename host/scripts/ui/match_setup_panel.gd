extends Control

@onready var local_mode_panel: VBoxContainer = %LocalModePanel
@onready var lan_mode_panel: VBoxContainer = %LanModePanel

@onready var backward_button: Button = %BackwardButton
@onready var forward_button: Button = %ForwardButton
@onready var start_game_button: Button = %StartGameButton
@onready var game_time_spin_box: SpinBox = %GameTimeSpinBox

@onready var player1_color_picker: ColorPickerButton = %Player1ColorPicker
@onready var player2_color_picker: ColorPickerButton = %Player2ColorPicker

@export var maps: Array[MapInfo]
@onready var map_preview_texture_rect: TextureRect = %MapPreviewTextureRect
@onready var map_name_label: Label = %MapNameLabel

var current_game_mode: Enums.GameMode = Enums.GameMode.LOCAL_2P
var current_index: int = 0
var selected_map: MapInfo

func on_open(data: Variant = null) -> void:
	if data == null:
		return

	current_game_mode = data as Enums.GameMode
	_refresh_mode_panel()

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
		
	backward_button.pressed.connect(_on_backward_button_pressed)
	forward_button.pressed.connect(_on_forward_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	
	randomize()
	
	player1_color_picker.color = _random_color()
	player2_color_picker.color = _random_color()
	
	_show_map(current_index)
	_refresh_mode_panel()

func _show_map(index: int):
	if maps.is_empty():
		push_error("Chưa gán maps cho MatchSetupPanel")
		return

	current_index = wrapi(index, 0, maps.size())
	selected_map = maps[current_index]

	map_preview_texture_rect.texture = selected_map.preview
	map_name_label.text = selected_map.map_name

func _on_backward_button_pressed():
	_show_map(current_index - 1)

func _on_forward_button_pressed():
	_show_map(current_index + 1)

func _on_start_game_button_pressed():
	if selected_map == null:
		push_error("Chưa chọn map")
		return

	GameData.match_config = _build_match_config()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _build_match_config() -> MatchConfig:
	var config := MatchConfig.new()

	config.mode = current_game_mode
	config.map_info = selected_map
	config.game_time = float(game_time_spin_box.value)
	config.players = _build_players_config()

	return config

func _build_players_config() -> Dictionary[int, Dictionary]:
	match current_game_mode:
		Enums.GameMode.LOCAL_2P:
			return _build_local_players_config()

		Enums.GameMode.LAN_4P:
			return _build_lan_players_config()

	return {}

func _build_local_players_config() -> Dictionary[int, Dictionary]:
	return {
		1: {
			"name": "Player 1",
			"team": Enums.Team.TEAM_A,
			"color": player1_color_picker.color,
			"is_local": true
		},
		2: {
			"name": "Player 2",
			"team": Enums.Team.TEAM_B,
			"color": player2_color_picker.color,
			"is_local": true
		}
	}

#test
func _build_lan_players_config() -> Dictionary[int, Dictionary]:
	return {
		1: {"name": "Player 1", "team": Enums.Team.TEAM_A, "color": Color.BLUE, "is_local": false},
		2: {"name": "Player 2", "team": Enums.Team.TEAM_B, "color": Color.RED, "is_local": false},
		3: {"name": "Player 3", "team": Enums.Team.TEAM_A, "color": Color.GREEN, "is_local": false},
		4: {"name": "Player 4", "team": Enums.Team.TEAM_B, "color": Color.YELLOW, "is_local": false},
	}

func _refresh_mode_panel() -> void:
	if current_game_mode == Enums.GameMode.LOCAL_2P:
		lan_mode_panel.visible = false
		local_mode_panel.visible = true
	elif current_game_mode == Enums.GameMode.LAN_4P:
		local_mode_panel.visible = false
		lan_mode_panel.visible = true

func _random_color() -> Color:
	return Color(
		randf(),
		randf(),
		randf(),
		1.0
	)
	

func get_lan_ip() -> String:
	# Lấy danh sách tất cả các địa chỉ IP của máy
	var addresses = IP.get_local_addresses()
	
	for ip in addresses:
		# 1. Kiểm tra xem có phải IPv4 không (có dấu chấm)
		# 2. Kiểm tra xem có phải địa chỉ nội bộ (localhost) không
		if "." in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			return ip
			
	return "127.0.0.1" # Trả về localhost nếu không thấy mạng LAN
