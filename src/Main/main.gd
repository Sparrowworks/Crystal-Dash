extends Control

@onready var menu_theme: AudioStreamPlayer = $MenuTheme
@onready var button_click: AudioStreamPlayer = $ButtonClick

@onready var pc_music_player: MusicPlayer = $MusicPlayer
@onready var web_music_player: MusicPlayer = $WebMusicPlayer

func _ready() -> void:
	Globals.menu_theme = menu_theme
	Globals.button_click = button_click

	if OS.get_name() == "Web":
		pc_music_player.queue_free()
		web_music_player.process_mode = Node.PROCESS_MODE_INHERIT
		Globals.music_player = web_music_player

		if Globals.audio_preload:
			await Globals.transition.finished_fade_out

			web_music_player.initialize()
			if not web_music_player.has_initialized:
				await web_music_player.finished_loading

		web_music_player.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		web_music_player.queue_free()
		Globals.music_player = pc_music_player

	Composer.root = self
	Composer.load_scene("res://src/Menus/MainMenu/MainMenu.tscn")
