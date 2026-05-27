class_name BotController
extends Node

enum State { CHASE, HOLD, RETREAT, WANDER, DODGE, SEEK_ITEM }

@export var config: BotConfig
var player_input: PlayerInput
var game_ref: Game
var player_id: int

var _owner_player: Player
var _enemies: Array[Player] = []
var _detected_bullets: Array[BaseBullet] = []
var _detect_area: Area2D

var _reaction_timer: float = 0.0
var _state: State = State.CHASE
var _wander_timer: float = 0.0
var _wander_dir: int = 0

const DIST_HYSTERESIS := 20.0

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	await get_tree().process_frame
	_owner_player = game_ref.players.get(player_id)
	_owner_player.override_facing = true
	_find_enemies()
	_setup_detect_area()

	if OS.is_debug_build():
		var debug := BotDebugDraw.new()
		debug.bot = self
		game_ref.world.add_child(debug)

# ─────────────────────────────────────────────────────────────────────────────
#  Setup
# ─────────────────────────────────────────────────────────────────────────────
func _setup_detect_area() -> void:
	_detect_area = Area2D.new()
	_detect_area.monitoring = true
	_detect_area.monitorable = false
	_detect_area.collision_layer = 0
	_detect_area.collision_mask = 2  # bullet layer
	var shape := CircleShape2D.new()
	shape.radius = config.detect_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_detect_area.add_child(col)
	_owner_player.add_child(_detect_area)
	_detect_area.area_entered.connect(_on_area_entered)
	_detect_area.area_exited.connect(_on_area_exited)

func _find_enemies() -> void:
	for id in game_ref.players:
		var p: Player = game_ref.players[id]
		if p == _owner_player: continue
		if p.team == _owner_player.team: continue
		_enemies.append(p)

# ─────────────────────────────────────────────────────────────────────────────
#  Bullet detection (Area2D callbacks)
# ─────────────────────────────────────────────────────────────────────────────
func _on_area_entered(area: Area2D) -> void:
	if area is BaseBullet and area.team != _owner_player.team:
		if _detected_bullets.has(area): return
		_detected_bullets.append(area)
		if not area.tree_exited.is_connected(_detected_bullets.erase.bind(area)):
			area.tree_exited.connect(_detected_bullets.erase.bind(area))

func _on_area_exited(area: Area2D) -> void:
	if area is BaseBullet:
		_detected_bullets.erase(area)

# ─────────────────────────────────────────────────────────────────────────────
#  Main loop
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _owner_player == null or not _owner_player.visible: return
	if _enemies.is_empty(): return

	_wander_timer -= delta

	_reaction_timer -= delta
	if _reaction_timer > 0.0: return
	_reaction_timer = max(config.reaction_delay, 0.016) * randf_range(0.7, 1.3)

	player_input.move_direction = 0
	player_input.shoot = false
	player_input.jump = false

	var enemy := _get_nearest_enemy()
	if enemy == null: return

	_update_state(enemy)
	_execute_state(enemy)

# ─────────────────────────────────────────────────────────────────────────────
#  State machine
# ─────────────────────────────────────────────────────────────────────────────
func _update_state(enemy: Player) -> void:
	var dist := _owner_player.global_position.distance_to(enemy.global_position)
	var bullet_range := _get_bullet_range()

	# ── Ưu tiên 1: Né đạn ────────────────────────────────────────────────
	if config.scan_bullets and _has_dangerous_bullet():
		if randf() < config.dodge_rate:
			_state = State.DODGE
			return

	# ── Ưu tiên 2: Nhặt item ─────────────────────────────────────────────
	if not config.scan_bullets or not _has_dangerous_bullet():
		var item := _find_nearest_item()
		if item != null:
			_state = State.SEEK_ITEM
			return

	# ── Khoảng cách với hysteresis ────────────────────────────────────────
	var chase_threshold := minf(bullet_range, config.preferred_dist_max)

	if _state == State.CHASE:
		if dist < config.preferred_dist_min:
			_state = State.RETREAT
		elif dist <= chase_threshold - DIST_HYSTERESIS:
			_state = State.HOLD
	elif _state == State.RETREAT:
		if dist > config.preferred_dist_min + DIST_HYSTERESIS:
			_state = State.HOLD
	else:
		# HOLD / WANDER
		if dist > chase_threshold:
			_state = State.CHASE
		elif dist < config.preferred_dist_min:
			_state = State.RETREAT
		elif _wander_timer > 0.0:
			_state = State.WANDER
		else:
			if randf() < config.wander_chance:
				_wander_dir = [-1, 1].pick_random()
				_wander_timer = config.wander_duration
				_state = State.WANDER
			else:
				_state = State.HOLD

