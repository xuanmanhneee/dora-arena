extends Control

@onready var player_name_lineedit: LineEdit = %PlayerNameLineEdit
@onready var player_color_picker_button: ColorPickerButton = %PlayerColorPickerButton
@onready var ready_button: Button = %ReadyButton

var player_name: String


func _ready() -> void:
	var id := multiplayer.get_unique_id()

	if id > 1:
		player_name = "player_%d" % id
	else:
		player_name = "host"

	player_name_lineedit.text = player_name

	ready_button.pressed.connect(_on_ready_button_pressed)


func _on_ready_button_pressed() -> void:
	player_name = player_name_lineedit.text.strip_edges()

	if player_name.is_empty():
		player_name = "player_%d" % multiplayer.get_unique_id()

	var player_color := player_color_picker_button.color

	NetworkManager.register.rpc_id(1, player_name, player_color)

	ready_button.disabled = true
	player_name_lineedit.editable = false
	player_color_picker_button.disabled = true
