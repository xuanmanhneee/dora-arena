extends Area2D

const EFFECTS: Array[Effect] = [
	
]

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		GameEvents.player_pickup_item.emit(body)
		queue_free()
