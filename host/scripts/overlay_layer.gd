extends CanvasLayer

@onready var team_a_score_label: Label = $ScoreBoards/TeamA/Label
@onready var team_b_score_label: Label = $ScoreBoards/TeamB/Label
@onready var remaining_time_label: Label = $Timer/Label

func _ready() -> void:
	# 1. Ngắt các hàm process không cần thiết để tối ưu hiệu năng (như bạn đã làm)
	set_process(false)
	set_physics_process(false)
	
	# 2. KẾT NỐI VỚI UI TẠI ĐÂY
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.score_changed.connect(_on_score_changed)
	GameEvents.phase_changed.connect(_on_game_phase_changed)
	GameEvents.game_restarted.connect(_on_game_restarted)

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
	
