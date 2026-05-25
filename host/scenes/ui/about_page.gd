extends MarginContainer

@onready var game_name_label: Label = $ScrollContainer/VBoxContainer/GameNameLabel
@onready var version_label: Label = $ScrollContainer/VBoxContainer/VersionLabel
@onready var description_label: Label = $ScrollContainer/VBoxContainer/DescriptionLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.subscribe("locale_changed", _update_locale)
	_update_locale()


func _update_locale() -> void:
	game_name_label.text = Localization.text("about_game_name")
	version_label.text = Localization.text("about_version")
	description_label.text = Localization.localized_text_file("about_description")
