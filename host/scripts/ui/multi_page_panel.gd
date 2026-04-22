extends PanelContainer

@onready var close_button: Button = %CloseButton

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	close_button.pressed.connect(queue_free)
