class_name ScorePopup extends Label

@onready var gem_break: AudioStreamPlayer = $GemBreak
@onready var _4_line: AudioStreamPlayer = $"4Line"
@onready var _5_line: AudioStreamPlayer = $"5Line"
@onready var _6_line: AudioStreamPlayer = $"6Line"
@onready var _7_line: AudioStreamPlayer = $"7Line"
@onready var higher_line: AudioStreamPlayer = $HigherLine

func _ready() -> void:
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
