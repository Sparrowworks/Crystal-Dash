extends Node

var menu_theme: AudioStreamPlayer
var button_click: AudioStreamPlayer

var master_volume: float = 100.0
var music_volume: float = 100.0
var sfx_volume: float = 100.0

var high_score: int = 0

var end_time: int
var end_score: int

var transition: FadeScreen

func _ready() -> void:
	load_data()
	save_data()

func load_data() -> void:
	high_score = SaveSystem.get_var("high_score", high_score)
	master_volume = SaveSystem.get_var("master_volume", 100.0)
	music_volume = SaveSystem.get_var("music_volume", 100.0)
	sfx_volume = SaveSystem.get_var("sfx_volume", 100.0)

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume/100))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume/100))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume/100))

func save_data() -> void:
	SaveSystem.set_var("high_score", high_score)
	SaveSystem.set_var("master_volume", master_volume)
	SaveSystem.set_var("music_volume", music_volume)
	SaveSystem.set_var("sfx_volume", sfx_volume)

	SaveSystem.save()

func go_to_with_fade(scene: String) -> void:
	transition = Composer.setup_load_screen("res://src/Composer/LoadingScreens/Fade/FadeScreen.tscn") as FadeScreen

	if transition:
		button_click.play()
		await transition.finished_fade_in
		Composer.load_scene(scene)
