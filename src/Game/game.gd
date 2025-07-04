extends Control

signal game_paused
signal game_over

signal _board_removed
signal _gems_moved

@onready var gem_move: AudioStreamPlayer = $SFX/GemMove
@onready var bad_move: AudioStreamPlayer = $SFX/BadMove
@onready var tick: AudioStreamPlayer = $SFX/Tick
@onready var gameover: AudioStreamPlayer = $SFX/Gameover
@onready var sample_score_popup: ScorePopup = $SampleScorePopup

@onready var sounds: Array[AudioStreamPlayer] = [gem_move, bad_move, tick, gameover]

@onready var music_player: MusicPlayer = $MusicPlayer

@onready var load_panel: Panel = $LoadPanel
@onready var ui_panel: Panel = $UIPanel
@onready var time_panel: Panel = $TimePanel
@onready var game_field: Panel = $Field

@onready var title: Label = %Title
@onready var time_text: Label = %TimeText
@onready var score_text: Label = %ScoreText
@onready var score_anim: AnimationPlayer = %ScoreAnim
@onready var next_highscore: Label = %NextHighscore
@onready var loop_text: Label = %LoopText

@onready var time_bar: ProgressBar = %TimeBar
@onready var time_animation: AnimationPlayer = %TimeAnimation

@onready var time_timer: Timer = $TimeTimer
@onready var difficulty_timer: Timer = $DifficultyTimer
@onready var time_decrease_timer: Timer = $TimeDecreaseTimer
@onready var idle_timer: Timer = $IdleTimer

@onready var seeds: Seeds = $Seeds

const GEM_SCENE: PackedScene = preload("res://src/Game/Gem/Gem.tscn")
const SCORE_POPUP: PackedScene = preload("res://src/Game/ScorePopup/ScorePopup.tscn")

const BOARD_X: int = 10
const BOARD_Y: int = 9

const BOARD_ORIGIN_X: int = 15
const BOARD_ORIGIN_Y: int = 10

const GEM_MARGIN_X: int = 10
const GEM_MARGIN_Y: int = 10

const GEM_SIZE_X: int = 192
const GEM_SIZE_Y: int = 192

const ANIM_TIME: float = 0.15

var game_seed: Array
var game_time: int = 0
var game_score: int = 0

var game_dict: Dictionary[Vector2i, Gem] = {}

var first_gem: Gem
var second_gem: Gem

var available_moves: int = 0
var is_board_locked: bool = true
var hint_move: Array[Gem] = []


func _ready() -> void:
	# Preloads the music and the scenes for the web to prevent lag
	if OS.get_name() == "Web":
		await Globals.transition.finished_fade_out

		music_player.initialize()
		if not music_player.has_initialized:
			await music_player.finished_loading

		sample_score_popup.initialize()
		if not sample_score_popup.has_initialized:
			await sample_score_popup.finished_loading

		for x in range(0, sounds.size()):
			sounds[x].volume_db = linear_to_db(0.0)
			sounds[x].play()
			await get_tree().create_timer(0.01).timeout
			sounds[x].stop()
			sounds[x].volume_db = linear_to_db(1.0)

	load_panel.hide()

	game_seed = seeds.get_random_seed()
	fill_field_with_seed(game_seed)

	set_next_highscore()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		set_process_input(false)
		get_tree().paused = true
		game_paused.emit()


func set_next_highscore() -> void:
	if game_score > Globals.high_score:
		next_highscore.text = "Highscore to beat: " + str(game_score)
	else:
		next_highscore.text = "Highscore to beat: " + str(Globals.high_score)


func add_score(value: int, gem_amount: int) -> void:
	game_score += value
	score_text.text = "Score: " + str(game_score)
	score_anim.play("Increase")

	var score_popup: ScorePopup = SCORE_POPUP.instantiate()
	score_text.add_child(score_popup)
	score_popup.text = "+" + str(value)
	score_popup.play_score_sound(gem_amount)

	set_next_highscore()


func increase_score(gem_amount: int) -> void:
	if gem_amount == 3:
		add_score(100, gem_amount)
		time_bar.value += 1.0
	elif gem_amount == 4:
		add_score(250, gem_amount)
		time_bar.value += 1.0
	elif gem_amount == 5:
		add_score(500, gem_amount)
		time_bar.value += 2.0
	elif gem_amount > 5 and gem_amount < 8:
		add_score(750, gem_amount)
		time_bar.value += 3.0
	elif gem_amount >= 8 and gem_amount <= 12:
		add_score(1000, gem_amount)
		time_bar.value += 4.0
	elif gem_amount > 12:
		# Scales the score added when more than 12 gems are destroyed.
		add_score(1000 + ((gem_amount - 12) * 500), gem_amount)
		time_bar.value += 5.0

	if time_bar.value > 15.0:
		time_animation.play("RESET")


