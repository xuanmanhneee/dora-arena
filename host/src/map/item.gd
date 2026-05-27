extends Area2D

const EFFECTS: Array[Effect] = [
	
]

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var player := area.get_parent()
	
	if player is Player:
		EventBus.emit("player_pickup_item", [player])
		queue_free()
