extends Node

var prompt_texts = {true:"ON",false:"OFF"}

var is_animation_finished = false

func _ready():
	$CanvasLayer/MusicButton.pressed = Global.is_music_on
	$CanvasLayer/SfxButton.pressed = Global.is_sfx_on

	$CanvasLayer/MusicLabel.text = "Music: " + prompt_texts[Global.is_music_on]
	$CanvasLayer/SfxLabel.text = "SFX: " + prompt_texts[Global.is_sfx_on]

	$CanvasLayer/TitleLabel.rect_global_position.y = -500
	$CanvasLayer/CreatorLabel.rect_global_position.y = -500

	$CanvasLayer/MusicLabel.rect_global_position.x = -1000
	$CanvasLayer/SfxLabel.rect_global_position.x = Global.screen_size.x + 1000

	$CanvasLayer/MusicButton.modulate.a = 0
	$CanvasLayer/SfxButton.modulate.a = 0

	$CanvasLayer/QuitButton.rect_global_position.x = -500

	$Tween.interpolate_property($CanvasLayer/TitleLabel,"rect_global_position:y",-500,110,1,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT)
	$Tween.interpolate_property($CanvasLayer/CreatorLabel,"rect_global_position:y",-500,230,1,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT,0.5)

	$Tween.interpolate_property($CanvasLayer/MusicLabel,"rect_global_position:x",-500,500,1,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT,1.5)
	$Tween.interpolate_property($CanvasLayer/SfxLabel,"rect_global_position:x",Global.screen_size.x + 1000,1200,1,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT,1.5)

	$Tween.interpolate_property($CanvasLayer/MusicButton,"modulate:a",0,1,1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,1.5)
	$Tween.interpolate_property($CanvasLayer/SfxButton,"modulate:a",0,1,1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,1.5)

	$Tween.interpolate_property($CanvasLayer/QuitButton,"rect_global_position:x",-500,895,1,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT,1.5)

	$Tween.start()

	yield($Tween,"tween_all_completed")

	is_animation_finished = true

func _input(event):
	if (event is InputEventMouseButton):
		if (event.is_pressed() && event.button_index == 1 && !is_animation_finished):
			$Tween.remove_all()

			$CanvasLayer/TitleLabel.rect_global_position.y = 110
			$CanvasLayer/CreatorLabel.rect_global_position.y = 230

			$CanvasLayer/MusicLabel.rect_global_position.x = 500
			$CanvasLayer/SfxLabel.rect_global_position.x = 1200

			$CanvasLayer/MusicButton.modulate.a = 1
			$CanvasLayer/SfxButton.modulate.a = 1

			$CanvasLayer/QuitButton.rect_global_position.x = 895

			is_animation_finished = true

func _on_QuitButton_pressed():
	if (!is_animation_finished):
		return

	Composer.gotoScene(Composer.scenes["mainmenu"])

func _on_MusicButton_pressed():
	if (!is_animation_finished):
		return

	Global.is_music_on = !Global.is_music_on

	var theme = get_parent().get_node("MenuTheme")
	if Global.is_music_on:
		theme.play()
	else:
		theme.stop()

	$CanvasLayer/MusicLabel.text = "Music: " + prompt_texts[Global.is_music_on]

func _on_SfxButton_pressed():
	if (!is_animation_finished):
		return

	Global.is_sfx_on = !Global.is_sfx_on

	$CanvasLayer/SfxLabel.text = "SFX: " + prompt_texts[Global.is_sfx_on]
