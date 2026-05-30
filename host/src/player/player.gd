class_name Player
extends CharacterBody2D

# ============================================================
# PLAYER.GD - Script điều khiển nhân vật chính
# Xử lý: di chuyển, nhảy, bắn đạn, chiêu cuối (Ultimate Skill)
# ============================================================


# --- HẰNG SỐ ---
const SPEED = 300.0           # Tốc độ di chuyển ngang
const JUMP_VELOCITY = -600.0  # Lực nhảy (âm = lên trên trong Godot)
const GRAVITY = 1000.0        # Lực kéo xuống mỗi frame
const MAX_ENERGY: float = 100.0  # Năng lượng tối đa để dùng chiêu cuối


# --- THAM CHIẾU NODE ---
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shoot_pos: Marker2D = $Visual/Marker2D
@onready var hurt_box: Area2D = $HurtBox
@onready var name_tag: Label = $NameTag
@onready var shoot_audio: AudioStreamPlayer = $ShootAudio
@onready var skill_effect: AnimatedSprite2D = $Visual/SkillEffectSprite
@onready var skill_effect_gun: AnimatedSprite2D = $Visual/SkillEffectGun


# --- PRELOAD TÀI NGUYÊN ---
const NORMAL_BULLET: PackedScene = preload("res://src/bullet/normal_bullet/normal_bullet.tscn")
const EXPLOSIVE_BULLET: PackedScene = preload("res://src/bullet/explosive_bullet/explosive_bullet.tscn")

# Danh sách âm thanh khi bị đánh (dùng trong chiêu cuối)
var _hit_sounds = [
	preload("res://assets/audio/459.mp3"),
	preload("res://assets/audio/400.mp3"),
]


# --- BIẾN TRẠNG THÁI ---
var current_bullet: PackedScene  # Loại đạn hiện tại

# Export: có thể chỉnh trong Inspector của Godot Editor
@export var team: Enums.Team = Enums.Team.NONE
@export var shoot_interval: float = 1.0   # Thời gian hồi chiêu bắn
@export var stun_time: float = 0.5        # Thời gian bị choáng khi trúng đạn
@export var knockback_decay: float = 8.0  # Tốc độ giảm lực bắn văng
@export var max_jump_count: int = 2       # Số lần nhảy tối đa (double jump)

var jumps_left: int = 0        # Số lần nhảy còn lại
var _shoot_cooldown: float = 0.0  # Bộ đếm hồi chiêu bắn

# Trạng thái khi bị chiêu cuối tác động
var is_being_hit_by_skill: bool = false  # Đang nhận đòn từ skill
var is_frozen_by_skill: bool = false     # Bị đóng băng bởi skill
var is_using_skill: bool = false         # Đang thi triển skill

# Trạng thái điều khiển
var is_controllable: bool = false  # Có thể điều khiển chưa
var is_camera_target: bool = true  # Camera có theo dõi nhân vật này không
var is_stunned: bool = false       # Đang bị choáng
var stun_timer: float = 0.0       # Bộ đếm thời gian choáng

# Trạng thái animation khi bị đánh trên không
var was_on_floor: bool = false
var hold_hit_until_floor: bool = false
var was_hit_in_air: bool = false  # Có bị đánh khi đang bay không

# Trạng thái đặc biệt
var is_reflecting: bool = false        # Đang phản đạn
var is_explosive_bullet: bool = false  # Đang dùng đạn nổ

# Input và hướng nhìn
var input: PlayerInput
var facing_dir: Vector2 = Vector2.RIGHT  # Hướng nhân vật đang nhìn
var is_shooting: bool = false            # Đang trong animation bắn
var override_facing: bool = false        # Khóa hướng nhìn (dùng trong skill)

# Thông tin người chơi (nhận từ lobby)
var id: int
var display_name: String
var color: Color = Color.WHITE

# Năng lượng và điểm số
var energy: float = 0.0
var score: int = 0
var _ultimate_damage_loop: bool = false
var _hit_sound_index = 0


# ============================================================
# KHỞI TẠO
# ============================================================

# Gọi từ bên ngoài để truyền dữ liệu người chơi vào
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
	# Kết nối signal: animation kết thúc và vùng va chạm
	anim.animation_finished.connect(_on_anim_finished)
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)
	name_tag.text = display_name
	_apply_color()
	_apply_team_color()


