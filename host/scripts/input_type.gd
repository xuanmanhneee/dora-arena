class_name InputType

enum Action {
	JUMP = 0,
	SHOOT = 1,
	SKILL = 2
}

enum Movement {
	IDLE = 0,
	LEFT = -1,
	RIGHT = 1
}

static func is_valid_action(action: int) -> bool:
	return action in Action.values()


static func is_valid_movement(move: int) -> bool:
	return move in Movement.values()
