class_name Effect extends Resource

@export var effect_name: String = ""
@export var duration: float = 3.0
@export var icon: Texture2D

func apply_effect(_player: Player, _value: float):
	pass

func remove_effect(_player: Player):
	pass
