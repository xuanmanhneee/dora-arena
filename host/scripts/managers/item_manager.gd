class_name ItemManager extends Node

var item_scene: PackedScene = preload("res://scenes/item.tscn")
@onready var map: Node2D = get_parent().get_node("Map")

@export var spawn_interval: float = 15.0

# Ép kiểu mảng (đã sửa lại cho an toàn hơn)
@onready var spawn_points: Array[Marker2D] = Array(
	get_tree().get_nodes_in_group("item_spawn_point"), 
	TYPE_OBJECT, 
	"Marker2D", 
	null
)

func _ready() -> void:
	if spawn_points.is_empty():
		push_warning("ItemManager: Không tìm thấy điểm spawn nào!")
		return
		
	print("ItemManager sẵn sàng. Số điểm spawn: ", spawn_points.size())
	
	# Tạo Timer
	var timer = Timer.new()
	timer.name = "ItemSpawnTimer" # Đặt tên để dễ tìm trong tab Remote
	add_child(timer) 
	
	timer.wait_time = spawn_interval
	timer.one_shot = false 
	timer.timeout.connect(_on_spawn_timer_timeout)
	
	# QUAN TRỌNG: Gọi start() thay vì chỉ dùng autostart khi tạo bằng code
	timer.start() 
	
	# Spawn cái đầu tiên ngay lập tức
	spawn_item()

func _on_spawn_timer_timeout() -> void:
	spawn_item()

func spawn_item() -> void:
	
	if not map:
		return
		
	if not item_scene:
		push_error("ItemManager: Chưa gán item_scene!")
		return
		
	if spawn_points.is_empty(): return

	# 1. Chọn điểm ngẫu nhiên bằng hàm pick_random() cực gọn
	var random_marker = spawn_points.pick_random()
	
	# 2. Tạo instance item
	var item_instance = item_scene.instantiate()
	
	# 3. Đặt vị trí (Dùng global_position để khớp tọa độ map)
	item_instance.global_position = random_marker.global_position
	
	# 4. Thêm vào scene tree
	# Tốt nhất là add vào Map hoặc một Node chuyên chứa Item để dễ quản lý
	if map:
		map.add_child.call_deferred(item_instance) # An toàn hơn add_child
	else:
		get_parent().add_child.call_deferred(item_instance)
