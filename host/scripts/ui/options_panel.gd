extends Control

@onready var settings_page: Control = %SettingsPage
@onready var control_page: Control = %ControlPage
@onready var credit_page: Control = %CreditPage
@onready var about_page: Control = %AboutPage

@onready var settings_button: Button = %SettingsButton
@onready var control_button: Button = %ControlButton
@onready var credit_button: Button = %CreditButton
@onready var about_button: Button = %AboutButton

func _ready() -> void:
	settings_button.pressed.connect(func(): show_page(settings_page))
	control_button.pressed.connect(func(): show_page(control_page))
	credit_button.pressed.connect(func(): show_page(credit_page))
	about_button.pressed.connect(func(): show_page(about_page))
	
	show_page(settings_page)

func show_page(page: Control) -> void:
	settings_page.visible = false
	about_page.visible = false
	credit_page.visible = false
	control_page.visible = false

	page.visible = true
