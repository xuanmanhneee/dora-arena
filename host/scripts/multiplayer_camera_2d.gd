extends Camera2D

@export var move_speed: float = 5.0  # Tốc độ di chuyển của camera
@export var zoom_speed: float = 5.0  # Tốc độ zoom
@export var min_zoom: float = 0.5    # Zoom nhỏ nhất (nhìn xa nhất)
@export var max_zoom: float = 2.0    # Zoom lớn nhất (nhìn gần nhất)
@export var margin: Vector2 = Vector2(200, 150) # Khoảng đệm bao quanh player

var players: Array[Node2D] = []

func _process(delta: float) -> void:
	# 1. Cập nhật danh sách các player đang tồn tại trong scene
	_update_player_list()
	
	if players.is_empty():
		return

	# 2. Tính toán khung bao quanh (Rect) chứa tất cả player
	var rect = _get_players_rect()
	
	# 3. Di chuyển Camera tới tâm của Rect
	var target_pos = rect.get_center()
	global_position = global_position.lerp(target_pos, move_speed * delta)
	
	# 4. Tính toán mức Zoom
	_apply_zoom(rect, delta)

func _update_player_list():
	# Tìm tất cả các node thuộc class Player hoặc trong group "players"
	# Tốt nhất là khi spawn player trong code của bạn, hãy add chúng vào group "players"
	players.clear()
	var nodes = get_tree().get_nodes_in_group("players")
	for node in nodes:
		if node is Node2D:
			players.append(node)

func _get_players_rect() -> Rect2:
	var first_pos = players[0].global_position
	var rect = Rect2(first_pos, Vector2.ZERO)
	
	for i in range(1, players.size()):
		rect = rect.expand(players[i].global_position)
	
	# Thêm lề (margin) để player không bị sát mép màn hình
	rect = rect.grow_individual(margin.x, margin.y, margin.x, margin.y)
	return rect

func _apply_zoom(rect: Rect2, delta: float):
	var screen_size = get_viewport_rect().size
	
	# Tính toán tỷ lệ giữa kích thước khung bao và kích thước màn hình
	var zoom_x = screen_size.x / rect.size.x
	var zoom_y = screen_size.y / rect.size.y
	
	# Lấy giá trị zoom nhỏ nhất để đảm bảo bao quát được cả chiều ngang và dọc
	var target_zoom_value = min(zoom_x, zoom_y)
	
	# Giới hạn trong khoảng min/max
	target_zoom_value = clamp(target_zoom_value, min_zoom, max_zoom)
	
	var target_zoom = Vector2(target_zoom_value, target_zoom_value)
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
