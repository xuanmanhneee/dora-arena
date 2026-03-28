class_name ClientInputAdapter extends InputAdapter

func _init(input: PlayerInput) -> void:
	_input = input
	NetworkManager.movement_received.connect()

func _on_move_received()
