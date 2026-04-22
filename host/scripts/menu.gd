extends Control

@onready var two_players_button: Button = %TwoPlayersButton
@onready var four_players_button: Button = %FourPlayersButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

@onready var options_panel: OptionsPanel = %OptionsPanel

var multi_page_panel: PackedScene = preload("res://scenes/ui/multi_page_panel.tscn")

func _ready() -> void:
	options_panel.visible = false
	
	two_players_button.pressed.connect(_on_two_players_button_pressed)
	four_players_button.pressed.connect(_on_four_players_button_presssed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_two_players_button_pressed():
	GameData.mode = Enums.GameMode.LOCAL_2P
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_four_players_button_presssed():
	GameData.mode = Enums.GameMode.LAN_4P
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_options_button_pressed():
	options_panel.visible = true

func _on_quit_button_pressed():
	get_tree().quit()
