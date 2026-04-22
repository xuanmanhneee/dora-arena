extends BaseBullet

var explosion_radius: float = 200
var _is_exploding = false

func _on_max_distance_reached() -> void:
	# Không gọi super ở đây vì nó sẽ xóa đạn ngay
	await _explode()
	queue_free() # Tự xóa sau khi nổ xong

func _handle_impact(_body: Node2D) -> void:
	# Không gọi super ở đây
	await _explode()
	queue_free()

func _explode():
	if _is_exploding: return
	_is_exploding = true
	
	# 1. Thực hiện quét vật lý và đẩy (Giữ nguyên logic của bạn)
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1 
	
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)

	for res in results:
		var obj = res.collider
		if obj.has_method("apply_knockback"):
			var push_dir = (obj.global_position - global_position).normalized()
			var dist = global_position.distance_to(obj.global_position)
			var force_multiplier = clamp(1.0 - (dist / explosion_radius), 0.0, 1.0)
			obj.apply_knockback(push_dir * 2000 * force_multiplier)

	# 2. Xử lý phần nhìn (Visual)
	speed = 0 # Dừng đạn lại thay vì set_process(false) để đảm bảo _draw vẫn chạy
	$Sprite2D.visible = false # Ẩn hình ảnh viên đạn đi chỉ hiện vòng tròn nổ
	
	queue_redraw() # Yêu cầu Godot vẽ lại (gọi _draw)
	
	# Đợi một chút để mắt người kịp thấy vòng tròn
	await get_tree().create_timer(0.15).timeout

func _draw():
	if _is_exploding:
		# Vẽ vòng tròn đặc màu cam nhạt
		draw_circle(Vector2.ZERO, explosion_radius, Color(1, 0.5, 0, 0.4))
		# Vẽ thêm viền cho rõ nét
		draw_arc(Vector2.ZERO, explosion_radius, 0, TAU, 64, Color(1, 0.8, 0, 1), 2.0)

'''
extends BaseBullet

var explosion_radius: float = 200

func _on_max_distance_reached() -> void:
	_explode()
	super._on_max_distance_reached()

func _handle_impact(body: Node2D) -> void:
	_explode()
	super._handle_impact(body)

func _explode():
	# 1. Tạo hình tròn để quét
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius

	# 2. Cấu hình tham số quét
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform # Lấy vị trí tại tâm vụ nổ
	query.collision_mask = 1 # Chỉ quét layer chứa Player/Enemy
	
	# 3. Thực hiện quét không gian vật lý
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)

	# 4. Xử lý kết quả
	for res in results:
		var obj = res.collider
		if obj.has_method("apply_knockback") and obj != self:
			var push_dir = (obj.global_position - global_position).normalized()
			# Tính lực đẩy (có thể giảm dần theo khoảng cách)
			var dist = global_position.distance_to(obj.global_position)
			var force_multiplier = 1.0 - (dist / explosion_radius)
			
			obj.apply_knockback(push_dir * 1200 * force_multiplier)
			
	# Bắt đầu vẽ
	set_process(false) # Dừng di chuyển
	set_physics_process(false) # Dừng va chạm thêm
	_is_exploding = true # Biến flag để vẽ
	queue_redraw() # Gọi hàm _draw()
	
	# Đợi 0.1s cho người chơi thấy rồi mới xóa
	await get_tree().create_timer(0.1).timeout

var _is_exploding = false

func _draw():
	if _is_exploding:
		# Vẽ vòng tròn nổ tại tâm (0,0) của đạn
		draw_circle(Vector2.ZERO, explosion_radius, Color(1, 0.5, 0, 0.5)) # Màu cam mờ
'''
