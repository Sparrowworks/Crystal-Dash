extends Control

@onready var version_text: Label = $MarginContainer/VersionText
@onready var highscore_text: Label = $HighscoreText

func _ready() -> void:
	if not Globals.menu_theme.playing:
		Globals.menu_theme.play()

	highscore_text.text = "Your highscore: " + str(Globals.high_score)

	if OS.get_name() == "Web":
		$ButtonContainer/QuitButton.hide()

	version_text.text = "v" + ProjectSettings.get_setting("application/config/version")

func _on_play_button_pressed() -> void:
	Globals.menu_theme.stop()
	Globals.go_to_with_fade("res://src/Game/Game.tscn")

func _on_settings_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/Settings/Settings.tscn")

func _on_help_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/Help/Help.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
