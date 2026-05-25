extends MarginContainer


@onready var credits_label: RichTextLabel = $ScrollContainer/MarginContainer/RichTextLabel

func _ready() -> void:
	EventBus.subscribe("locale_changed", _update_locale)
	_update_locale()
	credits_label.meta_clicked.connect(_on_meta_clicked)

func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _update_locale() -> void:
	credits_label.text = Localization.bbcode_text("credits")
