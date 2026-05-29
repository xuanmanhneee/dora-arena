extends Node

const CONFIG_PATH := "user://settings.cfg"

const DEFAULTS := {
	"audio": {
		"bgm_volume": 0.5,
		"sfx_volume": 0.8
	},
	"localization": {
		"locale": "vi"
	},
	"input": {
		"p1_left": KEY_A,
		"p1_right": KEY_D,
		"p1_jump": KEY_W,
		"p1_shoot": KEY_F,

		"p2_left": KEY_LEFT,
		"p2_right": KEY_RIGHT,
		"p2_jump": KEY_UP,
		"p2_shoot": KEY_K
	}
}

var config := ConfigFile.new()

func _ready() -> void:
	load_config()
	ensure_defaults()
	save_config()

func load_config() -> void:
	var err: int = config.load(CONFIG_PATH)
	if err != OK:
		config = ConfigFile.new()

func ensure_defaults() -> void:
	for section in DEFAULTS:
		for key in DEFAULTS[section]:
			if not config.has_section_key(section, key):
				config.set_value(section, key, DEFAULTS[section][key])

func save_config() -> void:
	config.save(CONFIG_PATH)

func get_setting(section: String, key: String, default_value: Variant) -> Variant:
	return config.get_value(section, key, default_value)

func set_setting(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	save_config()
