extends Control

@onready var master_text: Label = %MasterText
@onready var master_slider: HSlider = %MasterSlider
@onready var music_text: Label = %MusicText
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_text: Label = %SfxText
@onready var sfx_slider: HSlider = %SfxSlider

func _ready() -> void:
	_update_sliders()

func _update_sliders() -> void:
	master_text.text = "master volume: " + str(int(Globals.master_volume))
	master_slider.value = Globals.master_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(Globals.master_volume/100))

	music_text.text = "music volume: " + str(int(Globals.music_volume))
	music_slider.value = Globals.music_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Globals.music_volume/100))

	sfx_text.text = "sfx volume: " + str(int(Globals.sfx_volume))
	sfx_slider.value = Globals.sfx_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(Globals.sfx_volume/100))

func _on_master_slider_value_changed(value: float) -> void:
	Globals.master_volume = value
	_update_sliders()

func _on_music_slider_value_changed(value: float) -> void:
	Globals.music_volume = value
	_update_sliders()

func _on_sfx_slider_value_changed(value: float) -> void:
	Globals.sfx_volume = value
	_update_sliders()

func _on_menu_button_pressed() -> void:
	Globals.save_data()

	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")
