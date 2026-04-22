class_name EffectManager extends Node

@export var effects: Array[Effect]

@onready var player: Player = get_parent()
var active_timers: Dictionary[Effect, Timer] = {}

func _ready() -> void:
	GameEvents.player_pickup_item.connect(_on_item_picked)

func add_effect(effect: Effect, value: float = 0.0) -> void:
	# Nếu đã có buff này rồi, cộng dồn thời gian
	if active_timers.has(effect):
		var existing_timer = active_timers[effect]
		# Lấy thời gian còn lại hiện tại + thời gian của buff mới
		var new_time = existing_timer.time_left + effect.duration
		
		# Khởi động lại timer với tổng thời gian mới
		existing_timer.start(new_time)
		return

	# Thực thi logic của buff
	effect.apply_effect(player, value)

	# Tạo Timer
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = effect.duration
	
	# Dùng callable.bind để truyền tham số vào hàm callback
	timer.timeout.connect(_on_timeout.bind(effect, timer))
	
	active_timers[effect] = timer
	timer.start()

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
		add_effect(effect)

func _select_random_effect() -> Effect:
	return effects.pick_random()
