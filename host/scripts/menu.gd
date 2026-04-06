extends Control

@onready var two_players_button: Button = %TwoPlayersButton
@onready var four_players_button: Button = %FourPlayersButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	two_players_button.pressed.connect(_on_two_players_button_pressed)
	four_players_button.pressed.connect(_on_four_players_button_presssed)

func _on_two_players_button_pressed():
	GameData.mode = Enums.GameMode.LOCAL_2P
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_four_players_button_presssed():
	GameData.mode = Enums.GameMode.LAN_4P
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
