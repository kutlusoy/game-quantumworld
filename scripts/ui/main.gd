extends Control

const Level = preload("res://scripts/core/level.gd")
const Session = preload("res://scripts/core/session.gd")
const BoardView = preload("res://scripts/ui/board_view.gd")
const SaveStore = preload("res://scripts/core/save_store.gd")

const VIEW_W := 720.0
const BOARD_MAX := 660.0

var levels: Array = []
var progress: Dictionary = {}
var current := 0
var session
var board_view
var screen: Control
var moves_label: Label
var score_label: Label

func _ready() -> void:
	levels = Level.load_all()
	progress = SaveStore.load_progress()
	_build_background()
	_show_levels()

func _build_background() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("2b1055"), Color("7b4fd1"), Color("ff8fb8")])
	grad.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

func _new_screen() -> void:
	if screen != null:
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _button(text: String, size: int = 36) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	return b

func _stars_of(level) -> int:
	return int(progress["stars"].get(str(level.id), 0))

func _is_unlocked(i: int) -> bool:
	return i == 0 or _stars_of(levels[i - 1]) >= 1

func _show_levels() -> void:
	_new_screen()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 30
	box.offset_right = -30
	box.offset_top = 60
	box.offset_bottom = -30
	box.add_theme_constant_override("separation", 24)
	screen.add_child(box)
	box.add_child(_label("Quantum World", 64))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for i in levels.size():
		var b := _button("%d\n%d/3" % [levels[i].id, _stars_of(levels[i])], 32)
		b.custom_minimum_size = Vector2(150, 150)
		b.disabled = not _is_unlocked(i)
		b.pressed.connect(_start_level.bind(i))
		grid.add_child(b)

func _start_level(i: int) -> void:
	current = i
	var level = levels[i]
	session = Session.new(level)
	_new_screen()
	var cell := floorf(BOARD_MAX / maxf(level.width, level.height))
	board_view = BoardView.new()
	board_view.setup(session, cell)
	var size: Vector2 = board_view.board_size()
	board_view.position = Vector2((VIEW_W - size.x) / 2.0, 340)
	screen.add_child(board_view)
	board_view.move_played.connect(_on_move_played)
	var title := _label("Level %d" % level.id, 48)
	title.position = Vector2(0, 50)
	title.size = Vector2(VIEW_W, 70)
	screen.add_child(title)
	var goal := _label("Goal: %d" % level.target, 36)
	goal.position = Vector2(0, 130)
	goal.size = Vector2(VIEW_W, 50)
	screen.add_child(goal)
	moves_label = _label("", 44)
	moves_label.position = Vector2(0, 200)
	moves_label.size = Vector2(VIEW_W / 2.0, 60)
	screen.add_child(moves_label)
	score_label = _label("", 44)
	score_label.position = Vector2(VIEW_W / 2.0, 200)
	score_label.size = Vector2(VIEW_W / 2.0, 60)
	screen.add_child(score_label)
	var menu := _button("Levels")
	menu.position = Vector2(30, 1180)
	menu.size = Vector2(200, 70)
	menu.pressed.connect(_show_levels)
	screen.add_child(menu)
	_update_hud()

func _update_hud() -> void:
	moves_label.text = "Moves: %d" % session.moves_left
	score_label.text = "Score: %d" % session.score

func _on_move_played(_result: Dictionary) -> void:
	_update_hud()
	if session.is_over():
		_show_result()

func _show_result() -> void:
	var stars: int = session.stars()
	var level = levels[current]
	var key := str(level.id)
	if stars > int(progress["stars"].get(key, 0)):
		progress["stars"][key] = stars
		SaveStore.save_progress(progress)
	var panel := PanelContainer.new()
	panel.position = Vector2(60, 420)
	panel.size = Vector2(600, 440)
	screen.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)
	box.add_child(_label("Level complete!" if stars > 0 else "Out of moves", 48))
	box.add_child(_label("Score %d   Stars %d/3" % [session.score, stars], 40))
	var retry := _button("Retry")
	retry.pressed.connect(_start_level.bind(current))
	box.add_child(retry)
	if stars > 0 and current + 1 < levels.size():
		var next := _button("Next level")
		next.pressed.connect(_start_level.bind(current + 1))
		box.add_child(next)
	var back := _button("Levels")
	back.pressed.connect(_show_levels)
	box.add_child(back)
