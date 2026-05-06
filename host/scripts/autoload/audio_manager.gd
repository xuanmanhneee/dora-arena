extends Node

const CONFIG_PATH = "user://settings.cfg"
const BGM_PATH = "res://assets/audio/bgm.mp3"
const BGM_GOOGLE_DRIVE_PATH = "https://drive.google.com/file/d/15jRw4GMBtAQ5wa46gXCO55wik_FoBodC/view?usp=sharing"

@onready var player := AudioStreamPlayer.new()

var config := ConfigFile.new()
var volume := 1.0

func _ready() -> void:
	add_child(player)
	
	if not FileAccess.file_exists(BGM_PATH):
		_show_missing_file_error()
		push_error("Missing required audio file: " + BGM_PATH)
		return
	
	var stream = load(BGM_PATH)
	
	if stream == null:
		assert(false, "Failed to load audio: " + BGM_PATH)
		return
	
	player.stream = stream
	
	load_config()
	apply_volume()
	
	player.play()

func _show_missing_file_error() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Thiếu file âm thanh (bgm.mp3)!\nTải và bổ sung vào res://assets/audio/."

	add_child(dialog)

	dialog.get_ok_button().text = "Mở link"
	dialog.get_cancel_button().text = "Thoát"

	# Nhấn OK
	dialog.confirmed.connect(_exit_game)

	# Nhấn Cancel
	dialog.canceled.connect(func():
		get_tree().quit()
	)

	# Bấm X (close window)
	dialog.close_requested.connect(func():
		get_tree().quit()
	)

	dialog.popup_centered()

func _exit_game():
	OS.shell_open(BGM_GOOGLE_DRIVE_PATH)
	get_tree().quit()

func set_volume(value: float) -> void:
	volume = clamp(value, 0.0, 1.0)
	apply_volume()
	save_config()

func apply_volume() -> void:
	player.volume_db = linear_to_db(max(volume, 0.0001))

func save_config() -> void:
	config.set_value("audio", "volume", volume)
	config.save(CONFIG_PATH)

func load_config() -> void:
	if config.load(CONFIG_PATH) == OK:
		volume = config.get_value("audio", "volume", 0.5)
	else:
		volume = 0.5