# ============================================================
# VÒNG LẶP CHÍNH (chạy mỗi frame vật lý)
# ============================================================

func _physics_process(delta: float) -> void:
	if input == null:
		return

	# Áp dụng trọng lực
	velocity.y += GRAVITY * delta

	# Khi chạm đất: cho phép điều khiển và hồi lại số lần nhảy
	if is_on_floor():
		if not is_controllable:
			is_controllable = true
		jumps_left = max_jump_count

	# Xử lý trạng thái choáng
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			if is_on_floor():
				anim.play("idle")

	elif is_controllable:
		# Di chuyển ngang
		var direction: int = input.move_direction
		if direction != 0:
			velocity.x = direction * SPEED
			if not override_facing:
				facing_dir = Vector2(direction, 0)
				visual.scale.x = sign(direction)  # Lật sprite theo hướng di chuyển
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)  # Giảm tốc khi không nhấn

		if input.jump:
			_jump()
		if input.shoot:
			_handle_shoot()
		if input.skill:
			_handle_ultimate_skill()

	# Giảm cooldown bắn
	_shoot_cooldown -= delta

	# Giảm dần lực văng theo thời gian
	velocity.x = lerp(velocity.x, 0.0, knockback_decay * delta)

	move_and_slide()

	# Reset input sau mỗi frame (tránh nhập liệu bị giữ)
	input.jump = false
	input.shoot = false
	input.skill = false

	# Xử lý animation (chỉ khi không đang bắn hoặc dùng skill)
	if not is_shooting and not is_using_skill:
		_update_animation()


# Cập nhật animation dựa trên trạng thái hiện tại
func _update_animation() -> void:
	if is_stunned:
		if not is_frozen_by_skill:
			# Bị choáng thật sự → play animation hit
			if anim.animation != "hit":
				anim.play("hit")
		elif is_being_hit_by_skill:
			# Đang nhận đòn từ skill → giữ animation hit
			if anim.animation != "hit":
				anim.play("hit")
		else:
			# Bị đóng băng bởi skill → đứng yên
			if anim.animation != "idle":
				anim.play("idle")

	elif not is_on_floor():
		# Đang trên không
		if was_hit_in_air:
			# Bị đánh khi bay → giữ frame cuối animation hit
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
		# Chạm đất → reset trạng thái bay
		was_hit_in_air = false
		if abs(velocity.x) > 10:
			if anim.animation != "run":
				anim.play("run")
		else:
			if anim.animation != "idle":
				anim.play("idle")


# ============================================================
# CÁC HÀM HÀNH ĐỘNG CƠ BẢN
# ============================================================

func _handle_shoot() -> void:
	# Chỉ bắn khi không đang trong animation bắn và đã hết cooldown
	if not is_shooting and _shoot_cooldown <= 0.0:
		is_shooting = true
		_shoot_cooldown = shoot_interval
		anim.play("shoot")
		_shoot()
		add_energy(100.0)  # Bắn được thêm năng lượng


func _jump() -> void:
	if jumps_left <= 0:
		return
	velocity.y = JUMP_VELOCITY
	jumps_left -= 1
	if anim.animation != "jump":
		anim.play("jump")


func _shoot() -> void:
	# Tạo viên đạn và bắn ra theo hướng nhân vật đang nhìn
	var b = current_bullet.instantiate() as BaseBullet
	var pos = shoot_pos.global_position
	b.setup(pos, facing_dir, team)
	get_tree().current_scene.add_child(b)
	if has_node("ShootAudio"):
		shoot_audio.play()
	EventBus.emit("player_shoot", [self])


# ============================================================
# XỬ LÝ VA CHẠM VÀ SÁT THƯƠNG
# ============================================================

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is BaseBullet:
		if area.team == self.team:
			return  # Bỏ qua đạn của cùng đội
		if is_reflecting:
			_handle_reflection(area)
			AudioManager.play_reflect_bullet()
		else:
			_handle_bullet_impact(area)
		return
	if area is ExplosionArea:
		_handle_explosion_impact(area)


func _handle_reflection(bullet: BaseBullet) -> void:
	# Phản ngược hướng viên đạn lại
	bullet.reflect()


