extends Control

@onready var menu_theme: AudioStreamPlayer = $MenuTheme
@onready var button_click: AudioStreamPlayer = $ButtonClick


func _ready() -> void:
	Globals.menu_theme = menu_theme
	Globals.button_click = button_click

	Composer.root = self
	Composer.load_scene("res://src/Menus/MainMenu/MainMenu.tscn")
