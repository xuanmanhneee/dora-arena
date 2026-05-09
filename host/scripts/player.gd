class_name Player extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shoot_pos: Marker2D = $Visual/Marker2D
@onready var hurt_box: Area2D = $HurtBox

const NORMAL_BULLET: PackedScene = preload("res://scenes/normal_bullet.tscn")
const EXPLOSIVE_BULLET: PackedScene = preload("res://scenes/bullet/explosive_bullet.tscn")

var current_bullet: PackedScene
@export var team: Enums.Team = Enums.Team.NONE

var is_stunned: bool = false
var stun_timer: float = 0.0

var is_reflecting: bool = false

@export var stun_time: float = 0.2
@export var knockback_decay: float = 8.0

var input: PlayerInput

var facing_dir: Vector2 = Vector2.RIGHT
var is_shooting: bool = false

func _ready() -> void:
	current_bullet = NORMAL_BULLET
	anim.play("run")
	anim.animation_finished.connect(_on_anim_finished)
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)

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
	var b = current_bullet.instantiate() as BaseBullet
	var pos = shoot_pos.global_position
	b.setup(pos, facing_dir, team)
	get_tree().current_scene.add_child(b)

func _on_anim_finished():
	if anim.animation == "shoot":
		is_shooting = false

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# 1. Nếu là Đạn (Có thể phản lại)
	if area is BaseBullet:
		if area.team == self.team: return
		
		if is_reflecting:
			_handle_reflection(area)
		else:
			# Đổi tên từ damage thành impact cho đúng tính chất
			_handle_bullet_impact(area)
		return

	# 2. Nếu là Vụ Nổ (Không thể phản, chỉ bị hất)
	if area is ExplosionArea:
		_handle_explosion_impact(area)

func _handle_reflection(bullet: BaseBullet):
	bullet.reflect()

func _handle_explosion_impact(explosion: ExplosionArea):
	# Tự tính hướng và lực dựa trên vị trí tâm nổ
	var push_dir = (global_position - explosion.global_position).normalized()
	if push_dir == Vector2.ZERO: push_dir = Vector2.UP
	
	var dist = global_position.distance_to(explosion.global_position)
	var force_multiplier = clamp(1.0 - (dist / explosion.explosion_radius), 0.0, 1.0)
	
	# Hất văng Player
	apply_knockback(push_dir * explosion.explosion_force * force_multiplier)

func _handle_bullet_impact(bullet: BaseBullet):
	# Chỉ quan tâm đến việc bị hất văng
	apply_knockback(bullet.fly_dir * bullet.knockback_force)
	bullet.handle_impact()
	
func apply_knockback(force: Vector2):
	velocity.x = force.x
	velocity.y = force.y
	is_stunned = true
	stun_timer = stun_time

func freeze() -> void:
	set_physics_process(false)
	#set_process_input(false)
	_collider.set_deferred("disabled", true)