func get_gem_at_idx(idx: Vector2i) -> Gem:
	return game_dict[idx]


func find_first_gem_in_row(column: int, start_from: int) -> Vector2i:
	# Finds the first gem in a row that isn't an empty slot
	for row in range(start_from, -1, -1):
		if game_dict[Vector2i(column, row)] != null:
			return Vector2i(column, row)

	return Vector2i(-1, -1)


func get_gem_neighbors(gem: Gem) -> Dictionary:
	# Grabs the gems around the gem. Returns null if the gem doesn't have a neighbor in a direction
	var gem_idx: Vector2i = gem.index
	var gems: Dictionary = {"right": null, "left": null, "up": null, "down": null}

	if gem_idx.x < BOARD_X - 1:
		gems["right"] = get_gem_at_idx(Vector2i(gem_idx.x + 1, gem_idx.y))

	if gem_idx.x > 0:
		gems["left"] = get_gem_at_idx(Vector2i(gem_idx.x - 1, gem_idx.y))

	if gem_idx.y < BOARD_Y - 1:
		gems["down"] = get_gem_at_idx(Vector2i(gem_idx.x, gem_idx.y + 1))

	if gem_idx.y > 0:
		gems["up"] = get_gem_at_idx(Vector2i(gem_idx.x, gem_idx.y - 1))

	return gems


func check_if_gems_are_neighbors(gem1: Gem, gem2: Gem) -> bool:
	if gem1 == gem2:
		return false

	return get_gem_neighbors(gem1).values().has(gem2)


func check_for_matches(check_after_cleared: bool = false) -> void:
	# Checks for matches (gems that are aligned in lines of 3 or more)
	var lined: Array[Gem] = find_matches()

	if lined.size() == 0:
		if first_gem != null and second_gem != null:
			bad_move.play()
			edit_board(second_gem, first_gem)
			move_gems(second_gem, first_gem)
			await _gems_moved

		# Checks if any available moves exist, if not we remove the board and replace it with a new one
		if check_after_cleared:
			var are_moves_available: bool = check_for_available_moves()
			if not are_moves_available:
				await get_tree().create_timer(1.0).timeout

				title.text = "No moves available!"
				await get_tree().create_timer(0.5).timeout

				remove_board(1.0)
				await _board_removed

				fill_field_with_seed(seeds.get_random_seed(), true)
			else:
				is_board_locked = false
				time_timer.paused = false
				idle_timer.start()
		else:
			is_board_locked = false
			time_timer.paused = false
			idle_timer.start()
	else:
		remove_gems(lined)


func find_matches() -> Array[Gem]:
	var gems_to_break: Dictionary[Gem, bool] = {}
	var found_line: Array[Gem]

	# Searches horizontal lines for matches
	for index: Vector2i in game_dict.keys():
		var gem: Gem = game_dict[index]
		if gem == null:  # If null, then we reached the end of the line
			continue

		if not found_line.has(gem):
			found_line.append(gem)

		var next_gem: Gem = game_dict.get(Vector2i(index.x + 1, index.y))

		if next_gem == null:
			if found_line.size() >= 3:  # We only accept matches of 3 or more
				for found_gem in found_line:
					gems_to_break[found_gem] = true

			found_line.clear()
			continue

		if gem.type == next_gem.type:
			found_line.append(next_gem)
		else:
			if found_line.size() >= 3:  # We only accept matches of 3 or more
				for found_gem in found_line:
					gems_to_break[found_gem] = true

			found_line.clear()

	found_line.clear()

	# Searches vertical lines for matches
	for x in range(0, BOARD_X):
		for y in range(0, BOARD_Y):
			var index: Vector2i = Vector2i(x, y)
			var gem: Gem = game_dict[index]

			if gem == null:  # If null, then we reached the end of the line
				continue

			if not found_line.has(gem):
				found_line.append(gem)

			var next_gem: Gem = game_dict.get(Vector2i(index.x, index.y + 1))

			if next_gem == null:
				if found_line.size() >= 3:  # We only accept matches of 3 or more
					for found_gem in found_line:
						gems_to_break[found_gem] = true

				found_line.clear()
				continue

			if gem.type == next_gem.type:
				found_line.append(next_gem)
			else:
				if found_line.size() >= 3:  # We only accept matches of 3 or more
					for found_gem in found_line:
						gems_to_break[found_gem] = true

				found_line.clear()

	return gems_to_break.keys()


