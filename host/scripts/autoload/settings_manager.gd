extends Node

const CONFIG_PATH := "user://settings.cfg"

var config := ConfigFile.new()

func _ready() -> void:
	load_config()

func load_config() -> void:
	var err := config.load(CONFIG_PATH)
	if err != OK:
		config = ConfigFile.new()

func save_config() -> void:
	config.save(CONFIG_PATH)

func get_setting(section: String, key: String, default_value: Variant) -> Variant:
	return config.get_value(section, key, default_value)

func set_setting(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	save_config()
