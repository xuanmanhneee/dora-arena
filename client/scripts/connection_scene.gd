extends Control

@onready var ip_address_lineedit: LineEdit = %IpAddressLineEdit
@onready var connect_button: Button = %ConnectButton

const port: int = 7000

func _ready() -> void:
	connect_button.pressed.connect(_on_connect_button_click)

func _on_connect_button_click():
	var ip_address: String = ip_address_lineedit.text
	NetworkManager.connect_to_server(ip_address, port)
