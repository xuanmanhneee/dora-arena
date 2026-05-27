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
		
	
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var player := area.get_parent()
	
	if player is Player:
		EventBus.emit("player_pickup_item", [player])
		queue_free()
