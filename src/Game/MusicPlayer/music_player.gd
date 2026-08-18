class_name MusicPlayer extends Node

signal loop_changed(is_on: bool)
signal finished_loading

@export var game_tracks: Array[AudioStreamPlayer] = []

var track_id: int = -1
var is_looped: bool = false

var has_initialized: bool = false


func _ready() -> void:
	set_process(false)


func initialize() -> void:
	# Prevents lag by preloading sounds
	for x in range(0, game_tracks.size()):
		game_tracks[x].volume_db = linear_to_db(0.0)
		game_tracks[x].play()
		game_tracks[x].stop()
		game_tracks[x].volume_db = linear_to_db(1.0)

	has_initialized = true
	finished_loading.emit()


func enable() -> void:
	# Plays a random track on activation
	set_process(true)
	track_id = randi_range(0, game_tracks.size()-1)
	game_tracks[track_id].play()


func disable() -> void:
	set_process(false)
	game_tracks[track_id].stop()


func play_next_track() -> void:
	game_tracks[track_id].stop()

	track_id += 1
	if track_id > game_tracks.size()-1:
		track_id = 0

	game_tracks[track_id].play()


func play_prev_track() -> void:
	game_tracks[track_id].stop()

	track_id -= 1
	if track_id < 0:
		track_id = game_tracks.size()-1

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
