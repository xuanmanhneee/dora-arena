extends Control

@onready var center_container: CenterContainer = %CenterContainer
@onready var vbox_container: VBoxContainer = $CenterContainer/VBoxContainer
@onready var ip_address_lineedit: LineEdit = %IpAddressLineEdit
@onready var connect_button: Button = %ConnectButton

const CONFIG_PATH := "user://network.cfg"
const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 7000

var port := DEFAULT_PORT

var _keyboard_height: float = 0.0
var _initial_vbox_y: float = 0.0
var _has_saved_position: bool = false

func _ready() -> void:
	load_config()
	connect_button.pressed.connect(_on_connect_button_click)

func _process(_delta):
	if not _has_saved_position and vbox_container.position.y > 0:
		_initial_vbox_y = vbox_container.position.y
		_has_saved_position = true

	var kb_height = DisplayServer.virtual_keyboard_get_height()
	if kb_height != _keyboard_height:
		_keyboard_height = kb_height
		_update_container_position()

func _update_container_position():
	if not _has_saved_position:
		return
		
	var tween = create_tween()
	# Dùng set_parallel() để vừa đẩy cả Box lên, vừa chỉnh khoảng cách Label cùng một lúc
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if _keyboard_height > 0:
		# 1. Đẩy cả cụm VBox lên để né bàn phím
		var target_offset_y = _initial_vbox_y - 140.0
		tween.tween_property(vbox_container, "position:y", target_offset_y, 0.20)
		
		# 2. Tăng khoảng cách tách biệt (separation) của VBox để đẩy các phần tử giãn ra/dịch xuống
		# Bạn có thể tăng số 30 này lên nếu muốn Label cách xa các ô dưới hơn nữa
		tween.tween_property(vbox_container, "theme_overrides_constants/separation", 0, 0.20)
	else:
		# Khi hạ bàn phím: Trả mọi thứ về trạng thái ban đầu
		tween.tween_property(vbox_container, "position:y", _initial_vbox_y, 0.20)
		# Trả khoảng cách các nút về mặc định (ví dụ ban đầu trên Editor bạn để là 10)
		tween.tween_property(vbox_container, "theme_overrides_constants/separation", 10, 0.20)


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
