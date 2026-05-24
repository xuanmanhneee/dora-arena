extends Node

@export var player_scene: PackedScene
@export var current_map: Node2D

var _game_time: float = -1

var _remaining_time: float = -1
var is_game_over: bool = false
var player_inputs: Dictionary[int, PlayerInput] = {}

var _current_phase: Enums.GamePhase = Enums.GamePhase.NORMAL
var scores: Dictionary[Enums.Team, int] = {
	Enums.Team.TEAM_A: 0,
	Enums.Team.TEAM_B: 0
}

func setup(game_time: float):
	_game_time = game_time

func _ready() -> void:
	GameEvents.player_died.connect(_on_player_handle_death)
	GameEvents.play_again_requested.connect(_on_restart)
	GameEvents.return_main_menu_requested.connect(_on_return_to_main_menu)
	await get_tree().process_frame
	
	_current_phase = Enums.GamePhase.NORMAL
	
	_game_time = GameData.current_game_time
	_remaining_time = _game_time
	
	_register_players()
	_spawn_all_players()

# --- TÁCH BIỆT: Đăng ký input vs Spawn vật lý ---

func _register_players() -> void:
	match GameData.mode:
		Enums.GameMode.LOCAL_2P:
			GameData.player_teams[1] = Enums.Team.TEAM_A
			GameData.player_teams[2] = Enums.Team.TEAM_B
			player_inputs[1] = PlayerInput.new()
			player_inputs[2] = PlayerInput.new()

		Enums.GameMode.LAN_4P:
			NetworkManager.movement_input_received.connect(_on_movement_input_received)
			NetworkManager.action_input_received.connect(_on_action_input_received)
			for id in GameData.player_teams:
				player_inputs[id] = PlayerInput.new()

func _spawn_all_players() -> void:
	# Cả 2 chế độ đều dùng GameData.player_teams — không phân biệt
	var index = 0
	for id in GameData.player_teams:
		var pos = current_map.get_spawn_position(index)
		_create_player(id, GameData.player_teams[id], player_inputs[id], pos)
		index += 1
		

func _on_restart() -> void:
	# Reset trạng thái
	is_game_over = false
	_remaining_time = _game_time
	_current_phase = Enums.GamePhase.NORMAL
	scores[Enums.Team.TEAM_A] = 0
	scores[Enums.Team.TEAM_B] = 0

	# Xóa player cũ
	for p in get_tree().get_nodes_in_group("players"):
		p.queue_free()

	await get_tree().process_frame
	
	# Tạo lại player — dùng lại data đã có sẵn
	_spawn_all_players()

	GameEvents.game_restarted.emit()

# --- PROCESS ---

func _process(delta: float) -> void:
	_tick_timer(delta)
	if GameData.mode == Enums.GameMode.LOCAL_2P:
		_read_local_movement()

func _tick_timer(delta: float) -> void:
	if is_game_over: return
	
	if _current_phase == Enums.GamePhase.SUDDEN_DEATH:
		return
		
	_remaining_time = maxf(_remaining_time - delta, 0.0)
	GameEvents.time_changed.emit(_remaining_time)
	if _remaining_time == 0.0:
		_on_time_up()

func _read_local_movement() -> void:
	if player_inputs.has(1):
		player_inputs[1].move_direction = int(Input.get_axis("p1_left", "p1_right"))
	if player_inputs.has(2):
		player_inputs[2].move_direction = int(Input.get_axis("p2_left", "p2_right"))

# --- TẠO / HỒI SINH ---

func _create_player(id: int, team: Enums.Team, input: PlayerInput, pos: Vector2) -> void:
	if not player_scene:
		push_error("Chưa gán Player Scene vào GameManager!")
		return

	var p := player_scene.instantiate() as Player
	p.name = "Player_%d" % id
	p.team = team
	p.input = input
	p.global_position = pos
	p.modulate = Color(randf(), randf(), randf())
	p.add_to_group("players")
	get_parent().add_child(p)
	
	

func _on_player_handle_death(player: Player) -> void:
	if is_game_over: return  # Không xử lý nếu game đã kết thúc

	# Cộng điểm cho team đối phương
	var scorer := Enums.Team.TEAM_B if player.team == Enums.Team.TEAM_A else Enums.Team.TEAM_A
	scores[scorer] += 1
	GameEvents.score_changed.emit(scorer, scores[scorer])
	
	# Nếu đang trong giai đoạn bù giờ thì kết thúc luôn
	if _current_phase == Enums.GamePhase.SUDDEN_DEATH:
		_end_game()
		return
	
	if player.has_node("EffectManager"):
		var effect_manager: EffectManager = player.get_node("EffectManager")
		effect_manager.clear_all_effects()
	
	# Vô hiệu hóa player
	player.remove_from_group("players")
	player.visible = false
	player.set_physics_process(false)

	# Hồi sinh sau delay
	await get_tree().create_timer(1.0).timeout
	if not is_game_over:
		_respawn_player(player)
	else:
		player.freeze()

func _respawn_player(player: Player) -> void:
	player.global_position = current_map.get_spawn_position(-1)
	player.visible = true
	player.set_physics_process(true)
	player.add_to_group("players")
	if player.has_method("reset_physics"):
		player.reset_physics()

# --- KẾT THÚC GAME ---
func _on_time_up() -> void:
	if scores[Enums.Team.TEAM_A] != scores[Enums.Team.TEAM_B]:
		_end_game()
		return
		
	_current_phase = Enums.GamePhase.SUDDEN_DEATH
	GameEvents.phase_changed.emit()
	_remaining_time = -1


func _end_game() -> void:
	is_game_over = true

	for p: Player in get_tree().get_nodes_in_group("players"):
		p.freeze()

	var score_a := scores[Enums.Team.TEAM_A]
	var score_b := scores[Enums.Team.TEAM_B]
	var winner = Enums.Team.TEAM_A if score_a > score_b else Enums.Team.TEAM_B
	
	for p in get_tree().get_nodes_in_group("players"):
		p.freeze()
		if winner != Enums.Team.NONE and p.team != winner:
			p.visible = false
			p.remove_from_group("players")  # Camera bỏ qua luôn

	GameEvents.game_over.emit(winner)
	

func _on_return_to_main_menu() -> void:
	# Tùy chọn: Nếu đang chơi LAN, bạn có thể gọi hàm ngắt kết nối tại đây
	# if GameData.mode == Enums.GameMode.LAN_4P:
	# 	NetworkManager.disconnect_all()
	if GameData.has_method("reset"):
		GameData.reset()
		
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
#region INPUT EVENT

func _input(event: InputEvent) -> void:
	if GameData.mode != Enums.GameMode.LOCAL_2P: return
	if event.is_action_pressed("p1_jump"):  player_inputs[1].jump = true
	if event.is_action_pressed("p1_shoot"): player_inputs[1].shoot = true
	if event.is_action_pressed("p2_jump"):  player_inputs[2].jump = true
	if event.is_action_pressed("p2_shoot"): player_inputs[2].shoot = true
	if event.is_action_pressed("p1_skill"): player_inputs[1].skill = true
	if event.is_action_pressed("p2_skill"): player_inputs[2].skill = true

func _on_movement_input_received(id: int, move: int) -> void:
	if player_inputs.has(id):
		player_inputs[id].move_direction = move

func _on_action_input_received(id: int, action: int) -> void:
	if not player_inputs.has(id): return
	match action:
		Enums.Action.JUMP:  player_inputs[id].jump = true
		Enums.Action.SHOOT: player_inputs[id].shoot = true
		Enums.Action.SKILL: player_inputs[id].skill = true

#endregion
