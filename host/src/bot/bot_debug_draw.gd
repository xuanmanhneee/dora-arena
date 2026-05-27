class_name BotDebugDraw
extends Node2D

var bot: BotController

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if bot == null or bot._owner_player == null: return
	var origin := bot._owner_player.global_position - global_position

	# Đường đỏ → enemy
	for enemy in bot._enemies:
		if not is_instance_valid(enemy): continue
		draw_line(origin, enemy.global_position - global_position, Color.RED, 2.0)
		draw_circle(enemy.global_position - global_position, 8.0, Color.RED)

	# Đường xanh → đạn nguy hiểm
	for bullet in bot._detected_bullets:
		if not is_instance_valid(bullet): continue
		draw_line(origin, bullet.global_position - global_position, Color.CYAN, 2.0)
		draw_circle(bullet.global_position - global_position, 5.0, Color.CYAN)

	# Vòng tròn detect radius
	if bot._detect_area != null:
		draw_arc(
			bot._owner_player.global_position - global_position,
			bot.config.detect_radius,
			0, TAU, 64,
			Color(0.922, 0.914, 0.0, 1.0), 1.5
		)
