extends Effect

func apply_effect(player: Player, _value: float):
	player.is_reflecting = true

func remove_effect(player: Player):
	player.is_reflecting = false
