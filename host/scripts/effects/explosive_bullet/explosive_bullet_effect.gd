class_name ExplosiveBulletEffect extends Effect

@export var bullet_scene: PackedScene

func apply_effect(player: Player, _value: float):
	player.current_bullet = bullet_scene

func remove_effect(player: Player):
	player.current_bullet = player.NORMAL_BULLET
