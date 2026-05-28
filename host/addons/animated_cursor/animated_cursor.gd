@tool
extends CanvasLayer

@export var sprite_frames: SpriteFrames
@export var animation_name: String = "default"
@export var cursor_offset: Vector2 = Vector2.ZERO
@export var cursor_layer: int = 1000
@export var start_visible: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	layer = cursor_layer
	
	if sprite_frames:
		sprite.sprite_frames = sprite_frames
	
	if Engine.is_editor_hint():
		return
	
	if start_visible:
		show_cursor()
	else:
		hide_cursor()
	
	_play_animation()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	sprite.global_position = get_viewport().get_mouse_position().round() + cursor_offset

func show_cursor() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_play_animation()

func hide_cursor() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func show_system_cursor() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_sprite_frames(frames: SpriteFrames, anim_name: String = "default") -> void:
	sprite_frames = frames
	animation_name = anim_name
	sprite.sprite_frames = frames
	_play_animation()

func set_animation(anim_name: String) -> void:
	animation_name = anim_name
	_play_animation()

func _play_animation() -> void:
	if not sprite.sprite_frames:
		return
	
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