func _handle_explosion_impact(explosion: ExplosionArea) -> void:
	# Tính lực đẩy từ vụ nổ dựa trên khoảng cách
	var push_dir: Vector2 = (global_position - explosion.global_position).normalized()
	if push_dir == Vector2.ZERO:
		push_dir = Vector2.UP
	var dist: float = global_position.distance_to(explosion.global_position)
	var force_multiplier: float = clamp(1.0 - (dist / explosion.explosion_radius), 0.0, 1.0)
	apply_knockback(push_dir * explosion.explosion_force * force_multiplier)


func _handle_bullet_impact(bullet: BaseBullet) -> void:
	# Áp dụng lực bắn văng và xử lý hiệu ứng của viên đạn
	apply_knockback(bullet.fly_dir * bullet.knockback_force)
	bullet.handle_impact()


func apply_knockback(force: Vector2) -> void:
	# Áp dụng lực đẩy, gây choáng và trừ năng lượng
	velocity = force
	is_stunned = true
	stun_timer = stun_time
	is_shooting = false
	was_hit_in_air = not is_on_floor() or force.y < 0
	anim.play("hit")
	add_energy(-5.0)


# ============================================================
# CALLBACK ANIMATION
# ============================================================

func _on_anim_finished() -> void:
	# Khi animation bắn kết thúc → cho phép bắn lại
	if anim.animation == "shoot":
		is_shooting = false
	# Khi bị đánh trên không → giữ frame cuối cho đến khi chạm đất
	if anim.animation == "hit" and hold_hit_until_floor and not is_on_floor():
		anim.pause()
		anim.frame = anim.sprite_frames.get_frame_count("hit") - 1


# ============================================================
# MÀU SẮC VÀ HIỂN THỊ
# ============================================================

func _apply_color() -> void:
	visual.modulate = color

func _apply_team_color() -> void:
	# Đổi màu tên theo đội: xanh lá = Team A, đỏ = Team B
	var team_color := Color.WHITE
	match team:
		Enums.Team.TEAM_A:
			team_color = Color("6aff73ff")
		Enums.Team.TEAM_B:
			team_color = Color("e73846ff")
	name_tag.add_theme_color_override("font_color", team_color)
	name_tag.add_theme_color_override("font_outline_color", Color.BLACK)
	name_tag.add_theme_constant_override("outline_size", 4)


# ============================================================
# FREEZE / UNFREEZE (dùng trong chiêu cuối)
# ============================================================

func freeze() -> void:
	# Đóng băng hoàn toàn nhân vật (dùng khi game over hoặc kết thúc match)
	set_physics_process(false)
	_collider.set_deferred("disabled", true)
	_ultimate_damage_loop = false
	is_using_skill = false

func freeze_for_skill() -> void:
	# Đóng băng nhân vật khi bị chiêu cuối của đối thủ tác động
	is_frozen_by_skill = true
	is_stunned = true
	stun_timer = 9999.0  # Giữ choáng vô thời hạn cho đến khi được giải phóng

func unfreeze_from_skill() -> void:
	is_frozen_by_skill = false
	is_stunned = false
	stun_timer = 0.0

func freeze_gravity() -> void:
	# Tắt physics_process → nhân vật không bị rơi (treo trên không)
	set_physics_process(false)

func unfreeze_gravity() -> void:
	set_physics_process(true)


# ============================================================
# NĂNG LƯỢNG VÀ ĐIỂM SỐ
# ============================================================

func add_score(amount: int) -> void:
	score += amount
	EventBus.emit("player_score_changed", [self, score])

func add_energy(amount: float) -> void:
	energy = minf(energy + amount, MAX_ENERGY)
	EventBus.emit("energy_changed", [self, energy, MAX_ENERGY])

func can_use_ultimate() -> bool:
	# Chỉ dùng chiêu cuối khi đã đầy năng lượng
	return energy >= MAX_ENERGY


# ============================================================
# CHIÊU CUỐI (ULTIMATE SKILL) - 3 PHASE
# Flow: Teleport đấm → Nobita bắn súng → Storm cuốn hất bay
# ============================================================

