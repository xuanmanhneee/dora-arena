class_name ExplosionArea extends Area2D

var explosion_radius: float = 200.0
var explosion_force: float = 2000.0
var explosion_alpha: float = 0.5 # Độ mờ của vụ nổ

func _ready() -> void:
	# 1. Tạo hiệu ứng Visual bằng Tween để vụ nổ mờ dần rồi biến mất
	var tween = create_tween()
	# Vừa giãn nở bán kính (từ 0 đến radius), vừa giảm alpha (từ 0.5 về 0)
	tween.tween_property(self, "explosion_alpha", 0.0, 0.2)
	
	# 2. Xóa node sau khi diễn xong hiệu ứng
	tween.finished.connect(queue_free)

func _process(_delta: float) -> void:
	# Luôn yêu cầu vẽ lại trong lúc hiệu ứng đang chạy
	queue_redraw()

func _draw() -> void:
	# Vẽ vòng nổ mờ dần dựa trên explosion_alpha
	draw_circle(Vector2.ZERO, explosion_radius, Color(1, 0.5, 0, explosion_alpha))
	# Vẽ viền rực rỡ hơn một chút
	draw_arc(Vector2.ZERO, explosion_radius, 0, TAU, 64, Color(1, 0.8, 0, explosion_alpha * 2), 2.0)
