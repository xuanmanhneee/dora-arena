class_name OverlayLayer extends CanvasLayer

var _game: Game = null

@onready var team_a_name_label: Label = $Scoreboard/HBoxContainer/TeamA/NameLabel
@onready var team_a_score_label: Label = $Scoreboard/HBoxContainer/TeamA/ScoreLabel

@onready var team_b_name_label: Label = $Scoreboard/HBoxContainer/TeamB/NameLabel
@onready var team_b_score_label: Label = $Scoreboard/HBoxContainer/TeamB/ScoreLabel

@onready var remaining_time_label: Label = $Scoreboard/HBoxContainer/RemainingTimeLabel

func _ready() -> void:
	# 1. Ngắt các hàm process không cần thiết để tối ưu hiệu năng (như bạn đã làm)
	set_process(false)
	set_physics_process(false)
	
	# 2. KẾT NỐI VỚI UI TẠI ĐÂY
	EventBus.subscribe("time_changed", _on_time_changed)
	EventBus.subscribe("score_changed", _on_score_changed)
	EventBus.subscribe("phase_changed", _on_game_phase_changed)
	EventBus.subscribe("game_restarted", _on_game_restarted)

func setup(game: Game):
	_game = game
	_setup_team_names()
	
	team_a_score_label.text = "0"
	team_b_score_label.text = "0"

func _on_time_changed(remaining_time: int) -> void:
	remaining_time_label.text = str(remaining_time)

# 3. Hàm xử lý khi nhận được tín hiệu
func _on_score_changed(team: Enums.Team, score: int):
	if team == Enums.Team.TEAM_A:
		team_a_score_label.text = str(score)
	elif team == Enums.Team.TEAM_B:
		team_b_score_label.text = str(score)

func _on_game_phase_changed():
	remaining_time_label.text = "Overtime"

func _on_game_restarted() -> void:
	team_a_score_label.text = "0"
	team_b_score_label.text = "0"
	

func _setup_team_names() -> void:
	if _game == null:
		return

	if _game.mode == Enums.GameMode.LOCAL_2P:
		_setup_local_names()
	elif _game.mode == Enums.GameMode.LAN_4P:
		_setup_lan_names()

func _setup_local_names() -> void:
	var p1 = _game.player_configs.get(1, {})
	var p2 = _game.player_configs.get(2, {})

	team_a_name_label.text = p1.get("name", "P1")
	team_b_name_label.text = p2.get("name", "P2")
	
func _setup_lan_names() -> void:
	team_a_name_label.text = "Team A"
	team_b_name_label.text = "Team B"
