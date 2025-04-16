class_name ScorePopup extends Label

signal finished_loading()

@onready var gem_break: AudioStreamPlayer = $GemBreak
@onready var _4_line: AudioStreamPlayer = $"4Line"
@onready var _5_line: AudioStreamPlayer = $"5Line"
@onready var _6_line: AudioStreamPlayer = $"6Line"
@onready var _7_line: AudioStreamPlayer = $"7Line"
@onready var higher_line: AudioStreamPlayer = $HigherLine

@onready var sounds: Array[AudioStreamPlayer] = [
	gem_break,
	_4_line,
	_5_line,
	_6_line,
	_7_line,
	higher_line,
]

var has_initialized: bool = false

func _ready() -> void:
	if name == "SampleScorePopup":
		return

	position = Vector2(185, 0)

	var move_tween: Tween = get_tree().create_tween()
	move_tween.tween_property(self, "position:y", -1000, 0.75)
	move_tween.tween_callback(
		func() -> void:
			queue_free()
	)

func play_score_sound(gem_amount: int) -> void:
	if gem_amount == 3:
		gem_break.play()
	elif gem_amount == 4:
		_4_line.play()
	elif gem_amount == 5:
		_5_line.play()
	elif gem_amount > 5 and gem_amount < 8:
		_6_line.play()
	elif gem_amount >= 8 and gem_amount <= 12:
		_7_line.play()
	elif gem_amount > 12:
		higher_line.play()

func initialize() -> void:
	for x in range(0, sounds.size()):
		sounds[x].volume_db = linear_to_db(0.0)
		sounds[x].play()
		await get_tree().create_timer(0.01).timeout
		sounds[x].stop()
		sounds[x].volume_db = linear_to_db(1.0)

	has_initialized = true
	finished_loading.emit()
