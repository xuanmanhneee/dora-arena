extends Node2D

# Map chỉ quản lý các vị trí và vùng nguy hiểm
@export var spawn_points: Array[Marker2D] = []
@onready var death_zone: Area2D = %DeathZone

func _ready() -> void:
	# Khi có vật thể rơi vào vực, chỉ việc bắn Event báo cho "Trọng tài"
	death_zone.body_entered.connect(_on_death_zone_body_entered)

func _on_death_zone_body_entered(body: Node) -> void:
	if body is Player:
		EventBus.emit("player_died", [body])

# Hàm hỗ trợ GameManager lấy vị trí để spawn
func get_spawn_position(index: int = -1) -> Vector2:
	if index == -1 or index >= spawn_points.size():
		return spawn_points.pick_random().global_position
	return spawn_points[index].global_position
