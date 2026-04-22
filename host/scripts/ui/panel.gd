extends Panel

@export_range(0.1, 1.0) var width_ratio := 0.6:
	set(value):
		width_ratio = value
		if is_inside_tree():
			_update()

@export_range(0.1, 1.0) var height_ratio := 0.5:
	set(value):
		height_ratio = value
		if is_inside_tree():
			_update()

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	_update()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update()

func _update():
	var screen_size = get_viewport_rect().size
	size = screen_size * Vector2(width_ratio, height_ratio)
	position = -size / 2
