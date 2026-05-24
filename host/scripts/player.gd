class_name Player extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const MAX_ENERGY: float = 100.0

@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shoot_pos: Marker2D = $Visual/Marker2D
@onready var hurt_box: Area2D = $HurtBox
@onready var shoot_audio: AudioStreamPlayer = $ShootAudio

const NORMAL_BULLET: PackedScene = preload("res://scenes/normal_bullet.tscn")
const EXPLOSIVE_BULLET: PackedScene = preload("res://scenes/bullet/explosive_bullet.tscn")

var current_bullet: PackedScene
@export var team: Enums.Team = Enums.Team.NONE

var is_stunned: bool = false
var stun_timer: float = 0.0

var is_reflecting: bool = false

var energy: float = 0.0
var score: int = 0

var _ultimate_damage_loop: bool = false
var _hit_sounds = [
	preload("res://assets/audio/459.mp3"),
	preload("res://assets/audio/400.mp3"),
]
var _hit_sound_index = 0

@export var stun_time: float = 0.5
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
			
		if input.skill:
			_handle_ultimate_skill()

	# 👉 decay knockback (LUÔN chạy)
	velocity.x = lerp(velocity.x, 0.0, knockback_decay * delta)

	move_and_slide()
	
	
	# reset input
	input.jump = false
	input.shoot = false
	input.skill = false

	# animation
	if not is_shooting:
		if is_stunned:
			if anim.animation != "receiveDamage":
				anim.play("receiveDamage")
		elif not is_on_floor():
			if anim.animation != "fall":
				anim.play("fall")
		else:
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
	b.setup(pos, facing_dir, team, self) 
	get_tree().current_scene.add_child(b)
	shoot_audio.play()

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
	is_shooting = false
	anim.play("receiveDamage")
	add_energy(-5.0)
	add_score(-3)
	
func freeze() -> void:
	set_physics_process(false)
	#set_process_input(false)
	_collider.set_deferred("disabled", true)
	
func _handle_ultimate_skill():
	if not can_use_ultimate(): return  # ← chặn nếu chưa đủ energy
	energy = 0.0                        # ← reset về 0
	GameEvents.energy_changed.emit(self, energy, MAX_ENERGY)  # ← cập nhật UI
	
	Engine.time_scale = 0.2
	
	# Giảm BGM
	AudioManager.player.volume_db = linear_to_db(0.1)
	
	$CinematicPlayer.speed_scale = 5.0
	$CinematicPlayer.play("ultimate_cinematic")
	
	await get_tree().create_timer(2.0, true, false, true).timeout
	
	$Visual/AnimatedSprite2D.visible = false
	$Visual/CinematicAnim.visible = true
	
	# === NOBITA PART ===
	$Visual/CinematicAnim.play("nobita_part")
	await $Visual/CinematicAnim.animation_finished  # ← chờ 6 frame chạy hết

	# === DORAEMON PART ===
	$Visual/CinematicAnim.position = Vector2(0, -20)
	$Visual/CinematicAnim.play("doraemon_part")

	$SkillAudio.stream = preload("res://assets/audio/400.mp3")
	$SkillAudio.play()

	await $Visual/CinematicAnim.animation_finished  # ← chờ 20 frame chạy hết

	_ultimate_damage_loop = true
	_run_ultimate_damage_loop()
		
	await get_tree().create_timer(3.0, true, false, true).timeout
		
	_ultimate_damage_loop = false
	$Visual/AnimatedSprite2D.visible = true
	$Visual/CinematicAnim.visible = false
	$Visual/CinematicAnim.stop()
	$SkillAudio.stop()
		
	await get_tree().create_timer(2.0, true, false, true).timeout
		
	$CinematicPlayer.stop()
	$CinematicPlayer.speed_scale = 1.0
	Engine.time_scale = 1.0
		
		# Khôi phục BGM
	AudioManager.apply_volume()

func _run_ultimate_damage_loop():
	var targets = []
	for p in get_tree().get_nodes_in_group("players"):
		if p == self: continue
		if p.team == self.team: continue
		targets.append({"node": p, "pos": p.global_position})
	
	_hit_sound_index = 0
	var shake_dir = 1
	while _ultimate_damage_loop:
		for t in targets:
			var p = t["node"]
			if not is_instance_valid(p): continue
			
			var shake_offset = Vector2(shake_dir * 5, 0)
			p.global_position = t["pos"] + shake_offset
			shake_dir *= -1
			
			p.velocity = Vector2.ZERO
			p.is_stunned = true
			p.stun_timer = 0.2
			if p.anim.animation != "receiveDamage":
				p.anim.play("receiveDamage")
		
		$SkillAudio.stream = _hit_sounds[_hit_sound_index % _hit_sounds.size()]
		$SkillAudio.play()
		_hit_sound_index += 1
		
		await get_tree().create_timer(0.05, true, false, true).timeout

func add_score(amount: int) -> void:
	score += amount
	GameEvents.player_score_changed.emit(self, score)

func add_energy(amount: float):
	energy = minf(energy + amount, MAX_ENERGY)
	GameEvents.energy_changed.emit(self, energy, MAX_ENERGY)
	
func can_use_ultimate() -> bool:
	return energy >= MAX_ENERGY
	
