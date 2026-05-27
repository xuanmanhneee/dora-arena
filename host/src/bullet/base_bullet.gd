class_name BaseBullet extends Area2D

var fly_dir: Vector2 = Vector2.ZERO
var team: Enums.Team = Enums.Team.NONE
var speed: float = 800
var max_distance: float = 1000.0
var knockback_force: float = 2000.0

var _start_pos: Vector2 = Vector2.ZERO
var _traveled_distance: float = 0.0
var shooter: Player = null 

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	body_entered.connect(_on_body_entered)
	
func setup(pos: Vector2, dir: Vector2, shooter_team: Enums.Team, shooter_player: Player = null) -> void:
	global_position = pos
	_start_pos = pos
	fly_dir = dir
	team = shooter_team
	rotation = dir.angle()
	shooter = shooter_player 


# Trong BaseBullet.gd
func reflect() -> void:
	# 1. Đảo ngược hướng bay
	fly_dir = -fly_dir
	
	# 2. Đổi phe (để không bắn trúng người vừa phản nó)
	team = Enums.Team.TEAM_B if team == Enums.Team.TEAM_A else Enums.Team.TEAM_A
	
	# 3. Cập nhật lại góc quay của Sprite
	rotation = fly_dir.angle()
	
	# 4. (Tùy chọn) Thêm một chút "Oomph" - cảm giác game
	speed *= 1.2 # Phản đạn thì đạn bay nhanh hơn chút cho "đã"
	
	# Có thể thêm hiệu ứng đổi màu để biết đạn đã bị phản
	modulate = Color(2, 2, 2) # Làm viên đạn sáng rực lên (Bloom)

func _process(delta: float) -> void:
	var move_vec: Vector2 = fly_dir * speed * delta
	position += move_vec
	
	_traveled_distance += move_vec.length()
	
	if _traveled_distance >= max_distance:
		_on_max_distance_reached()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.team != team:
			if shooter and is_instance_valid(shooter):
				shooter.add_energy(15.0)
				shooter.add_score(10)   
			body.apply_knockback(fly_dir * knockback_force) 
			handle_impact()                                 
	else:
		handle_impact()

func _on_max_distance_reached() -> void:
	handle_impact()

func handle_impact() -> void:
	queue_free()
