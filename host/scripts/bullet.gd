class_name Bullet extends Area2D

var fly_dir: Vector2
@export var speed: float = 500

var team: Enums.Team = Enums.Team.NONE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup(pos: Vector2, dir: Vector2, shooter_team: Enums.Team):
	position = pos
	fly_dir = dir
	team = shooter_team
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += fly_dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	if body.team == team:
		return
	
	if body.has_method("apply_knockback"):
		body.apply_knockback(fly_dir * 1000)
	queue_free()