func get_two_vertical_columns(first_index: Vector2i) -> Array[Array]:
	var gems: Array[Array] = [[], []]

	gems[0].append(game_dict[first_index])
	gems[0].append(game_dict[Vector2i(first_index.x, first_index.y + 1)])
	gems[0].append(game_dict[Vector2i(first_index.x, first_index.y + 2)])
	gems[0].append(game_dict[Vector2i(first_index.x, first_index.y + 3)])

	gems[1].append(game_dict[Vector2i(first_index.x + 1, first_index.y)])
	gems[1].append(game_dict[Vector2i(first_index.x + 1, first_index.y + 1)])
	gems[1].append(game_dict[Vector2i(first_index.x + 1, first_index.y + 2)])
	gems[1].append(game_dict[Vector2i(first_index.x + 1, first_index.y + 3)])

	return gems


func get_two_horizontal_rows(first_index: Vector2i) -> Array[Array]:
	var gems: Array[Array] = [[], []]

	gems[0].append(game_dict[first_index])
	gems[0].append(game_dict[Vector2i(first_index.x + 1, first_index.y)])
	gems[0].append(game_dict[Vector2i(first_index.x + 2, first_index.y)])
	gems[0].append(game_dict[Vector2i(first_index.x + 3, first_index.y)])

	gems[1].append(game_dict[Vector2i(first_index.x, first_index.y + 1)])
	gems[1].append(game_dict[Vector2i(first_index.x + 1, first_index.y + 1)])
	gems[1].append(game_dict[Vector2i(first_index.x + 2, first_index.y + 1)])
	gems[1].append(game_dict[Vector2i(first_index.x + 3, first_index.y + 1)])

	return gems


func check_rows(gems: Array) -> bool:
	# Searches the rows for any potential moves and returns the first one that will be shown as a hint
	var row1: Array = gems[0]
	var row2: Array = gems[1]

	var temp_array: Array = []
	# Checks for moves in one column/row (i.e AABA or ABAA)
	if row1[0].type == row1[1].type and row1[1].type == row1[3].type:
		hint_move = [row1[2], row1[3]]
		return true
	elif row1[0].type == row1[2].type and row1[2].type == row1[3].type:
		hint_move = [row1[0], row1[1]]
		return true

	if row2[0].type == row2[1].type and row2[1].type == row2[3].type:
		hint_move = [row2[2], row2[3]]
		return true
	elif row2[0].type == row2[2].type and row2[2].type == row2[3].type:
		hint_move = [row2[0], row2[1]]
		return true

	# Checks if a match between two columns/rows exists
	temp_array = row1.duplicate()
	for i in range(0, row1.size()):
		temp_array[i] = row2[i]

		if (
			temp_array[0].type == temp_array[1].type and temp_array[1].type == temp_array[2].type
			or temp_array[1].type == temp_array[2].type and temp_array[2].type == temp_array[3].type
		):
			hint_move = [row1[i], row2[i]]
			return true

		temp_array[i] = row1[i]

	temp_array = row2.duplicate()
	for i in range(0, row2.size()):
		temp_array[i] = row1[i]

		if (
			temp_array[0].type == temp_array[1].type and temp_array[1].type == temp_array[2].type
			or temp_array[1].type == temp_array[2].type and temp_array[2].type == temp_array[3].type
		):
			hint_move = [row1[i], row2[i]]
			return true

		temp_array[i] = row2[i]

	return false


func check_for_available_moves() -> bool:
	#check vertical
	for x in range(0, BOARD_X - 1):
		for y in range(0, BOARD_Y - 4):
			var first_index: Vector2i = Vector2i(x, y)
			var two_rows: Array = get_two_vertical_columns(first_index)
			var is_match: bool = check_rows(two_rows)
			if is_match:
				return true

	#check horizontal
	for x in range(0, BOARD_X - 4):
		for y in range(0, BOARD_Y - 1):
			var first_index: Vector2i = Vector2i(x, y)
			var two_rows: Array = get_two_horizontal_rows(first_index)
			var is_match: bool = check_rows(two_rows)
			if is_match:
				return true

	return false


