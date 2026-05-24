class_name GameCamera
extends Camera2D

@export var move_speed: float = 5.0
@export var zoom_speed: float = 5.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var margin: Vector2 = Vector2(200, 150)

# Rect giới hạn map theo global coordinate
# Ví dụ map của bạn bắt đầu tại (0, 0), size 1920x1080 thì để như dưới
@export var map_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1920, 1080))

var game: Game


func setup(game_ref: Game) -> void:
	game = game_ref

	limit_left = int(map_bounds.position.x)
	limit_top = int(map_bounds.position.y)
	limit_right = int(map_bounds.end.x)
	limit_bottom = int(map_bounds.end.y)

	set_process(true)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if game == null:
		return

	var players: Array[Node2D] = _get_alive_players()
	if players.is_empty():
		return

	var rect: Rect2 = _get_players_rect(players)

	_apply_zoom(rect, delta)

	var target_pos: Vector2 = rect.get_center()
	global_position = global_position.lerp(target_pos, move_speed * delta)

	_clamp_camera_to_bounds()


func _get_alive_players() -> Array[Node2D]:
	var result: Array[Node2D] = []

	for player: Player in game.players.values():
		if player == null:
			continue
		if not is_instance_valid(player):
			continue
		if not player.is_camera_target:
			continue

		result.append(player)

	return result


func _get_players_rect(players: Array[Node2D]) -> Rect2:
	var first_pos: Vector2 = players[0].global_position
	var rect: Rect2 = Rect2(first_pos, Vector2.ZERO)

	for i in range(1, players.size()):
		rect = rect.expand(players[i].global_position)

	return rect.grow_individual(margin.x, margin.y, margin.x, margin.y)


func _apply_zoom(rect: Rect2, delta: float) -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var zoom_x: float = screen_size.x / rect.size.x
	var zoom_y: float = screen_size.y / rect.size.y

	var target_zoom_value: float = min(zoom_x, zoom_y)

	# Không cho zoom out quá mức làm lộ ngoài map
	var min_zoom_by_bounds: float = max(
		screen_size.x / map_bounds.size.x,
		screen_size.y / map_bounds.size.y
	)

	var effective_min_zoom: float = max(min_zoom, min_zoom_by_bounds)

	target_zoom_value = clamp(target_zoom_value, effective_min_zoom, max_zoom)

	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)


func _clamp_camera_to_bounds() -> void:
	var visible_size: Vector2 = get_viewport_rect().size / zoom
	var half_visible_size: Vector2 = visible_size * 0.5

	var min_pos: Vector2 = map_bounds.position + half_visible_size
	var max_pos: Vector2 = map_bounds.end - half_visible_size

	var clamped_pos: Vector2 = global_position

	if min_pos.x > max_pos.x:
		clamped_pos.x = map_bounds.get_center().x
	else:
		clamped_pos.x = clamp(clamped_pos.x, min_pos.x, max_pos.x)

	if min_pos.y > max_pos.y:
		clamped_pos.y = map_bounds.get_center().y
	else:
		clamped_pos.y = clamp(clamped_pos.y, min_pos.y, max_pos.y)

	global_position = clamped_pos
