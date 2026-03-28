class_name Player extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

@onready var visual = $Visual
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shoot_pos: Marker2D = $Visual/Marker2D

@export var bullet: PackedScene
@export var team: TeamDef.Team = TeamDef.Team.NONE

var is_stunned: bool = false
var stun_timer: float = 0.0

@export var stun_time: float = 0.2
@export var knockback_decay: float = 8.0

var input: PlayerInput

var facing_dir: Vector2 = Vector2.RIGHT
var is_shooting: bool = false

func _ready() -> void:
	anim.play("run")
	anim.animation_finished.connect(_on_anim_finished)


func _physics_process(delta: float) -> void:
	if input == null:
		return
	
	# gravity
	velocity.y += 1000 * delta

	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
	else:
		# movement
		var direction: int = input.move_direction

		if direction != 0:
			velocity.x = direction * SPEED
			
			facing_dir = Vector2(direction, 0)
			visual.scale.x = sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# jump
		if input.jump and is_on_floor():
			_jump()

		# shoot
		if input.shoot:
			_handle_shoot()

	# 👉 decay knockback (LUÔN chạy)
	velocity.x = lerp(velocity.x, 0.0, knockback_decay * delta)

	move_and_slide()
	
	# reset input
	input.jump = false
	input.shoot = false
	input.skill = false

	# animation
	if not is_shooting:
		if anim.animation != "run":
			anim.play("run")

func _handle_shoot():
	if not is_shooting:
		is_shooting = true
		anim.play("shoot")
		_shoot()

func _jump():
	velocity.y = JUMP_VELOCITY

func _shoot():
	var b = bullet.instantiate() as Bullet
	var pos = shoot_pos.global_position
	b.setup(pos, facing_dir, team)
	get_tree().current_scene.add_child(b)

func _on_anim_finished():
	if anim.animation == "shoot":
		is_shooting = false

func apply_knockback(force: Vector2):
	velocity.x = force.x
	velocity.y = force.y
	is_stunned = true
	stun_timer = stun_time
