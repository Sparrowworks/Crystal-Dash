extends Control

@onready var help_title: Label = $TextContainer/HelpTitle
@onready var help: Label = $TextContainer/Help
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_switching: bool = false
var page: int = 0

var headings: Array[String] = [
	"How to play:",
	"Credits:",
]
var content: Array[String] = [
	"click on crystals and match them in lines of at least 3 of the same color
	to break them. you get more points if your line is bigger and have multiple lines at once!
	the game ends when the timer runs out. break crystals to add more time!
	if you make 5 wrong moves in a row, the board will automatically reset to give you more moves.

	press m to either mute or play music in game
	press l to loop current track
	use arrow keys to switch current track",

	"programming: sp4r0w
	testing: vargadot

	art made by kenney
	ui theme made by azagaya
	music made by Benjamin Burnes"
]

func _ready() -> void:
	help_title.text = headings[page]
	help.text = content[page]

func _on_switch_button_pressed() -> void:
	if is_switching:
		return

	is_switching = true
	page = (page + 1) % content.size()

	animation_player.play("FadeIn")
	await animation_player.animation_finished

	help_title.text = headings[page]
	help.text = content[page]

	animation_player.play("FadeOut")
	await animation_player.animation_finished

	is_switching = false

func _on_menu_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")
