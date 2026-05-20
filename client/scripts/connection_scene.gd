extends Control

@onready var ip_address_lineedit: LineEdit = %IpAddressLineEdit
@onready var connect_button: Button = %ConnectButton

const CONFIG_PATH := "user://network.cfg"
const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 7000

var port := DEFAULT_PORT


func _ready() -> void:
	load_config()
	connect_button.pressed.connect(_on_connect_button_click)


func load_config() -> void:
	var config := ConfigFile.new()

	if config.load(CONFIG_PATH) != OK:
		ip_address_lineedit.text = DEFAULT_IP
		return

	ip_address_lineedit.text = config.get_value(
		"network",
		"ip",
		DEFAULT_IP
	)

	port = config.get_value(
		"network",
		"port",
		DEFAULT_PORT
	)


func save_config(ip: String) -> void:
	var config := ConfigFile.new()

	config.set_value("network", "ip", ip)
	config.set_value("network", "port", port)

	config.save(CONFIG_PATH)


func _on_connect_button_click() -> void:
	var ip_address := ip_address_lineedit.text.strip_edges()

	save_config(ip_address)

	NetworkManager.connect_to_server(ip_address, port)
