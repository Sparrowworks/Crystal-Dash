class_name FadeScreen extends CanvasLayer

signal finished_fade_in()
signal finished_fade_out()

@onready var fade_rect: ColorRect = $FadeRect

var fade_tween: Tween

func _ready() -> void:
	fade_in()
	Composer.finished_loading.connect(_on_finished_loading)

func fade_in() -> void:
	fade_rect.color = Color(0,0,0,0)

	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(fade_rect,"color:a",1.0,0.75)
	fade_tween.tween_callback(
		func() -> void:
			finished_fade_in.emit()
	)

func fade_out() -> void:
	fade_rect.color = Color(0,0,0,1)

	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(fade_rect,"color:a",0.0,0.75)
	fade_tween.tween_callback(
		func() -> void:
			finished_fade_out.emit()
			Composer.clear_load_screen()
	)

func _on_finished_loading(_scene: Node) -> void:
	fade_out()
