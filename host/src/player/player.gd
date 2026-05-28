class_name Player
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const GRAVITY = 1000.0

@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shoot_pos: Marker2D = $Visual/Marker2D
@onready var hurt_box: Area2D = $HurtBox
@onready var name_tag: Label = $NameTag

const NORMAL_BULLET: PackedScene = preload("res://src/bullet/normal_bullet/normal_bullet.tscn")
const EXPLOSIVE_BULLET: PackedScene = preload("res://src/bullet/explosive_bullet/explosive_bullet.tscn")

var current_bullet: PackedScene

@export var team: Enums.Team = Enums.Team.NONE
@export var shoot_interval: float = 1.0
@export var stun_time: float = 0.5
@export var knockback_decay: float = 8.0

@export var max_jump_count: int = 2

var jumps_left: int = 0

var _shoot_cooldown: float = 0.0

var is_controllable: bool = false
var is_camera_target: bool = true
var is_stunned: bool = false
var stun_timer: float = 0.0

var was_on_floor: bool = false
var hold_hit_until_floor: bool = false
var was_hit_in_air: bool = false

var is_reflecting: bool = false
var is_explosive_bullet: bool = false

var input: PlayerInput

var facing_dir: Vector2 = Vector2.RIGHT
var is_shooting: bool = false

# Khi true, Player không tự flip visual theo hướng di chuyển
# Bot set cái này để tự quản lý facing độc lập với movement
var override_facing: bool = false

var id: int
var display_name: String
var color: Color = Color.WHITE


func setup(
	player_id: int,
	player_name: String,
	player_team: Enums.Team,
	player_input: PlayerInput,
	player_color: Color
) -> void:
	id = player_id
	display_name = player_name
	team = player_team
	input = player_input
	color = player_color
	
	if is_node_ready():
		_apply_color()


func _ready() -> void:
	current_bullet = NORMAL_BULLET

	anim.play("run")
	anim.animation_finished.connect(_on_anim_finished)
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)
	
	name_tag.text = display_name
	_apply_color()
	_apply_team_color()


func _physics_process(delta: float) -> void:
	if input == null:
		return

	# gravity
	velocity.y += GRAVITY * delta

	# Chạm đất thì được điều khiển và hồi lại số lần nhảy
	if is_on_floor():
		if not is_controllable:
			is_controllable = true

		jumps_left = max_jump_count
	
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false

	elif is_controllable:
		# movement
		var direction: int = input.move_direction

		if direction != 0:
			velocity.x = direction * SPEED

			# Chỉ flip theo hướng đi khi không có ai override
			if not override_facing:
				facing_dir = Vector2(direction, 0)
				visual.scale.x = sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

		# jump / double jump
		if input.jump:
			_jump()
	
		# shoot
		if input.shoot:
			_handle_shoot()
	
	_shoot_cooldown -= delta
	
	# decay knockback luôn chạy
	velocity.x = lerp(velocity.x, 0.0, knockback_decay * delta)

	move_and_slide()

	# reset input
	input.jump = false
	input.shoot = false
	input.skill = false

		# animation
	if not is_shooting:

		if is_stunned:
			if anim.animation != "hit":
				anim.play("hit")

		elif not is_on_floor():

			# Nếu trước đó bị hit trên không
			if was_hit_in_air:
				if anim.animation == "hit":
					anim.pause()
					anim.frame = anim.sprite_frames.get_frame_count("hit") - 1
				else:
					anim.play("hit")
					anim.pause()
					anim.frame = anim.sprite_frames.get_frame_count("hit") - 1

			else:
				if anim.animation != "jump":
					anim.play("jump")

		else:
			# Chạm đất thì reset trạng thái
			was_hit_in_air = false

			if abs(velocity.x) > 10:
				if anim.animation != "run":
					anim.play("run")
			else:
				if anim.animation != "idle":
					anim.play("idle")


func _handle_shoot() -> void:
	if not is_shooting and _shoot_cooldown <= 0.0:
		is_shooting = true
		_shoot_cooldown = shoot_interval
		anim.play("shoot")
		_shoot()


func _jump() -> void:
	if jumps_left <= 0:
		return

	velocity.y = JUMP_VELOCITY
	jumps_left -= 1
	
	if anim.animation != "jump":
		anim.play("jump")


func _shoot() -> void:
	var b = current_bullet.instantiate() as BaseBullet
	var pos = shoot_pos.global_position
	b.setup(pos, facing_dir, team)
	get_tree().current_scene.add_child(b)


func _on_anim_finished() -> void:
	if anim.animation == "shoot":
		is_shooting = false
	
		if anim.animation == "hit" and hold_hit_until_floor and not is_on_floor():
			anim.pause()
			anim.frame = anim.sprite_frames.get_frame_count("hit") - 1

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# 1. Nếu là Đạn, có thể phản lại
	if area is BaseBullet:
		if area.team == self.team:
			return
		
		if is_reflecting:
			_handle_reflection(area)
		else:
			_handle_bullet_impact(area)

		return

	# 2. Nếu là Vụ Nổ, không thể phản, chỉ bị hất
	if area is ExplosionArea:
		_handle_explosion_impact(area)


func _handle_reflection(bullet: BaseBullet) -> void:
	bullet.reflect()


func _handle_explosion_impact(explosion: ExplosionArea) -> void:
	var push_dir: Vector2 = (global_position - explosion.global_position).normalized()

	if push_dir == Vector2.ZERO:
		push_dir = Vector2.UP
	
	var dist: float = global_position.distance_to(explosion.global_position)
	var force_multiplier: float = clamp(1.0 - (dist / explosion.explosion_radius), 0.0, 1.0)
	
	apply_knockback(push_dir * explosion.explosion_force * force_multiplier)


func _handle_bullet_impact(bullet: BaseBullet) -> void:
	apply_knockback(bullet.fly_dir * bullet.knockback_force)
	bullet.handle_impact()


func _apply_color() -> void:
	visual.modulate = color

func _apply_team_color() -> void:
	var team_color := Color.WHITE

	match team:
		Enums.Team.TEAM_A:
			team_color = Color("6aff73ff")
		Enums.Team.TEAM_B:
			team_color = Color("e73846ff")

	name_tag.add_theme_color_override("font_color", team_color)
	name_tag.add_theme_color_override("font_outline_color", Color.BLACK)
	name_tag.add_theme_constant_override("outline_size", 4)

func apply_knockback(force: Vector2) -> void:
	velocity = force

	is_stunned = true
	stun_timer = stun_time

	is_shooting = false
	
	# Nếu đang trên không hoặc bị hất bay lên
	was_hit_in_air = not is_on_floor() or force.y < 0

	anim.play("hit")


func freeze() -> void:
	set_physics_process(false)
	_collider.set_deferred("disabled", true)
