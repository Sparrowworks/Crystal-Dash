class_name MusicPlayer extends Node

signal loop_changed(is_on: bool)

@onready var game_tracks: Array[AudioStreamPlayer] = [
	$Gametrack1,
	$Gametrack2,
	$Gametrack3,
	$Gametrack4,
	$Gametrack5,
	$Gametrack6,
	$Gametrack7,
	$Gametrack8
]

var track_titles: Array[String] = [

]

var track_id: int = -1
var is_looped: bool = false

func _ready() -> void:
	set_process(false)

func enable() -> void:
	set_process(true)
	track_id = randi_range(0, 7)
	game_tracks[track_id].play()

func disable() -> void:
	set_process(false)
	game_tracks[track_id].stop()

func play_next_track() -> void:
	game_tracks[track_id].stop()

	track_id += 1
	if track_id > 7:
		track_id = 0

	game_tracks[track_id].play()

func play_prev_track() -> void:
	game_tracks[track_id].stop()

	track_id -= 1
	if track_id < 0:
		track_id = 7

	game_tracks[track_id].play()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mute"):
		game_tracks[track_id].stream_paused = !game_tracks[track_id].stream_paused

	if Input.is_action_just_pressed("loop"):
		is_looped = !is_looped
		loop_changed.emit(is_looped)

	if Input.is_action_just_pressed("next"):
		play_next_track()
	elif Input.is_action_just_pressed("back"):
		play_prev_track()

func _on_track_finished() -> void:
	if is_looped:
		game_tracks[track_id].play()
	else:
		play_next_track()
