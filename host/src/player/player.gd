class_name Player
extends CharacterBody2D

# --- CONSTANTS ---
const SPEED = 300.0
const JUMP_VELOCITY = -600.0 # Giữ lực nhảy mới
const GRAVITY = 1000.0       # Giữ trọng lực mới
const MAX_ENERGY: float = 100.0 # Bê từ file cũ sang

# --- ONREADY NODES ---
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shoot_pos: Marker2D = $Visual/Marker2D
@onready var hurt_box: Area2D = $HurtBox
@onready var name_tag: Label = $NameTag # Giữ nhãn tên mới
@onready var shoot_audio: AudioStreamPlayer = $ShootAudio # Mang âm thanh trở lại
@onready var skill_effect: AnimatedSprite2D = $Visual/SkillEffectSprite

# --- PRELOAD ASSETS ---
const NORMAL_BULLET: PackedScene = preload("res://src/bullet/normal_bullet/normal_bullet.tscn")
const EXPLOSIVE_BULLET: PackedScene = preload("res://src/bullet/explosive_bullet/explosive_bullet.tscn")

var _hit_sounds = [
	preload("res://assets/audio/459.mp3"),
	preload("res://assets/audio/400.mp3"),
]

# --- VARIABLES ---
var current_bullet: PackedScene

@export var team: Enums.Team = Enums.Team.NONE
@export var shoot_interval: float = 1.0
@export var stun_time: float = 0.5
@export var knockback_decay: float = 8.0
@export var max_jump_count: int = 2

var jumps_left: int = 0
var _shoot_cooldown: float = 0.0

var is_being_hit_by_skill: bool = false
var is_frozen_by_skill: bool = false
var is_using_skill: bool = false

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
var override_facing: bool = false

# Dữ liệu phòng chờ (Mới)
var id: int
var display_name: String
var color: Color = Color.WHITE

# Năng lượng & Điểm số (Khôi phục từ file cũ)
var energy: float = 0.0
var score: int = 0
var _ultimate_damage_loop: bool = false
var _hit_sound_index = 0


# --- HÀM KHỞI TẠO (Bắt buộc của nhánh mới) ---
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


func _physics_process(delta: float) -> void:
	if input == null:
		return

	# gravity
	velocity.y += GRAVITY * delta

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
			
		# KHÔI PHỤC: Kích hoạt Chiêu cuối
		if input.skill:
			_handle_ultimate_skill()
	
	_shoot_cooldown -= delta
	
	# decay knockback
	velocity.x = lerp(velocity.x, 0.0, knockback_decay * delta)

	move_and_slide()

	# reset input
	input.jump = false
	input.shoot = false
	input.skill = false

		# animation
	if not is_shooting and not is_using_skill:

		if is_stunned:
			if not is_frozen_by_skill:          # ← chỉ play "hit" khi bị stunned thật sự
				if anim.animation != "hit":
					anim.play("hit")
					
			elif is_being_hit_by_skill:        # ← đang nhận đòn → giữ "hit"
				if anim.animation != "hit":
						anim.play("hit")
			else:
				if anim.animation != "idle":    # ← khi bị freeze bởi skill thì đứng yên
					anim.play("idle")

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
		add_energy(100.0)


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
	# Giữ nguyên signature mới (Không truyền self) để tránh lỗi Đạn trên main
	b.setup(pos, facing_dir, team) 
	get_tree().current_scene.add_child(b)
	
	# KHÔI PHỤC: Chạy âm thanh bắn
	if has_node("ShootAudio"): 
		shoot_audio.play()


func _on_anim_finished() -> void:
	if anim.animation == "shoot":
		is_shooting = false
	
		if anim.animation == "hit" and hold_hit_until_floor and not is_on_floor():
			anim.pause()
			anim.frame = anim.sprite_frames.get_frame_count("hit") - 1

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is BaseBullet:
		if area.team == self.team:
			return
		if is_reflecting:
			_handle_reflection(area)
		else:
			_handle_bullet_impact(area)
		return

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


# KHÔI PHỤC: Trừ điểm và năng lượng khi dính đạn
func apply_knockback(force: Vector2) -> void:
	velocity = force

	is_stunned = true
	stun_timer = stun_time

	is_shooting = false
	
	# Nếu đang trên không hoặc bị hất bay lên
	was_hit_in_air = not is_on_floor() or force.y < 0

	anim.play("hit")
	
	# Tính năng khi bị bắn trúng thì trừ điểm
	add_energy(-5.0)


