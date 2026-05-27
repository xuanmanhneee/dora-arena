extends Area2D

const EFFECTS: Array[Effect] = [
	preload("res://scripts/effects/reflect/reflect_effect.tres"),
	preload("res://scripts/effects/explosive_bullet/explosive_bullet_effect.tres"),
]

@onready var sprite: Sprite2D = $Sprite2D

var current_effect: Effect = null

func _ready() -> void:
	current_effect = EFFECTS.pick_random()
	
	# Hiển thị icon
	if current_effect and current_effect.icon:
		sprite.texture = current_effect.icon
		
	
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.emit("player_pickup_item", [body])
		queue_free()
