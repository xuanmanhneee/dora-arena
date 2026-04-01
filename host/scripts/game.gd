extends Node2D

@onready var death_zone: Area2D = %DeathZone

@export var spawn_points: Array[Marker2D] = []
@export var player_scene: PackedScene

var player_inputs: Dictionary[int, PlayerInput] = {}

func _ready() -> void:
	death_zone.body_entered.connect(_on_death_zone_body_entered)
	
	if GameData.mode == GameMode.LOCAL_2P:
		_setup_local_mode()
	else:
		_setup_lan_mode()
		

func _process(_delta: float) -> void:
	if GameData.mode == GameMode.LOCAL_2P:
		player_inputs[1].move_direction = int(Input.get_axis("p1_left", "p1_right"))
		player_inputs[2].move_direction = int(Input.get_axis("p2_left", "p2_right"))

func _setup_local_mode():
	var input1 = PlayerInput.new()
	var input2 = PlayerInput.new()
	player_inputs[1] = input1
	player_inputs[2] = input2
	
	var p1 = player_scene.instantiate() as Player
	p1.team = Enums.Team.TEAM_A
	p1.input = input1
	p1.position = Vector2(300, 300)  # thêm vị trí

	
	var p2 = player_scene.instantiate() as Player
	p2.team = Enums.Team.TEAM_B
	p2.input = input2
	p2.position = Vector2(500, 300)  # thêm vị trí
	
	p1.add_to_group("players")
	p2.add_to_group("players")
	
	add_child(p1)
	add_child(p2)

func _setup_lan_mode():
	NetworkManager.movement_input_received.connect(_on_movement_input_received)
	NetworkManager.action_input_received.connect(_on_action_input_received)
	
	var index = 0
	for id in GameData.player_teams:
		var input = PlayerInput.new()
		player_inputs[id] = input
		
		var p = player_scene.instantiate() as Player
		p.add_to_group("players")
		p.team = GameData.player_teams[id]
		p.input = input
		p.position = spawn_points[index].position
		add_child(p)
		index += 1

func _input(event: InputEvent) -> void:
	if GameData.mode != GameMode.LOCAL_2P:
		return
	if event.is_action_pressed("p1_jump"):
		player_inputs[1].jump = true
	if event.is_action_pressed("p1_shoot"):
		player_inputs[1].shoot = true
	if event.is_action_pressed("p2_jump"):
		player_inputs[2].jump = true
	if event.is_action_pressed("p2_shoot"):
		player_inputs[2].shoot = true

func _on_movement_input_received(id: int, move: int):
	if not player_inputs.has(id):
		return
	
	player_inputs[id].move_direction = move


func _on_action_input_received(id: int, action: int):
	if not player_inputs.has(id):
		return
	
	var input: PlayerInput = player_inputs[id]
	
	match action:
		InputType.Action.JUMP:
			input.jump = true
		InputType.Action.SHOOT:
			input.shoot = true
		InputType.Action.SKILL:
			input.skill = true

# XỬ LÝ KHI RƠI XUỐNG VỰC
func _on_death_zone_body_entered(body: Node) -> void:
	if body is Player:
		_handle_player_death(body)

func _handle_player_death(player: Player):
	# 1. Tạm thời xóa khỏi group để Camera không "đuổi theo" xác dưới vực
	player.remove_from_group("players")
	
	# 2. Tắt va chạm và hiển thị (giả lập chết)
	player.visible = false
	# Giả sử trong Player.gd bạn có cách để vô hiệu hóa điều khiển tạm thời
	
	# 3. Chờ 1 giây để hồi sinh (Dùng Timer hoặc await)
	await get_tree().create_timer(1.0).timeout
	
	# 4. Gọi hàm hồi sinh
	_respawn_player(player)

func _respawn_player(player: Player):
	# Chọn ngẫu nhiên 1 điểm từ danh sách Marker2D bạn đã kéo vào @export
	if spawn_points.is_empty():
		player.global_position = Vector2(400, 300) # Vị trí mặc định nếu quên set điểm
	else:
		var spawn_point = spawn_points.pick_random()
		player.global_position = spawn_point.global_position
	
	# 5. Hiển thị lại và cho Camera focus trở lại
	player.visible = true
	player.add_to_group("players")
	
	# Reset các trạng thái vật lý (vận tốc) của player trong script Player.gd nếu cần
	if player.has_method("reset_physics"):
		player.reset_physics()