func _handle_ultimate_skill() -> void:
	if not can_use_ultimate(): return

	energy = 0.0
	is_using_skill = true
	EventBus.emit("energy_changed", [self, energy, MAX_ENERGY])

	# Bật hiệu ứng cinematic (thanh đen trên dưới)
	if has_node("CinematicPlayer"):
		$CinematicPlayer.play("ultimate_cinematic")

	await get_tree().create_timer(1.0).timeout

	# Tìm tất cả kẻ địch và đóng băng chúng lại
	var targets = []
	for p in get_tree().get_nodes_in_group("players"):
		if p == self: continue
		if p.team == self.team: continue
		targets.append(p)
		p.freeze_for_skill()

	# Xử lý từng kẻ địch
	for target in targets:

		# ── PHASE 1: DORAEMON TELEPORT VÀ ĐẤM ──────────────────
		# Teleport đến phía sau kẻ địch (animation cánh cửa lần 1)
		anim.play("skill_teleport")
		await anim.animation_finished

		var behind = target.global_position + Vector2(-target.facing_dir.x * 80, 0)
		global_position = behind
		facing_dir = Vector2(target.facing_dir.x, 0)
		visual.scale.x = target.facing_dir.x

		# Teleport lần 2: xuất hiện
		anim.play("skill_teleport")
		await anim.animation_finished

		# Thi triển đòn đấm
		anim.play("skill")
		anim.speed_scale = 0.5  # Làm chậm để hiệu ứng đẹp hơn
		skill_effect.visible = true
		skill_effect.speed_scale = 4.0 / 11.0
		skill_effect.play("skill_effect")

		await get_tree().create_timer(0.3).timeout

		# Bắt đầu shake kẻ địch song song (không await → chạy nền)
		target.is_being_hit_by_skill = true
		target.anim.play("hit")
		var target_origin_skill = target.global_position
		_shake_target(target, target_origin_skill, 10, 12.0, 0.10)

		await anim.animation_finished

		# Dọn dẹp hiệu ứng sau đòn đấm
		anim.speed_scale = 0.5
		skill_effect.visible = false
		skill_effect.stop()
		target.is_being_hit_by_skill = false
		target.is_frozen_by_skill = false
		target.is_stunned = false
		target.stun_timer = 0.0

		await get_tree().process_frame

		# Hất kẻ địch ra xa
		target.apply_knockback(facing_dir * 4000 + Vector2(0, -400))
		target.stun_timer = 1.2


		# ── PHASE 2: NOBITA BẮN SÚNG ────────────────────────────
		await get_tree().create_timer(0.3).timeout  # Chờ kẻ địch bay ra

		# Đóng băng cả 2 treo trên không
		target.freeze_gravity()
		freeze_gravity()
		target.velocity = Vector2.ZERO

		var target_origin = target.global_position

		# Shake song song trong lúc Nobita chuẩn bị
		_shake_target(target, target_origin, 15, 12.0, 0.15)

		# Di chuyển Nobita ra phía sau kẻ địch (ngược hướng Doraemon)
		var doraemon_dir = facing_dir.x
		var nobita_pos = target.global_position + Vector2(doraemon_dir * 150, 0)
		global_position = nobita_pos
		visual.scale.x = -doraemon_dir
		facing_dir = Vector2(-doraemon_dir, 0)

		# Âm thanh mở/đóng cửa khi Nobita xuất hiện
		if has_node("SkillAudio"):
			$SkillAudio.stream = preload("res://assets/audio/open_door.mp3")
			$SkillAudio.play()
		await get_tree().create_timer(0.3).timeout
		if has_node("SkillAudio"):
			$SkillAudio.stream = preload("res://assets/audio/close_door.mp3")
			$SkillAudio.play()

		# Play animation Nobita bắn súng
		anim.speed_scale = 1.0
		anim.play("skill_nobita")

		# Delay 0.4s để trigger tiếng súng đúng lúc Nobita bắn (frame 2)
		await get_tree().create_timer(0.4).timeout

		# Bật hiệu ứng tia súng
		skill_effect_gun.visible = true
		skill_effect_gun.play("skill_effect_gun")

		await anim.animation_finished

		# Giữ frame cuối của Nobita thêm 1.5s
		anim.pause()
		await get_tree().create_timer(1.5).timeout

		# Tắt hiệu ứng và hất kẻ địch lần 2
		skill_effect_gun.visible = false
		skill_effect_gun.stop()
		anim.play("skill_nobita")

		target.unfreeze_gravity()
		unfreeze_gravity()
		target.apply_knockback(Vector2(-doraemon_dir, 0) * 4000 + Vector2(0, -200))


		# ── PHASE 3: DORAEMON TUNG BÃO (STORM) ─────────────────
		await get_tree().create_timer(0.3).timeout  # Chờ kẻ địch bay ra

		# Đóng băng kẻ địch và bản thân
		target.freeze_gravity()
		target.velocity = Vector2.ZERO
		var storm_origin = target.global_position
		freeze_gravity()

		# Âm thanh cửa khi Doraemon teleport lên trên đầu
		if has_node("SkillAudio"):
			$SkillAudio.stream = preload("res://assets/audio/open_door.mp3")
			$SkillAudio.play()

		# Teleport biến mất
		anim.play("skill_teleport")
		await anim.animation_finished

		# Di chuyển lên trên đầu kẻ địch
		global_position = target.global_position + Vector2(0, -100)
		facing_dir = Vector2(1, 0)
		visual.scale.x = 1

		# Tiếng đóng cửa khi xuất hiện
		if has_node("SkillAudio"):
			$SkillAudio.stream = preload("res://assets/audio/close_door.mp3")
			$SkillAudio.play()

		# Teleport xuất hiện
		anim.play("skill_teleport")
		await anim.animation_finished

		# Shake kẻ địch song song trong lúc storm
		_shake_target(target, storm_origin, 15, 12.0, 0.15)

		# Tung chiêu bão
		anim.speed_scale = 1.0
		anim.play("skill_storm")

		# Gây sát thương liên tục trong suốt animation bão (~2.47s)
		var storm_duration = 37.0 / 15.0  # 37 frame @ 15 FPS
		var damage_interval = 0.5
		var elapsed = 0.0
		while elapsed < storm_duration:
			await get_tree().create_timer(damage_interval).timeout
			elapsed += damage_interval
			target.apply_knockback(Vector2(0, 0))  # Gây choáng tại chỗ, không hất
			target.velocity = Vector2.ZERO          # Giữ kẻ địch không bay đi

		await get_tree().create_timer(0.1).timeout

		# Giải phóng và hất kẻ địch lần cuối
		target.unfreeze_gravity()
		unfreeze_gravity()
		target.apply_knockback(Vector2(facing_dir.x * 3000, -500))
		# ── KẾT THÚC ULTIMATE SKILL ─────────────────────────────

	# Kết thúc cinematic ngay sau khi skill xong
	if has_node("CinematicPlayer"):
		$CinematicPlayer.stop()
		$CinematicPlayer.play("RESET")
		await get_tree().create_timer(0.3).timeout
		$CinematicPlayer.stop()

	is_using_skill = false
	anim.play("idle")


