class_name OverlayLayer extends CanvasLayer

var _game: Game = null

# --- CÁC BIẾN CỦA FILE MỚI ---
@onready var team_a_name_label: Label = $Scoreboard/HBoxContainer/TeamA/NameLabel
@onready var team_a_score_label: Label = $Scoreboard/HBoxContainer/TeamA/ScoreLabel
@onready var team_b_name_label: Label = $Scoreboard/HBoxContainer/TeamB/NameLabel
@onready var team_b_score_label: Label = $Scoreboard/HBoxContainer/TeamB/ScoreLabel
@onready var remaining_time_label: Label = $Scoreboard/HBoxContainer/RemainingTimeLabel

# --- THANH NĂNG LƯỢNG & ĐIỂM SỐ CÁ NHÂN ---
@onready var energy_bar_p1: ProgressBar = $EnergyBarP1
@onready var energy_bar_p2: ProgressBar = $EnergyBarP2
@onready var energy_bar_p3: ProgressBar = $EnergyBarP3
@onready var energy_bar_p4: ProgressBar = $EnergyBarP4


var _energy_bars: Dictionary = {}

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	
	EventBus.subscribe("time_changed", _on_time_changed)
	EventBus.subscribe("score_changed", _on_score_changed)
	EventBus.subscribe("phase_changed", _on_game_phase_changed)
	EventBus.subscribe("game_restarted", _on_game_restarted)
	EventBus.subscribe("energy_changed", _on_energy_changed)
	
	_setup_bar(energy_bar_p1, Color("#EF9F27"))
	_setup_bar(energy_bar_p2, Color("#378ADD"))


func setup(game: Game) -> void:
	_game = game
	_setup_team_names()
	

	
	_setup_player_bars()

func _setup_player_bars() -> void:
		_energy_bars.clear()
		
		energy_bar_p1.visible = false
		energy_bar_p2.visible = false
		energy_bar_p3.visible = false
		energy_bar_p4.visible = false
		
		var bars = [energy_bar_p1, energy_bar_p2, energy_bar_p3, energy_bar_p4]
		var colors = [
			Color("#EF9F27"),
			Color("#E74C3C"),
			Color("#378ADD"),
			Color("#2ECC71")
		]
 
		var index = 0
		for id in _game.player_configs:
			var bar = bars[index]
			_setup_bar(bar, colors[index])
			bar.visible = true
			_energy_bars[id] = bar
			index += 1
 

func _on_time_changed(remaining_time: int) -> void:
	remaining_time_label.text = str(remaining_time)


func _on_score_changed(team: Enums.Team, score: int) -> void:
	if team == Enums.Team.TEAM_A:
		team_a_score_label.text = str(score)
	elif team == Enums.Team.TEAM_B:
		team_b_score_label.text = str(score)


func _on_game_phase_changed() -> void:
	remaining_time_label.text = "Overtime"


func _on_game_restarted() -> void:
	team_a_score_label.text = "0"
	team_b_score_label.text = "0"
	

	
	for bar in _energy_bars.values():
		if bar: bar.value = 0.0
	
	if energy_bar_p1: energy_bar_p1.value = 0.0
	if energy_bar_p2: energy_bar_p2.value = 0.0





func _on_energy_changed(player: Player, current: float, maximum: float) -> void:
	if not _energy_bars.has(player.id): return
	var bar = _energy_bars[player.id]
	if bar:
		var tween = create_tween()
		tween.tween_property(bar, "value", (current / maximum) * 100.0, 0.15)


func _setup_bar(bar: ProgressBar, color: Color) -> void:
	if not bar: return
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
