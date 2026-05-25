extends Control

var lan_player_placeholder: String

@onready var local_mode_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LocalModePanel/Label
@onready var lan_mode_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/Label

@onready var id_address_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/HBoxContainer/IpAddress

@onready var select_map_label: Label = $RootMarginContainer/RootHBoxContainer/VBoxContainer2/Label
@onready var time_limit_label: Label = $RootMarginContainer/RootHBoxContainer/VBoxContainer2/HBoxContainer2/Label
# Setup Local
@onready var local_mode_panel: VBoxContainer = %LocalModePanel

@onready var player1_type_option: OptionButton = %Player1TypeOption
@onready var player2_type_option: OptionButton = %Player2TypeOption

@onready var player1_name_line_edit: LineEdit = %Player1NameLineEdit
@onready var player2_name_line_edit: LineEdit = %Player2NameLineEdit

@onready var player1_color_picker: ColorPickerButton = %Player1ColorPicker
@onready var player2_color_picker: ColorPickerButton = %Player2ColorPicker


# Setup LAN
@onready var lan_mode_panel: VBoxContainer = %LanModePanel

@onready var player1_team_a_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/PlayersContainer/TeamAContainer/P1Label
@onready var player2_team_a_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/PlayersContainer/TeamAContainer/P2Label

@onready var player1_team_b_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/PlayersContainer/TeamBContainer/P1Label
@onready var player2_team_b_label: Label = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/PlayersContainer/TeamBContainer/P2Label

@onready var ip_address_lineedit: LineEdit = $RootMarginContainer/RootHBoxContainer/LeftMarginContainer/VBoxContainer/PlayerSetting/LanModePanel/HBoxContainer/LineEdit

var lan_player_teams: Dictionary[int, Enums.Team] = {}
var lan_player_names: Dictionary[int, String] = {}
var lan_player_colors: Dictionary[int, Color] = {}

# Setup game
@onready var backward_button: Button = %BackwardButton
@onready var forward_button: Button = %ForwardButton
@onready var start_game_button: Button = %StartGameButton
@onready var game_time_spin_box: SpinBox = %GameTimeSpinBox



@export var maps: Array[MapInfo]
@onready var map_preview_texture_rect: TextureRect = %MapPreviewTextureRect
@onready var map_name_label: Label = %MapNameLabel

