extends Node

const BGM_PATH := "res://assets/audio/bgm.mp3"

@onready var player := AudioStreamPlayer.new()

var volume := 0.5

func _ready() -> void:
	add_child(player)

	var stream := load(BGM_PATH)
	if stream == null:
		push_error("Failed to load audio: " + BGM_PATH)
		return

	player.stream = stream

	load_settings()
	apply_volume()

	player.play()

func set_volume(value: float) -> void:
	volume = clamp(value, 0.0, 1.0)
	apply_volume()
	save_settings()

func apply_volume() -> void:
	player.volume_db = linear_to_db(max(volume, 0.0001))

func load_settings() -> void:
	volume = SettingsManager.get_setting("audio", "volume", 0.5)

func save_settings() -> void:
	SettingsManager.set_setting("audio", "volume", volume)