func _execute_state(enemy: Player) -> void:
	var diff_x := enemy.global_position.x - _owner_player.global_position.x
	var dist := _owner_player.global_position.distance_to(enemy.global_position)
	var bullet_range := _get_bullet_range()

	match _state:
		State.CHASE:
			player_input.move_direction = sign(diff_x) as int
			_try_jump_if_blocked()

		State.RETREAT:
			player_input.move_direction = -sign(diff_x) as int

		State.WANDER:
			player_input.move_direction = _wander_dir

		State.HOLD:
			player_input.move_direction = 0

		State.DODGE:
			_execute_dodge()

		State.SEEK_ITEM:
			_execute_seek_item()

	# ── Facing và bắn: luôn nhìn về enemy, độc lập với di chuyển ─────────
	if dist <= bullet_range:
		_owner_player.facing_dir = Vector2(sign(diff_x), 0)
		_owner_player.visual.scale.x = sign(diff_x)
		_try_shoot(enemy)

# ─────────────────────────────────────────────────────────────────────────────
#  State executors
# ─────────────────────────────────────────────────────────────────────────────
func _execute_dodge() -> void:
	var threat := _get_most_dangerous_bullet()
	if threat == null:
		_state = State.HOLD
		return

	var bullet_vel: Vector2 = threat.velocity
	var to_bot := _owner_player.global_position - threat.global_position

	if abs(bullet_vel.x) >= abs(bullet_vel.y):
		player_input.jump = true
	else:
		player_input.move_direction = sign(to_bot.x) as int

func _execute_seek_item() -> void:
	var item := _find_nearest_item()
	if item == null:
		_state = State.CHASE
		return
	var diff_x := item.global_position.x - _owner_player.global_position.x
	player_input.move_direction = sign(diff_x) as int

func _try_jump_if_blocked() -> void:
	var body := _owner_player as CharacterBody2D
	if body == null: return
	if body.is_on_floor() and body.is_on_wall():
		player_input.jump = true

# ─────────────────────────────────────────────────────────────────────────────
#  Shooting logic
# ─────────────────────────────────────────────────────────────────────────────
func _try_shoot(enemy: Player) -> void:
	if config.check_enemy_buffs:
		if enemy.is_reflecting:
			return

		if enemy.current_bullet == enemy.EXPLOSIVE_BULLET:
			var dist := _owner_player.global_position.distance_to(enemy.global_position)
			if dist < config.preferred_dist_min * 1.5:
				player_input.move_direction = -sign(
					enemy.global_position.x - _owner_player.global_position.x
				) as int
				return

	if randf() > config.shoot_hesitate_chance:
		player_input.shoot = true

# ─────────────────────────────────────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────────────────────────────────────
func _get_nearest_enemy() -> Player:
	var nearest: Player = null
	var min_dist := INF
	for e in _enemies:
		if not is_instance_valid(e): continue
		var d := _owner_player.global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _get_bullet_range() -> float:
	for b in _detected_bullets:
		if is_instance_valid(b):
			return b.max_distance
	for node in get_tree().get_nodes_in_group("bullets"):
		if node is BaseBullet:
			return node.max_distance
	return 250.0

func _has_dangerous_bullet() -> bool:
	return _get_most_dangerous_bullet() != null

func _get_most_dangerous_bullet() -> BaseBullet:
	var bot_pos := _owner_player.global_position
	for b in _detected_bullets:
		if not is_instance_valid(b): continue
		if not b.has_meta("velocity"): continue

		var to_bot := bot_pos - b.global_position
		var vel: Vector2 = b.velocity

		if vel.dot(to_bot) > 0.0:
			var vel_norm := vel.normalized()
			var miss_dist = abs(to_bot.x * vel_norm.y - to_bot.y * vel_norm.x)
			var player_half_width := 24.0

			if config.consider_explosion and b.has_meta("explosion_radius"):
				player_half_width += float(b.get_meta("explosion_radius"))

			if miss_dist < player_half_width:
				return b
	return null

func _find_nearest_item() -> Node2D:
	var bot_pos := _owner_player.global_position
	var best: Node2D = null
	var best_score := INF

	for item in get_tree().get_nodes_in_group("items"):
		if not is_instance_valid(item): continue
		var dist := bot_pos.distance_to(item.global_position)
		if dist > config.item_seek_range: continue

		var score := dist
		if config.item_priority > 0.0:
			var value := _evaluate_item(item)
			score = dist / max(value * config.item_priority, 0.01)

		if score < best_score:
			best_score = score
			best = item
	return best

func _evaluate_item(item: Node2D) -> float:
	if item.has_meta("item_type"):
		var itype: String = item.get_meta("item_type")
		if itype == "health":
			var hp_ratio := float(_owner_player.current_hp) / float(_owner_player.max_hp)
			if hp_ratio > 0.85: return 0.1
			return 2.0
		if itype == "attack_buff":
			return 3.0
	return 1.0
