class_name BaseBullet extends Area2D

var fly_dir: Vector2 = Vector2.ZERO
var team: Enums.Team = Enums.Team.NONE
var speed: float = 500
var max_distance: float = 500.0

var _start_pos: Vector2 = Vector2.ZERO
var _traveled_distance: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func setup(pos: Vector2, dir: Vector2, shooter_team: Enums.Team) -> void:
	global_position = pos
	_start_pos = pos
	fly_dir = dir
	team = shooter_team
	rotation = dir.angle()

func _process(delta: float) -> void:
	var move_vec: Vector2 = fly_dir * speed * delta
	position += move_vec
	
	_traveled_distance += move_vec.length()
	
	if _traveled_distance >= max_distance:
		_on_max_distance_reached()

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	if body.team == team:
		return

	_handle_impact(body)

func _on_max_distance_reached() -> void:
	queue_free()

func _handle_impact(_body: Node2D) -> void:
	queue_free()
