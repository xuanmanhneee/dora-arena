class_name EffectManager extends Node

# 1. Thêm biến preload scene Label bạn đã tạo ở bước trước
const FLOATING_LABEL_SCENE = preload("res://src/map/floating_label.tscn")

@export var effects: Array[Effect]

@onready var player: Player = get_parent()
var active_timers: Dictionary[Effect, Timer] = {}

func _ready() -> void:
	EventBus.subscribe("player_pickup_item", _on_item_picked)

func add_effect(effect: Effect, value: float = 0.0) -> void:
	# --- HIỂN THỊ TÊN EFFECT ---
	var display_text = effect.effect_name if effect.effect_name != "" else "New Effect!"
	spawn_effect_label(display_text)
	# ---------------------------

	if active_timers.has(effect):
		var existing_timer = active_timers[effect]
		var new_time = existing_timer.time_left + effect.duration
		existing_timer.start(new_time)
		return

	effect.apply_effect(player, value)

	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = effect.duration
	timer.timeout.connect(_on_timeout.bind(effect, timer))
	
	active_timers[effect] = timer
	timer.start()

# --- HÀM HELPER ĐỂ SPAWN LABEL ---
func spawn_effect_label(text: String) -> void:
	var label = FLOATING_LABEL_SCENE.instantiate()
	
	# Thêm vào root scene để Label không bị phụ thuộc vào vị trí/di chuyển của Player sau khi spawn
	get_tree().current_scene.add_child(label)
	
	# Vị trí spawn: Trên đầu player một chút (offset lên trên khoảng 50-80 pixel)
	var spawn_pos = player.global_position + Vector2(0, -60)
	
	# Gọi hàm setup từ script Label đã viết trước đó
	if label.has_method("setup"):
		label.setup(spawn_pos, text)
	else:
		# Fallback nếu bạn chưa kịp gắn script cho Label
		label.global_position = spawn_pos
		label.text = text

func _on_timeout(effect: Effect, timer: Timer):
	effect.remove_effect(player)
	active_timers.erase(effect)
	timer.queue_free()

func clear_all_effects():
	for effect in active_timers.keys():
		effect.remove_effect(player)
		active_timers[effect].queue_free()
	active_timers.clear()

func _on_item_picked(picker: Player) -> void:
	if picker == player:
		var effect: Effect = _select_random_effect()
		if effect == null:
			print("⚠️ Không có effect nào trong danh sách!")
			return
		add_effect(effect)

func _select_random_effect() -> Effect:
	if effects.is_empty():
		push_warning("EffectManager: Mảng effects rỗng!")
		return null
	return effects.pick_random()