const PLAYER_OPTION_DATA := {
	0: { "control_type": Enums.PlayerControlType.HUMAN, "bot_difficulty": Enums.BotDifficulty.NONE  },
	1: { "control_type": Enums.PlayerControlType.BOT,   "bot_difficulty": Enums.BotDifficulty.EASY   },
	2: { "control_type": Enums.PlayerControlType.BOT,   "bot_difficulty": Enums.BotDifficulty.NORMAL },
	3: { "control_type": Enums.PlayerControlType.BOT,   "bot_difficulty": Enums.BotDifficulty.HARD   },
	4: { "control_type": Enums.PlayerControlType.BOT,   "bot_difficulty": Enums.BotDifficulty.ASIAN  },
}

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
	
	EventBus.subscribe("locale_changed", _update_locale)
	_update_locale()
	
	backward_button.pressed.connect(_on_backward_button_pressed)
	forward_button.pressed.connect(_on_forward_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	
	if not NetworkManager.player_registered.is_connected(_on_player_registered):
		NetworkManager.player_registered.connect(_on_player_registered)
	
	EventBus.subscribe("player_register", _on_player_registered)
	EventBus.subscribe("lan_player_disconnected", _on_lan_player_disconnected)
	
	player1_type_option.item_selected.connect(_on_player1_type_selected)
	player2_type_option.item_selected.connect(_on_player2_type_selected)

	_update_default_name(1, player1_type_option, player1_name_line_edit)
	_update_default_name(2, player2_type_option, player2_name_line_edit)
	
	randomize()
	
	player1_color_picker.color = _random_color()
	player2_color_picker.color = _random_color()
	
	# LAN
	ip_address_lineedit.text = Utils.get_lan_ip()

	_show_map(current_index)
	_refresh_mode_panel()

func _exit_tree() -> void:
	EventBus.unsubscribe("player_register", _on_player_registered)
	EventBus.unsubscribe("lan_player_disconnected", _on_lan_player_disconnected)


# SETTINGS CHUNG ----------------------------------------------------------------------------------
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
	
	if current_game_mode == Enums.GameMode.LAN_4P:
		NetworkManager.start_game.rpc()
	
	#if current_game_mode == Enums.GameMode.LAN_4P and lan_player_teams.size() < 4:
		#push_error("LAN cần đủ 4 client để bắt đầu")
		#return
		
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# LOCAL--------------------------------------------------------------------------------------------
func _on_player1_type_selected(_index: int) -> void:
	_update_default_name(1, player1_type_option, player1_name_line_edit)

func _on_player2_type_selected(_index: int) -> void:
	_update_default_name(2, player2_type_option, player2_name_line_edit)

func _update_default_name(id: int, option: OptionButton, line_edit: LineEdit) -> void:
	var option_id := option.get_selected_id()
	var data: Dictionary = PLAYER_OPTION_DATA[option_id]

	if data["control_type"] == Enums.PlayerControlType.BOT:
		var difficulty_name := _get_difficulty_name(data["bot_difficulty"])
		line_edit.text = "AI_%s_%d" % [difficulty_name, id]
	else:
		line_edit.text = "P%d" % id

func _build_local_players_config() -> Dictionary[int, Dictionary]:
	var p1_data: Dictionary = PLAYER_OPTION_DATA[player1_type_option.get_selected_id()]
	var p2_data: Dictionary = PLAYER_OPTION_DATA[player2_type_option.get_selected_id()]

	return {
		1: {
			"name": _get_player_name(1, player1_name_line_edit, p1_data),
			"team": Enums.Team.TEAM_A,
			"color": player1_color_picker.color,
			"is_local": true,
			"control_type": p1_data["control_type"],
			"bot_difficulty": p1_data["bot_difficulty"]
		},
		2: {
			"name": _get_player_name(2, player2_name_line_edit, p2_data),
			"team": Enums.Team.TEAM_B,
			"color": player2_color_picker.color,
			"is_local": true,
			"control_type": p2_data["control_type"],
			"bot_difficulty": p2_data["bot_difficulty"]
		}
	}

# LAN ---------------------------------------------------------------------------------------------
func _assign_lan_team() -> Enums.Team:
	var team_a_count := lan_player_teams.values().count(Enums.Team.TEAM_A)
	var team_b_count := lan_player_teams.values().count(Enums.Team.TEAM_B)

	return Enums.Team.TEAM_A if team_a_count <= team_b_count else Enums.Team.TEAM_B


func _add_lan_player(id: int, player_name: String, player_color: Color) -> void:
	if lan_player_teams.has(id):
		lan_player_names[id] = player_name
	else:
		lan_player_teams[id] = _assign_lan_team()
		lan_player_names[id] = player_name
		lan_player_colors[id] = player_color


	_refresh_lan_ui()

func _on_lan_player_disconnected(id: int) -> void:
	if current_game_mode != Enums.GameMode.LAN_4P:
		return

	_remove_lan_player(id)

func _remove_lan_player(id: int) -> void:
	if not lan_player_teams.has(id):
		return

	lan_player_teams.erase(id)
	lan_player_names.erase(id)
	lan_player_colors.erase(id)

	_refresh_lan_ui()

	print("[LAN] Removed player: %d" % id)

func _refresh_lan_ui() -> void:
	var team_a_labels := [
		player1_team_a_label,
		player2_team_a_label
	]

	var team_b_labels := [
		player1_team_b_label,
		player2_team_b_label
	]

	for label in team_a_labels:
		label.text = lan_player_placeholder

	for label in team_b_labels:
		label.text = lan_player_placeholder

	var a_index := 0
	var b_index := 0

	for id in lan_player_teams:
		var team := lan_player_teams[id]
		var player_name: String = lan_player_names.get(id, "Player %d" % id)

		if team == Enums.Team.TEAM_A:
			if a_index < team_a_labels.size():
				team_a_labels[a_index].text = player_name
				a_index += 1
		else:
			if b_index < team_b_labels.size():
				team_b_labels[b_index].text = player_name
				b_index += 1
	
	_update_start_button_state()

func _on_player_registered(id: int, player_name: String, player_color: Color) -> void:
	if current_game_mode != Enums.GameMode.LAN_4P:
		return

	_add_lan_player(id, player_name, player_color)

func _build_lan_players_config() -> Dictionary[int, Dictionary]:
	var result: Dictionary[int, Dictionary] = {}

	for id in lan_player_teams:
		result[id] = {
			"name": lan_player_names.get(id, "Player %d" % id),
			"team": lan_player_teams[id],
			"color": lan_player_colors.get(id, Color.WHITE),
			"is_local": false,
			"control_type": Enums.PlayerControlType.HUMAN,
			"bot_difficulty": Enums.BotDifficulty.NONE
		}

	return result

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

func _refresh_mode_panel() -> void:
	if current_game_mode == Enums.GameMode.LOCAL_2P:
		lan_mode_panel.visible = false
		local_mode_panel.visible = true
		_clear_lan_data()
		
		if NetworkManager.is_hosting:
			NetworkManager.stop_server()

	elif current_game_mode == Enums.GameMode.LAN_4P:
		local_mode_panel.visible = false
		lan_mode_panel.visible = true
		NetworkManager.start_server()
		
func _random_color() -> Color:
	return Color(
		randf(),
		randf(),
		randf(),
		1.0
	)

func _update_locale() -> void:
	local_mode_label.text = Localization.text("menu_2_players_local")
	lan_mode_label.text = Localization.text("menu_4_player_lan")
	lan_player_placeholder = Localization.text("setting_waiting")
	start_game_button.text = Localization.text("setting_start_game")
	select_map_label.text = Localization.text("setting_select_map")
	time_limit_label.text = Localization.text("setting_time_limit")
	id_address_label.text = Localization.text("setting_ip_address")
	
	_refresh_lan_ui()

func _get_player_name(id: int, line_edit: LineEdit, data: Dictionary) -> String:
	var text := line_edit.text.strip_edges()

	if not text.is_empty():
		return text

	if data["control_type"] == Enums.PlayerControlType.BOT:
		return "AI%d" % id

	return "P%d" % id

func _get_difficulty_name(difficulty: Enums.BotDifficulty) -> String:
	match difficulty:
		Enums.BotDifficulty.EASY:   return "Easy"
		Enums.BotDifficulty.NORMAL: return "Normal"
		Enums.BotDifficulty.HARD:   return "Hard"
		Enums.BotDifficulty.ASIAN:  return "Asian"
		_:                          return "Bot"

func _clear_lan_data() -> void:
	lan_player_teams.clear()
	lan_player_names.clear()
	lan_player_colors.clear()
	_refresh_lan_ui()

func _update_start_button_state() -> void:
	if current_game_mode != Enums.GameMode.LAN_4P:
		start_game_button.disabled = false
		return

	var has_team_a := false
	var has_team_b := false

	for team in lan_player_teams.values():
		if team == Enums.Team.TEAM_A:
			has_team_a = true
		elif team == Enums.Team.TEAM_B:
			has_team_b = true

	start_game_button.disabled = not (has_team_a and has_team_b)
