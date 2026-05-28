extends MarginContainer

const LANGUAGES := [
	{"key": "language_vi", "locale": "vi"},
	{"key": "language_en", "locale": "en"},
]

@onready var bgm_value_label: Label = %BgmValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var lang_label: Label = %LangLabel
@onready var bgm_slider: HSlider = %BgmSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var lang_option_button: OptionButton = %LangOptionButton

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

	bgm_slider.value_changed.connect(_on_bgm_volume_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_value_changed)
	lang_option_button.item_selected.connect(_on_lang_selected)

	EventBus.subscribe("locale_changed", _update_locale)

	_setup_language_options()
	_update_locale()
	_sync_audio_ui()


func _setup_language_options() -> void:
	lang_option_button.clear()

	for language in LANGUAGES:
		lang_option_button.add_item(Localization.text(language.key))
		var index := lang_option_button.item_count - 1
		lang_option_button.set_item_metadata(index, language.locale)

	_select_current_locale()


func _select_current_locale() -> void:
	var current_locale := TranslationServer.get_locale()

	for i in lang_option_button.item_count:
		if lang_option_button.get_item_metadata(i) == current_locale:
			lang_option_button.select(i)
			return


func _update_locale() -> void:
	for i in lang_option_button.item_count:
		var key = LANGUAGES[i].key
		lang_option_button.set_item_text(i, Localization.text(key))

	_select_current_locale()
	lang_label.text = Localization.text("setting_language")


func _sync_audio_ui() -> void:
	bgm_slider.value = AudioManager.bgm_volume * 100.0
	bgm_value_label.text = str(int(bgm_slider.value))

	sfx_slider.value = AudioManager.sfx_volume * 100.0
	sfx_value_label.text = str(int(sfx_slider.value))


func _on_lang_selected(index: int) -> void:
	var locale := lang_option_button.get_item_metadata(index) as String
	Localization.set_locale(locale)


func _on_bgm_volume_value_changed(value: float) -> void:
	bgm_value_label.text = str(int(value))

	var normalized := value / 100.0
	AudioManager.set_bgm_volume(normalized)


func _on_sfx_volume_value_changed(value: float) -> void:
	sfx_value_label.text = str(int(value))

	var normalized := value / 100.0
	AudioManager.set_sfx_volume(normalized)
