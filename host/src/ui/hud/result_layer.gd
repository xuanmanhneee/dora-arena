class_name ResultLayer extends CanvasLayer

@onready var game: Game = get_parent() as Game

@onready var winner_label: Label = %WinnerLabel
@onready var play_again_button = %PlayAgainButton
@onready var return_main_menu_button = %ReturnMainMenuButton

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	return_main_menu_button.pressed.connect(_on_return_main_menu_button_pressed)
	
	EventBus.subscribe("locale_updated", _update_locale)
	_update_locale()
	
	EventBus.subscribe("game_over", _on_game_over)
	EventBus.subscribe("game_restarted", _on_game_restarted)

func _on_play_again_button_pressed():
	EventBus.emit("play_again_requested")

func _on_return_main_menu_button_pressed():
	EventBus.emit("return_main_menu_requested")

func _on_game_over(winner: Enums.Team) -> void:
	visible = true
	winner_label.text = _get_winner_text(winner)

func _get_winner_text(winner: Enums.Team) -> String:
	if game.mode == Enums.GameMode.LOCAL_2P:
		for id in game.player_configs:
			var data := game.player_configs[id]

			if data.get("team") == winner:
				var player_name = data.get("name", "Player")

				return "%s %s" % [
					player_name,
					Localization.text("result_winner")
				]

		return Localization.text("result_unknown_winner")

	var team_name := "A" if winner == Enums.Team.TEAM_A else "B"

	return "Team %s %s" % [
		team_name,
		Localization.text("result_winner")
	]

func _on_game_restarted() -> void:
	visible = false

func _update_locale() -> void:
	play_again_button.text = Localization.text("result_play_again")
	return_main_menu_button.text = Localization.text("result_main_menu")