func fill_field_with_seed(seed_id: Array, is_reset: bool = false) -> void:
	var gem_idx: Vector2i = Vector2i(0, 0)
	var gem_pos: Vector2i = Vector2i(BOARD_ORIGIN_X, BOARD_ORIGIN_Y)

	var move_tween: Tween = get_tree().create_tween()
	move_tween.set_parallel(true)

	# Creates the gems and assigns them a [x,y] key for easier identification later
	for y in range(0, BOARD_Y):
		gem_pos.x = BOARD_ORIGIN_X
		gem_idx.x = 0
		for x in range(0, BOARD_X):
			var gem: Gem
			if game_dict.get(gem_idx, null) == null:
				gem = GEM_SCENE.instantiate()
				gem.gem_clicked.connect(_on_gem_clicked)
				game_field.add_child(gem, true)
			else:
				gem = game_dict[gem_idx]

			gem.modulate = Color.TRANSPARENT
			gem.position = gem_pos
			gem.type = seed_id[y][x]
			gem.index = gem_idx
			game_dict[gem_idx] = gem

			move_tween.tween_property(gem, "modulate:a", 1, 1.0)

			gem_pos.x += GEM_SIZE_X + GEM_MARGIN_X
			gem_idx.x += 1

		gem_pos.y += GEM_SIZE_Y + GEM_MARGIN_Y
		gem_idx.y += 1

	await move_tween.finished

	# Searches for a hint to show later
	if not is_reset:
		var are_moves_available: bool = check_for_available_moves()
		if not are_moves_available:
			await get_tree().create_timer(1.0).timeout

			title.text = "No moves available!"
			await get_tree().create_timer(0.5).timeout

			remove_board(1.0)
			await _board_removed

			fill_field_with_seed(seeds.get_random_seed(), false)
		else:
			time_timer.start()
			time_decrease_timer.start()
			difficulty_timer.start()

			music_player.enable()
	else:
		time_timer.paused = false

	title.text = "Crystal Dash"
	idle_timer.start()
	is_board_locked = false


func edit_board(gem1: Gem, gem2: Gem) -> void:
	var gem1_idx: Vector2i = gem1.index
	var gem2_idx: Vector2i = gem2.index

	gem1.index = gem2_idx
	gem2.index = gem1_idx

	game_dict[gem2_idx] = gem1
	game_dict[gem1_idx] = gem2


func move_gems(gem1: Gem, gem2: Gem) -> void:
	var gem1_pos: Vector2 = gem1.position

	var move_tween: Tween = get_tree().create_tween()
	move_tween.tween_property(gem1, "position", gem2.position, ANIM_TIME)
	move_tween.set_parallel()
	move_tween.tween_property(gem2, "position", gem1_pos, ANIM_TIME)

	await move_tween.finished
	_gems_moved.emit()


func move_gem_to_slot(gem: Gem, index: Vector2i) -> void:
	# Moves a newly created gem to an empty slot
	var new_pos: Vector2 = Vector2(
		BOARD_ORIGIN_X + (index.x * (GEM_SIZE_X + GEM_MARGIN_X)),
		GEM_MARGIN_Y + (index.y * (GEM_SIZE_Y + GEM_MARGIN_Y))
	)

	var move_tween: Tween = get_tree().create_tween()
	move_tween.tween_property(gem, "position", new_pos, ANIM_TIME)


func move_gems_to_bottom() -> void:
	for x in range(0, BOARD_X):
		for y in range(BOARD_Y - 1, -1, -1):
			var index: Vector2i = Vector2i(x, y)
			var place: Gem = game_dict[index]

			if place == null:
				var taken_gem_place: Vector2i = find_first_gem_in_row(x, y)
				if taken_gem_place != Vector2i(-1, -1):
					game_dict[index] = game_dict[taken_gem_place]
					game_dict[index].index = index
					game_dict[taken_gem_place] = null
					move_gem_to_slot(game_dict[index], index)
				else:
					continue

	fill_empty_slots()


