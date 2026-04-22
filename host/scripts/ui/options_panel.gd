class_name OptionsPanel extends Control

@onready var close_button: Button = %CloseButton

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	
	close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed():
	self.visible = false
