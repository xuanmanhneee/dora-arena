extends MarginContainer


@onready var credits_label: RichTextLabel = $ScrollContainer/MarginContainer/RichTextLabel

func _ready() -> void:
	credits_label.meta_clicked.connect(_on_meta_clicked)

func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