func fill_empty_slots() -> void:
	# Creates gems for each empty slot that remains after the gems have been destroyed
	var gems_to_move: Array[Gem] = []

	for x in range(0, BOARD_X):
		for y in range(BOARD_Y - 1, -1, -1):
			var index: Vector2i = Vector2i(x, y)

			if game_dict[index] != null:
				continue

			var gem: Gem = GEM_SCENE.instantiate()
			gem.gem_clicked.connect(_on_gem_clicked)
			game_field.add_child(gem, true)

			gem.position = Vector2(BOARD_ORIGIN_X + (index.x * (GEM_SIZE_X + GEM_MARGIN_X)), -400)
			gem.type = randi_range(1, 6)
			gem.index = index
			game_dict[index] = gem
			gems_to_move.append(gem)

	var move_tween: Tween = get_tree().create_tween()
	for gem in gems_to_move:
		var desired_y: int = BOARD_ORIGIN_Y + (gem.index.y * (GEM_SIZE_Y + GEM_MARGIN_Y))
		move_tween.tween_property(gem, "position:y", desired_y, ANIM_TIME)

	await move_tween.finished

	check_for_matches(true)


func remove_gems(gems: Array[Gem]) -> void:
	increase_score(gems.size())

	for gem in gems:
		var index: Vector2i = gem.index
		gem.queue_free()
		game_dict[index] = null

	move_gems_to_bottom()


func remove_board(time: float) -> void:
	# Destroy the whole board when it's game over or there are no moves available
	var move_tween: Tween = get_tree().create_tween()
	move_tween.set_parallel(true)

	for x in range(0, BOARD_X):
		for y in range(0, BOARD_Y):
			var index: Vector2i = Vector2i(x, y)
			move_tween.tween_property(game_dict[index], "modulate:a", 0, time)

	await move_tween.finished

	_board_removed.emit()


func _on_gem_clicked(gem: Gem) -> void:
	if is_board_locked:
		return

	idle_timer.stop()

	if first_gem == null:
		# Hides the hint when we click on a gem
		if hint_move.size() > 0:
			if is_instance_valid(hint_move[0]):
				hint_move[0].stop_hint()
			if is_instance_valid(hint_move[1]):
				hint_move[1].stop_hint()

		first_gem = gem
		gem.border.show()
	elif second_gem == null:
		first_gem.border.hide()
		# If the two pressed gems are neighbors then we search for matches
		if check_if_gems_are_neighbors(first_gem, gem):
			second_gem = gem

			gem_move.play()

			is_board_locked = true
			time_timer.paused = true

			edit_board(first_gem, second_gem)
			move_gems(first_gem, second_gem)

			await _gems_moved

			check_for_matches()
		else:
			bad_move.play()
			idle_timer.start()

		first_gem = null
		second_gem = null


func _on_reset_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Game/Game.tscn")


func _on_menu_button_pressed() -> void:
	Globals.go_to_with_fade("res://src/Menus/MainMenu/MainMenu.tscn")


func _on_time_timer_timeout() -> void:
	game_time += 1
	time_text.text = "Time: " + str(game_time)


func _on_difficulty_timer_timeout() -> void:
	time_decrease_timer.stop()
	time_decrease_timer.wait_time = clampf(time_decrease_timer.wait_time - 0.1, 0.5, 2.0)
	time_decrease_timer.start()


func _on_time_decrease_timer_timeout() -> void:
	time_bar.value -= 1.0

	if time_bar.value <= 15.0 and time_bar.value > 0:
		time_animation.play("Blink")
		tick.play()

	if time_bar.value == 0.0:
		game_over.emit()


func _on_idle_timer_timeout() -> void:
	# Shows a hint after a few seconds have gone by without any progress
	if hint_move.size() > 0:
		if is_instance_valid(hint_move[0]):
			hint_move[0].play_hint()
		if is_instance_valid(hint_move[1]):
			hint_move[1].play_hint()


func _on_music_player_loop_changed(is_on: bool) -> void:
	if is_on:
		loop_text.text = "Music Loop: ON"
	else:
		loop_text.text = "Music Loop: OFF"


func _on_game_over() -> void:
	Globals.end_time = game_time
	Globals.end_score = game_score

	music_player.disable()
	gameover.play()

	time_animation.play("RESET")
	tick.stop()
	time_timer.stop()
	time_decrease_timer.stop()
	difficulty_timer.stop()
	mouse_filter = Control.MOUSE_FILTER_STOP

	remove_board(2.0)

	await _board_removed

	Globals.go_to_with_fade("res://src/Menus/GameEnd/GameEnd.tscn")


func _on_pause_ui_game_unpaused() -> void:
	get_tree().paused = false
	Globals.button_click.play()

	await get_tree().create_timer(0.5).timeout
	set_process_input(true)
