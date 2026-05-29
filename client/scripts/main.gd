extends Control

@onready var up_button: Button = %UpButton
@onready var down_button: Button = %DownButton
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton
@onready var shoot_button: Button = %ShootButton
@onready var skill_button: Button = %SkillButton

func _ready() -> void:
	left_button.button_down.connect(func(): _send_move(InputType.Movement.LEFT))
	left_button.button_up.connect(func(): _send_move(InputType.Movement.IDLE))

	right_button.button_down.connect(func(): _send_move(InputType.Movement.RIGHT))
	right_button.button_up.connect(func(): _send_move(InputType.Movement.IDLE))

	up_button.pressed.connect(func(): _send_action(InputType.Action.JUMP))
	shoot_button.pressed.connect(func(): _send_action(InputType.Action.SHOOT))
	skill_button.pressed.connect(func(): 
		print("[CLIENT] Ấn skill button, gửi action: ", InputType.Action.SKILL)
		_send_action(InputType.Action.SKILL)
)


func _send_move(move: int):
	NetworkManager.send_movement_input.rpc_id(1, move)


func _send_action(action: int):
	NetworkManager.send_action_input.rpc_id(1, action)
