class_name GameCamera
extends Camera2D

@export var move_speed: float = 5.0
@export var zoom_speed: float = 5.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var margin: Vector2 = Vector2(200, 150)

var game: Game

func setup(game_ref: Game) -> void:
	game = game_ref
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

	var target_pos: Vector2 = rect.get_center()
	global_position = global_position.lerp(target_pos, move_speed * delta)

	_apply_zoom(rect, delta)

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
	target_zoom_value = clamp(target_zoom_value, min_zoom, max_zoom)

	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
