@tool
class_name Gem extends Area2D

signal gem_clicked(gem: Gem)

@export var index: Vector2i = Vector2i.ZERO
@export_range(1, 6) var type: int = 1:
	set(val):
		type = val
		if animated_sprite_2d != null:
			animated_sprite_2d.animation = str(type)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var border: Sprite2D = $Border
@onready var border_anim: AnimationPlayer = $BorderAnim


func _ready() -> void:
	animated_sprite_2d.animation = str(type)


func play_hint() -> void:
	border.show()
	border_anim.play("BorderHint")


func stop_hint() -> void:
	border.hide()
	border_anim.stop()


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			gem_clicked.emit(self)
