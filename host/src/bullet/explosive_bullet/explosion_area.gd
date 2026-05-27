class_name ExplosionArea extends Area2D

var explosion_radius: float = 200.0
var explosion_force: float = 2000.0

func _ready() -> void:
	$AnimatedSprite2D.play("default")

	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.2)

	tween.finished.connect(queue_free)
