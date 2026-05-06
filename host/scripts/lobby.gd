extends Control

@onready var ip_address_lineedit: LineEdit = $IpAddress/HBoxContainer/LineEdit

@onready var team_a_slots = [
	$CenterContainer/VBoxContainer/PlayerListContainer/PlayersContainer/TeamAContainer/Player1,
	$CenterContainer/VBoxContainer/PlayerListContainer/PlayersContainer/TeamAContainer/Player2,
]
@onready var team_b_slots = [
	$CenterContainer/VBoxContainer/PlayerListContainer/PlayersContainer/TeamBContainer/Player1,
	$CenterContainer/VBoxContainer/PlayerListContainer/PlayersContainer/TeamBContainer/Player2,
]

@onready var start_button: Button = %StartButton

var player_teams: Dictionary[int, Enums.Team] = {}
var player_names: Dictionary[int, String] = {}

func _ready() -> void:
	ip_address_lineedit.text = get_lan_ip()
	NetworkManager.player_registered.connect(_on_player_registered)
	start_button.pressed.connect(_on_start_button_pressed)

func assign_team() -> Enums.Team:
	var count1 = player_teams.values().count(Enums.Team.TEAM_A)
	var count2 = player_teams.values().count(Enums.Team.TEAM_B)
	return Enums.Team.TEAM_A if count1 <= count2 else Enums.Team.TEAM_B

func add_player(id: int, player_name: String) -> void:
	var team = assign_team()
	player_teams[id] = team
	player_names[id] = player_name  # lưu thêm tên
	_refresh_ui()
	
func _refresh_ui() -> void:
	for slot in team_a_slots:
		slot.text = "Waiting ..."
	for slot in team_b_slots:
		slot.text = "Waiting ..."

	var a_index = 0
	var b_index = 0
	
	for id in player_teams:
		if player_teams[id] == Enums.Team.TEAM_A:
			if a_index < team_a_slots.size():
				team_a_slots[a_index].text = player_names[id]
				a_index += 1
		else:
			if b_index < team_b_slots.size():
				team_b_slots[b_index].text = player_names[id]
				b_index += 1

func _on_player_registered(id: int, player_name: String) -> void:
	add_player(id, player_name)

func _on_start_button_pressed():
	GameData.player_teams = player_teams
	GameData.player_names = player_names
	NetworkManager.start_game.rpc()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func get_lan_ip() -> String:
	# Lấy danh sách tất cả các địa chỉ IP của máy
	var addresses = IP.get_local_addresses()
	
	for ip in addresses:
		# 1. Kiểm tra xem có phải IPv4 không (có dấu chấm)
		# 2. Kiểm tra xem có phải địa chỉ nội bộ (localhost) không
		if "." in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			return ip
			
	return "127.0.0.1" # Trả về localhost nếu không thấy mạng LAN
