extends Node2D

@onready var sprite := $AnimatedSprite2D
var enabled := true

func _ready():
	show_cursor()
	sprite.play("default")

func _process(_delta):
	if not enabled:
		return
	
	global_position = get_viewport().get_mouse_position().round()

func show_cursor():
	enabled = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func hide_cursor():
	enabled = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
