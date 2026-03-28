extends Control

@onready var player_name_lineedit: LineEdit = %PlayerNameLineEdit
@onready var ready_button: Button = %ReadyButton

var player_name: String

func _ready() -> void:
	var id = multiplayer.get_unique_id()
	
	if id > 1:
		player_name = "player_%d" %id # Default name
		player_name_lineedit.text = player_name
	
	ready_button.pressed.connect(_on_ready_button_pressed)
	
func _on_ready_button_pressed():
	player_name = player_name_lineedit.text
	NetworkManager.register.rpc_id(1, player_name)
