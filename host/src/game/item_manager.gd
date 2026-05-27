class_name ItemManager
extends Node

@export var spawn_interval: float = 15.0
@export var item_scene: PackedScene = preload("res://src/map/item.tscn")

var game: Game
var map: Node2D
var spawn_points: Array[Marker2D] = []
var timer: Timer

func setup(_game: Game) -> void:
	game = _game
	map = game.current_map

	if map == null:
		push_error("ItemManager: current_map null")
		return

	_collect_spawn_points()

	if spawn_points.is_empty():
		push_warning("ItemManager: Không tìm thấy điểm spawn nào!")
		return

	_start_timer()
	spawn_item()

func _collect_spawn_points() -> void:
	spawn_points.clear()

	var root := map.get_node_or_null("ItemSpawnPoints")
	if root == null:
		push_warning("ItemManager: Map không có ItemSpawnPoints")
		return

	for child in root.get_children():
		if child is Marker2D:
			spawn_points.append(child)

func _start_timer() -> void:
	if timer == null:
		timer = Timer.new()
		timer.name = "ItemSpawnTimer"
		timer.timeout.connect(_on_spawn_timer_timeout)
		add_child(timer)

	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.start()

func _on_spawn_timer_timeout() -> void:
	spawn_item()

func spawn_item() -> void:
	if map == null or item_scene == null or spawn_points.is_empty():
		return

	var marker := spawn_points.pick_random() as Marker2D
	var item := item_scene.instantiate() as Node2D

	map.add_child(item)
	item.global_position = marker.global_position