# ============================================================
# HÀM RUNG LẮC KẺ ĐỊCH (dùng trong các phase của chiêu cuối)
# Tham số:
#   target  - nhân vật bị rung
#   origin  - vị trí gốc (để reset sau khi rung)
#   count   - số lần rung
#   offset  - biên độ rung (pixel)
#   speed   - thời gian mỗi lần rung (giây)
# ============================================================

func _shake_target(target: Player, origin: Vector2,
		count: int = 6, offset: float = 8.0, speed: float = 0.08) -> void:
	for i in count:
		if not is_instance_valid(target): break
		var direction = 1 if i % 2 == 0 else -1
		target.global_position = origin + Vector2(direction * offset, 0)
		target.anim.play("hit")
		await get_tree().create_timer(speed).timeout
	# Trả kẻ địch về vị trí gốc sau khi rung xong
	if is_instance_valid(target):
		target.global_position = origin


# ============================================================
# HÀM PHỤ TRỢ (không còn dùng trong flow chính, giữ lại phòng hờ)
# ============================================================

func _run_ultimate_damage_loop() -> void:
	# Loop gây sát thương liên tục - phiên bản cũ, hiện không dùng
	var targets = []
	for p in get_tree().get_nodes_in_group("players"):
		if p == self: continue
		if p.team == self.team: continue
		targets.append({"node": p, "pos": p.global_position})

	_hit_sound_index = 0
	var shake_dir = 1
	while _ultimate_damage_loop:
		anim.play("skill")
		skill_effect.visible = true
		skill_effect.play("skill_effect")
		await anim.animation_finished
		skill_effect.stop()
		skill_effect.visible = false

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

		anim.play("idle")
		await get_tree().create_timer(0.3).timeout
