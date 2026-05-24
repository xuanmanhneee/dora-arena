class_name PlayerInput

var move_direction: int = 0:
	set(value):
		move_direction = clamp(value, -1, 1)

var jump: bool = false
var drop_down: bool = false

var shoot: bool = false
var skill: bool = false
