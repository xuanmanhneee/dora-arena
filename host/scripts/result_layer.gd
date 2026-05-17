extends CanvasLayer

@onready var game: Game = get_parent() as Game

@onready var winner_label: Label = %WinnerLabel
@onready var play_again_button = %PlayAgainButton
@onready var return_main_menu_button = %ReturnMainMenuButton

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	return_main_menu_button.pressed.connect(_on_return_main_menu_button_pressed)
	
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.game_restarted.connect(_on_game_restarted)

func _on_play_again_button_pressed():
	GameEvents.play_again_requested.emit()

func _on_return_main_menu_button_pressed():
	GameEvents.return_main_menu_requested.emit()

func _on_game_over(winner: Enums.Team) -> void:
	visible = true
	winner_label.text = _get_winner_text(winner)

func _get_winner_text(winner: Enums.Team) -> String:
	
	if game.mode == Enums.GameMode.LOCAL_2P:
		return "P%d Win!" % (1 if winner == Enums.Team.TEAM_A else 2)
	else:
		return "Team %s Win!" % ("A" if winner == Enums.Team.TEAM_A else "B")

func _on_game_restarted() -> void:
	visible = false
