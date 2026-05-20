class_name BotController
extends Node

enum State { CHASE, HOLD, RETREAT, WANDER }

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

func _setup_detect_area() -> void:
	_detect_area = Area2D.new()
	_detect_area.monitoring = true
	_detect_area.monitorable = false
	_detect_area.collision_layer = 0
	_detect_area.collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = config.detect_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_detect_area.add_child(col)
	_owner_player.add_child(_detect_area)
	_detect_area.area_entered.connect(_on_area_entered)
	_detect_area.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is BaseBullet and area.team != _owner_player.team:
		if _detected_bullets.has(area): return
		_detected_bullets.append(area)
		if not area.tree_exited.is_connected(_detected_bullets.erase.bind(area)):
			area.tree_exited.connect(_detected_bullets.erase.bind(area))

func _on_area_exited(area: Area2D) -> void:
	if area is BaseBullet:
		_detected_bullets.erase(area)

func _find_enemies() -> void:
	for id in game_ref.players:
		var p: Player = game_ref.players[id]
		if p == _owner_player: continue
		if p.team == _owner_player.team: continue
		_enemies.append(p)

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

func _process(delta: float) -> void:
	if _owner_player == null or not _owner_player.visible: return
	if _enemies.is_empty(): return

	_wander_timer -= delta
	_reaction_timer -= delta
	if _reaction_timer > 0.0: return
	_reaction_timer = config.reaction_delay * randf_range(0.7, 1.3)

	var enemy := _get_nearest_enemy()
	if enemy == null: return

	_update_state(enemy)
	_execute_state(enemy)

func _update_state(enemy: Player) -> void:
	var dist := _owner_player.global_position.distance_to(enemy.global_position)
	var bullet_range := _get_bullet_range()

	if dist > bullet_range:
		_state = State.CHASE
	elif dist < config.preferred_dist_min:
		_state = State.RETREAT
	elif _wander_timer > 0.0:
		_state = State.WANDER
	else:
		# Trong tầm bắn, tung xúc xắc wander
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
		State.RETREAT:
			player_input.move_direction = -sign(diff_x) as int
		State.WANDER:
			player_input.move_direction = _wander_dir
		State.HOLD:
			player_input.move_direction = 0

	# Facing và bắn luôn hướng về enemy, độc lập với hướng di chuyển
	if dist <= bullet_range:
		_owner_player.facing_dir = Vector2(sign(diff_x), 0)
		_owner_player.visual.scale.x = sign(diff_x)
		if randf() > config.shoot_hesitate_chance:
			player_input.shoot = true
