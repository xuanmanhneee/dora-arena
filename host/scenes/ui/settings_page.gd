extends MarginContainer

@onready var bgm_value_label: Label = %BgmValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var bgm_slider: HSlider = %BgmSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var lang_option_button: OptionButton = %LangOptionButton

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	
	bgm_slider.value_changed.connect(_on_bgm_volume_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_value_changed)
	
	# sync từ AudioManager
	var volume = AudioManager.volume * 100.0
	bgm_slider.value = volume
	bgm_value_label.text = str(int(bgm_slider.value))
	
	sfx_value_label.text = str(int(sfx_slider.value))
	

func _on_bgm_volume_value_changed(value: float) -> void:
	bgm_value_label.text = str(int(value))
	
	var normalized = value / 100.0
	AudioManager.set_volume(normalized)

func _on_sfx_volume_value_changed(value: float) -> void:
	sfx_value_label.text = str(int(value))
