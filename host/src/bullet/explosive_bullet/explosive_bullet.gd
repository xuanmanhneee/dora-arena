extends BaseBullet

@export var explosion_scene: PackedScene # Kéo scene ExplosionArea.tscn vào đây

func handle_impact() -> void:
	_spawn_explosion()
	queue_free() # Đạn biến mất luôn, vụ nổ sẽ tự lo phần còn lại

func _on_max_distance_reached() -> void:

	_spawn_explosion()

	queue_free()


func _spawn_explosion():
	if explosion_scene:
		var explosion = explosion_scene.instantiate() as ExplosionArea
		explosion.global_position = global_position
		get_tree().current_scene.add_child.call_deferred(explosion)
