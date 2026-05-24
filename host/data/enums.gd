class_name Enums

enum Team { NONE, TEAM_A, TEAM_B }
enum GameMode { LOCAL_2P, LAN_4P }

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

enum PlayerControlType {
	HUMAN,
	BOT
}

enum BotDifficulty {
	NONE,
	EASY,
	NORMAL,
	HARD,
	ASIAN
}

enum GamePhase { NORMAL, SUDDEN_DEATH }

static func is_valid_action(action: int) -> bool:
	return action in Action.values()


static func is_valid_movement(move: int) -> bool:
	return move in Movement.values()
