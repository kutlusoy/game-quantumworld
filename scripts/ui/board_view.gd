extends Node2D

const PieceView = preload("res://scripts/ui/piece_view.gd")

signal move_played(result: Dictionary)

const PALETTE := [
	Color("ff6fa5"), Color("ffa94d"), Color("ffe066"),
	Color("69db7c"), Color("4dd4ff"), Color("b197fc"),
]

var session
var cell := 80.0
var views := {}
var busy := false
var _press_cell := Vector2i(-1, -1)
var _press_pos := Vector2.ZERO

func setup(s, cell_size: float) -> void:
	session = s
	cell = cell_size
	rebuild()

func board_size() -> Vector2:
	return Vector2(session.board.width, session.board.height) * cell

func rebuild() -> void:
	for v in views.values():
		v.queue_free()
	views.clear()
	var b = session.board
	for y in b.height:
		for x in b.width:
			var i: int = b.idx(x, y)
			views[i] = _make_view(b.cells[i], Vector2i(x, y))

func _make_view(piece: int, c: Vector2i) -> Node2D:
	var v = PieceView.new()
	v.setup(piece, cell, PALETTE)
	v.position = _center(c)
	add_child(v)
	return v

func _center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * cell

func _cell_pos(i: int) -> Vector2i:
	var w: int = session.board.width
	return Vector2i(i % w, i / w)

func _draw() -> void:
	if session == null:
		return
	var b = session.board
	draw_rect(Rect2(Vector2.ZERO, board_size()), Color(0, 0, 0, 0.25))
	for y in b.height:
		for x in b.width:
			if (x + y) % 2 == 0:
				draw_rect(Rect2(Vector2(x, y) * cell, Vector2(cell, cell)), Color(1, 1, 1, 0.05))

func _unhandled_input(event: InputEvent) -> void:
	if busy or session == null or session.is_over():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var p := get_local_mouse_position()
			var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
			if session.board.in_bounds(c.x, c.y):
				_press_cell = c
				_press_pos = event.position
		else:
			_press_cell = Vector2i(-1, -1)
	elif event is InputEventMouseMotion and _press_cell.x >= 0:
		var d: Vector2 = event.position - _press_pos
		if d.length() > cell * 0.35:
			var dir := Vector2i.ZERO
			if absf(d.x) > absf(d.y):
				dir = Vector2i(1 if d.x > 0 else -1, 0)
			else:
				dir = Vector2i(0, 1 if d.y > 0 else -1)
			var from := _press_cell
			_press_cell = Vector2i(-1, -1)
			_attempt(from, from + dir)

func _attempt(a: Vector2i, b: Vector2i) -> void:
	if not session.board.in_bounds(b.x, b.y):
		return
	busy = true
	if not session.board.is_valid_swap(a, b):
		await _bounce(a, b)
		busy = false
		return
	var result: Dictionary = session.play(a, b)
	await _animate(a, b, result)
	busy = false
	move_played.emit(result)

func _bounce(a: Vector2i, b: Vector2i) -> void:
	var va = views.get(session.board.idx(a.x, a.y))
	var vb = views.get(session.board.idx(b.x, b.y))
	if va == null or vb == null:
		return
	var t := create_tween().set_parallel(true)
	t.tween_property(va, "position", _center(b), 0.08)
	t.tween_property(vb, "position", _center(a), 0.08)
	await t.finished
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(va, "position", _center(a), 0.08)
	t2.tween_property(vb, "position", _center(b), 0.08)
	await t2.finished

func _animate(a: Vector2i, b: Vector2i, result: Dictionary) -> void:
	var ia: int = session.board.idx(a.x, a.y)
	var ib: int = session.board.idx(b.x, b.y)
	var va = views[ia]
	var vb = views[ib]
	views[ia] = vb
	views[ib] = va
	var t := create_tween().set_parallel(true)
	t.tween_property(va, "position", _center(b), 0.12)
	t.tween_property(vb, "position", _center(a), 0.12)
	await t.finished
	for step in result["steps"]:
		if step["type"] == "reshuffle":
			rebuild()
			continue
		await _animate_clear(step)

func _animate_clear(step: Dictionary) -> void:
	var gone := []
	var t := create_tween().set_parallel(true)
	for c in step["cleared"]:
		var v = views.get(c["idx"])
		if v == null:
			continue
		views.erase(c["idx"])
		gone.append(v)
		t.tween_property(v, "scale", Vector2.ZERO, 0.16)
	if not gone.is_empty():
		await t.finished
	for v in gone:
		v.queue_free()
	for cr in step["created"]:
		var old = views.get(cr["idx"])
		if old != null:
			old.queue_free()
		var nv := _make_view(cr["piece"], _cell_pos(cr["idx"]))
		nv.scale = Vector2.ZERO
		views[cr["idx"]] = nv
		create_tween().tween_property(nv, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	var moved := {}
	var t2 := create_tween().set_parallel(true)
	var any := false
	for f in step["falls"]:
		var v = views.get(f["from"])
		if v == null:
			continue
		moved[f["to"]] = v
		var dist: float = absf(_cell_pos(f["to"]).y - _cell_pos(f["from"]).y)
		t2.tween_property(v, "position", _center(_cell_pos(f["to"])), 0.1 + 0.05 * dist).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		any = true
	for f in step["falls"]:
		views.erase(f["from"])
	for k in moved:
		views[k] = moved[k]
	for sp in step["spawns"]:
		var target := _cell_pos(sp["to"])
		var v := _make_view(sp["piece"], target)
		v.position = _center(Vector2i(target.x, sp["from_row"]))
		views[sp["to"]] = v
		var dist: float = absf(target.y - sp["from_row"])
		t2.tween_property(v, "position", _center(target), 0.1 + 0.05 * dist).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		any = true
	if any:
		await t2.finished
