extends Node2D

@export var spawn_points: Array[Marker2D] = []
@onready var death_zone: Area2D = %DeathZone

func _ready() -> void:
	death_zone.area_entered.connect(_on_death_zone_area_entered)

func _on_death_zone_area_entered(area: Area2D) -> void:
	var player := area.get_parent()

	if player is Player:
		EventBus.emit("player_died", [player])

func get_spawn_position(index: int = -1) -> Vector2:
	if index == -1 or index >= spawn_points.size():
		return spawn_points.pick_random().global_position
	return spawn_points[index].global_position
