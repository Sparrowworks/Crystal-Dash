extends Control

@onready var time_text: Label = %TimeText
@onready var score_text: Label = %ScoreText
@onready var highscore_text: Label = %HighscoreText

func _ready() -> void:
	if not Globals.menu_theme.playing:
		Globals.menu_theme.play()

	time_text.text = "Total time: " + str(Globals.end_time)
	score_text.text = "Total score: " + str(Globals.end_score)

	var is_new_place: bool = check_highscore(Globals.end_score)
	if is_new_place:
		Globals.high_score = Globals.end_score
		Globals.save_data()
		highscore_text.text = "New Highscore!"
	else:
		highscore_text.text = "No highscore achieved."

func check_highscore(new_score: int) -> bool:
	return new_score > Globals.high_score

func _on_menu_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")
