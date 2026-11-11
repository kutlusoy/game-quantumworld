extends Control

var move := Vector2.ZERO
var jump_held := false
var dash_held := false
var _cam_delta := Vector2.ZERO
var _touches := {}
var _stick_center := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _jump_c := Vector2.ZERO
var _dash_c := Vector2.ZERO
const BTN_R := 90.0
const STICK_R := 120.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout()
	get_viewport().size_changed.connect(_layout)

func _layout() -> void:
	var s := get_viewport_rect().size
	_jump_c = Vector2(s.x - 150, s.y - 150)
	_dash_c = Vector2(s.x - 330, s.y - 110)
	_stick_center = Vector2(170, s.y - 170)
	_stick_pos = _stick_center
	queue_redraw()

func consume_camera_delta() -> Vector2:
	var d := _cam_delta
	_cam_delta = Vector2.ZERO
	return d

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.index, event.position)
		else:
			_end(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)

func _begin(i: int, p: Vector2) -> void:
	if p.distance_to(_jump_c) < BTN_R * 1.3:
		_touches[i] = "jump"
		jump_held = true
	elif p.distance_to(_dash_c) < BTN_R * 1.2:
		_touches[i] = "dash"
		dash_held = true
	elif p.x < get_viewport_rect().size.x * 0.45:
		_touches[i] = "stick"
		_stick_center = p
		_stick_pos = p
		move = Vector2.ZERO
	else:
		_touches[i] = "cam"
	queue_redraw()

func _end(i: int) -> void:
	var role: String = _touches.get(i, "")
	_touches.erase(i)
	if role == "jump":
		jump_held = false
	elif role == "dash":
		dash_held = false
	elif role == "stick":
		move = Vector2.ZERO
		_layout()
	queue_redraw()

func _drag(i: int, p: Vector2, rel: Vector2) -> void:
	var role: String = _touches.get(i, "")
	if role == "stick":
		var d := p - _stick_center
		if d.length() > STICK_R:
			d = d.normalized() * STICK_R
		_stick_pos = _stick_center + d
		move = d / STICK_R
		queue_redraw()
	elif role == "cam":
		_cam_delta += rel

func _draw() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	draw_circle(_stick_center, STICK_R, Color(1, 1, 1, 0.12))
	draw_circle(_stick_pos, 48.0, Color(1, 1, 1, 0.35))
	draw_circle(_jump_c, BTN_R, Color(1, 0.6, 0.8, 0.55 if jump_held else 0.35))
	draw_circle(_dash_c, BTN_R * 0.8, Color(0.4, 0.85, 1, 0.55 if dash_held else 0.35))
	var f := ThemeDB.fallback_font
	draw_string(f, _jump_c + Vector2(-36, 10), "JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	draw_string(f, _dash_c + Vector2(-36, 10), "DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
