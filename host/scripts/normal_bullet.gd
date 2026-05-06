class_name NormalBullet extends BaseBullet

func _handle_impact(body: Node2D) -> void:
	super._handle_impact(body)
	
	if body.has_method("apply_knockback"):
		body.apply_knockback(fly_dir * 1000)
