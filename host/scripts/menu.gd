extends Control

@onready var title_image_texture_rect: TextureRect = %TitleImageTextureRect

@onready var two_players_button: Button = %TwoPlayersButton
@onready var four_players_button: Button = %FourPlayersButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

@onready var placeholder_panel: Control = %PlaceholderPanel
@onready var match_setup_panel: Control = %MatchSetupPanel
@onready var options_panel: Control = %OptionsPanel

func _ready() -> void:
	two_players_button.pressed.connect(_on_two_players_button_pressed)
	four_players_button.pressed.connect(_on_four_players_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	EventBus.subscribe("locale_changed", _update_locale)

	_update_locale()
	_show_panel(placeholder_panel)


func _update_locale() -> void:
	title_image_texture_rect.texture = Localization.texture("menu_background")

	two_players_button.text = Localization.text("menu_2_players_local")
	four_players_button.text = Localization.text("menu_4_player_lan")
	options_button.text = Localization.text("menu_options")
	quit_button.text = Localization.text("menu_quit")


func _on_two_players_button_pressed() -> void:
	_show_panel(match_setup_panel, Enums.GameMode.LOCAL_2P)


func _on_four_players_button_pressed() -> void:
	_show_panel(match_setup_panel, Enums.GameMode.LAN_4P)


func _on_options_button_pressed() -> void:
	_show_panel(options_panel)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _show_panel(panel: Control, data: Variant = null) -> void:
	placeholder_panel.hide()
	match_setup_panel.hide()
	options_panel.hide()

	panel.show()

	if panel.has_method("on_open"):
		panel.on_open(data)
