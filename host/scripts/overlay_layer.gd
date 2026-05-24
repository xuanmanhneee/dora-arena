extends CanvasLayer

@onready var team_a_score_label: Label = $ScoreBoards/TeamA/Label
@onready var team_b_score_label: Label = $ScoreBoards/TeamB/Label
@onready var remaining_time_label: Label = $Timer/Label
@onready var energy_bar_p1: ProgressBar = $EnergyBarP1  # ← thêm
@onready var energy_bar_p2: ProgressBar = $EnergyBarP2  # ← thêm
@onready var score_p1: Label = $ScoreP1
@onready var score_p2: Label = $ScoreP2

func _ready() -> void:
	# 1. Ngắt các hàm process không cần thiết để tối ưu hiệu năng (như bạn đã làm)
	set_process(false)
	set_physics_process(false)
	
	# 2. KẾT NỐI VỚI UI TẠI ĐÂY
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.score_changed.connect(_on_score_changed)
	GameEvents.phase_changed.connect(_on_game_phase_changed)
	GameEvents.game_restarted.connect(_on_game_restarted)
	GameEvents.energy_changed.connect(_on_energy_changed)
	GameEvents.player_score_changed.connect(_on_player_score_changed)
	
	# Style thanh P1 (vàng cam)
	_setup_bar(energy_bar_p1, Color("#EF9F27"))
	# Style thanh P2 (xanh dương)
	_setup_bar(energy_bar_p2, Color("#378ADD"))

func _on_player_score_changed(player: Player, score: int) -> void:
	if player.team == Enums.Team.TEAM_A:
		score_p1.text = str(score)
	else:
		score_p2.text = str(score)

func _setup_bar(bar: ProgressBar, color: Color) -> void:
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.2, 0.2, 0.6)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

func _on_energy_changed(player: Player, current: float, maximum: float) -> void:
	# Xác định player nào dựa vào team
	var bar = energy_bar_p1 if player.team == Enums.Team.TEAM_A else energy_bar_p2
	var tween = create_tween()
	tween.tween_property(bar, "value", (current / maximum) * 100.0, 0.15)


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
	