func freeze() -> void:
	set_physics_process(false)
	_collider.set_deferred("disabled", true)
	_ultimate_damage_loop = false
	is_using_skill = false


# =======================================
# 🔥 TOÀN BỘ LOGIC CHIÊU CUỐI & ĐIỂM SỐ
# =======================================

func _handle_ultimate_skill():
	if not can_use_ultimate(): return  
	energy = 0.0
	is_using_skill = true
	EventBus.emit("energy_changed", [self, energy, MAX_ENERGY])
	
	if has_node("CinematicPlayer"):
		$CinematicPlayer.play("ultimate_cinematic")
	
	await get_tree().create_timer(1.0).timeout
	
	var targets = []
	for p in get_tree().get_nodes_in_group("players"):
		if p == self: continue
		if p.team == self.team: continue
		targets.append(p)
		p.freeze_for_skill()

	for target in targets:
		anim.play("skill_teleport")
		await anim.animation_finished

		var behind = target.global_position + Vector2(-target.facing_dir.x * 80, 0)
		global_position = behind
		facing_dir = Vector2(target.facing_dir.x, 0)
		visual.scale.x = target.facing_dir.x

		anim.play("skill_teleport")
		await anim.animation_finished

		anim.play("skill")
		anim.speed_scale = 0.5
		skill_effect.visible = true
		skill_effect.speed_scale = 4.0 / 11.0
		skill_effect.play("skill_effect")
		
		await get_tree().create_timer(0.3).timeout
		target.is_being_hit_by_skill = true
		target.anim.play("hit")    
		
		await anim.animation_finished
		
		anim.speed_scale = 0.5
		skill_effect.visible = false
		skill_effect.stop()
		
		target.is_being_hit_by_skill = false
		target.is_frozen_by_skill = false
		target.is_stunned = false
		target.stun_timer = 0.0 
		
		await get_tree().process_frame
		
		target.apply_knockback(facing_dir * 10000 + Vector2(0, -400))
		target.stun_timer = 1.2
		
	await get_tree().create_timer(0.5).timeout
	
	if has_node("CinematicPlayer"):
		await $CinematicPlayer.animation_finished
		$CinematicPlayer.play("RESET")  # reset bars về 0
		await get_tree().create_timer(0.5).timeout
		$CinematicPlayer.stop()
	
	is_using_skill = false
	anim.play("idle")

func _run_ultimate_damage_loop():
	var targets = []
	for p in get_tree().get_nodes_in_group("players"):
		if p == self: continue
		if p.team == self.team: continue
		targets.append({"node": p, "pos": p.global_position})
	
	_hit_sound_index = 0
	var shake_dir = 1
	while _ultimate_damage_loop:
		# 1. Chạy animation đấm - chỉ 1 lần
		anim.play("skill")
		skill_effect.visible = true
		skill_effect.play("skill_effect")
		
		# 2. Chờ CẢ HAI xong cùng lúc
		await anim.animation_finished
		
		skill_effect.stop()
		skill_effect.visible = false
		
		# 3. Gây damage sau khi đấm xong
		var shake_offset = Vector2(shake_dir * 5, 0)
		shake_dir *= -1
		for t in targets:
			var p = t["node"]
			if not is_instance_valid(p): continue
			p.global_position = t["pos"] + shake_offset
			p.velocity = Vector2.ZERO
			p.is_stunned = true
			p.stun_timer = 0.3
			p.anim.play("hit")
		
		if has_node("SkillAudio"):
			$SkillAudio.stream = _hit_sounds[_hit_sound_index % _hit_sounds.size()]
			$SkillAudio.play()
		_hit_sound_index += 1
		
		# 4. Khoảng trống giữa các lần đấm - chèn animation khác vào đây
		anim.play("idle")
		await get_tree().create_timer(0.3).timeout




func add_score(amount: int) -> void:
	score += amount
	EventBus.emit("player_score_changed", [self, score])


func add_energy(amount: float):
	energy = minf(energy + amount, MAX_ENERGY)
	EventBus.emit("energy_changed", [self, energy, MAX_ENERGY])
	

func can_use_ultimate() -> bool:
	return energy >= MAX_ENERGY


# Sửa freeze_for_skill / unfreeze_from_skill
func freeze_for_skill() -> void:
	is_frozen_by_skill = true
	is_stunned = true
	stun_timer = 9999.0

func unfreeze_from_skill() -> void:
	is_frozen_by_skill = false
	is_stunned = false
	stun_timer = 0.0
