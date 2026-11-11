extends RefCounted

const Rng = preload("res://scripts/core/rng.gd")

const EMPTY := -1
const NO_COLOR := 15
const LINE_H := 1
const LINE_V := 2
const COLLAPSE := 3

var width: int
var height: int
var num_colors: int
var cells := PackedInt32Array()
var rng

func _init(w: int, h: int, colors: int, seed_value: int) -> void:
	width = w
	height = h
	num_colors = colors
	rng = Rng.new(seed_value)
	cells.resize(w * h)
	_fill_no_matches()
	if not has_possible_move():
		shuffle()

static func make_piece(color: int, special: int = 0) -> int:
	return (special << 4) | color

static func color_of(p: int) -> int:
	return p & 15

static func special_of(p: int) -> int:
	return p >> 4

func idx(x: int, y: int) -> int:
	return y * width + x

func at(x: int, y: int) -> int:
	return cells[y * width + x]

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height

func _fill_no_matches() -> void:
	for y in height:
		for x in width:
			var banned := {}
			if x >= 2 and at(x - 1, y) == at(x - 2, y):
				banned[at(x - 1, y)] = true
			if y >= 2 and at(x, y - 1) == at(x, y - 2):
				banned[at(x, y - 1)] = true
			var allowed: Array[int] = []
			for c in num_colors:
				if not banned.has(c):
					allowed.append(c)
			cells[idx(x, y)] = allowed[rng.next_int(allowed.size())]

func shuffle() -> void:
	for attempt in 200:
		var i := cells.size() - 1
		while i > 0:
			var j: int = rng.next_int(i + 1)
			var t := cells[i]
			cells[i] = cells[j]
			cells[j] = t
			i -= 1
		if find_runs().is_empty() and has_possible_move():
			return
	_fill_no_matches()

func _matchable(p: int) -> bool:
	return p != EMPTY and special_of(p) != COLLAPSE

func find_runs() -> Array:
	var runs := []
	for y in height:
		var x := 0
		while x < width:
			var p := at(x, y)
			if not _matchable(p):
				x += 1
				continue
			var c := color_of(p)
			var e := x + 1
			while e < width and _matchable(at(e, y)) and color_of(at(e, y)) == c:
				e += 1
			if e - x >= 3:
				var r := PackedInt32Array()
				for k in range(x, e):
					r.append(idx(k, y))
				runs.append({"cells": r, "horizontal": true})
			x = e
	for x in width:
		var y := 0
		while y < height:
			var p := at(x, y)
			if not _matchable(p):
				y += 1
				continue
			var c := color_of(p)
			var e := y + 1
			while e < height and _matchable(at(x, e)) and color_of(at(x, e)) == c:
				e += 1
			if e - y >= 3:
				var r := PackedInt32Array()
				for k in range(y, e):
					r.append(idx(x, k))
				runs.append({"cells": r, "horizontal": false})
			y = e
	return runs

func _swap(i: int, j: int) -> void:
	var t := cells[i]
	cells[i] = cells[j]
	cells[j] = t

func is_valid_swap(a: Vector2i, b: Vector2i) -> bool:
	if not in_bounds(a.x, a.y) or not in_bounds(b.x, b.y):
		return false
	if absi(a.x - b.x) + absi(a.y - b.y) != 1:
		return false
	var ia := idx(a.x, a.y)
	var ib := idx(b.x, b.y)
	if cells[ia] == EMPTY or cells[ib] == EMPTY:
		return false
	if special_of(cells[ia]) == COLLAPSE or special_of(cells[ib]) == COLLAPSE:
		return true
	_swap(ia, ib)
	var ok := not find_runs().is_empty()
	_swap(ia, ib)
	return ok

func valid_moves() -> Array:
	var moves := []
	for y in height:
		for x in width:
			var a := Vector2i(x, y)
			if x + 1 < width and is_valid_swap(a, Vector2i(x + 1, y)):
				moves.append([a, Vector2i(x + 1, y)])
			if y + 1 < height and is_valid_swap(a, Vector2i(x, y + 1)):
				moves.append([a, Vector2i(x, y + 1)])
	return moves

func has_possible_move() -> bool:
	return not valid_moves().is_empty()

func play_move(a: Vector2i, b: Vector2i) -> Dictionary:
	var result := {"valid": false, "steps": [], "score": 0}
	if not is_valid_swap(a, b):
		return result
	result["valid"] = true
	var ia := idx(a.x, a.y)
	var ib := idx(b.x, b.y)
	_swap(ia, ib)
	var swapped := [ia, ib]
	var forced := _collapse_cells(ia, ib)
	var cascade := 0
	var total := 0
	while cascade < 100:
		var clear := {}
		var creations := {}
		if not forced.is_empty():
			for i in forced:
				clear[i] = true
			forced = PackedInt32Array()
		else:
			var runs := find_runs()
			if runs.is_empty():
				break
			for r in runs:
				for i in r["cells"]:
					clear[i] = true
				var n: int = r["cells"].size()
				if n >= 4:
					var at_i := _creation_cell(r["cells"], swapped)
					if n >= 5:
						creations[at_i] = make_piece(NO_COLOR, COLLAPSE)
					else:
						var col := color_of(cells[r["cells"][0]])
						creations[at_i] = make_piece(col, LINE_H if r["horizontal"] else LINE_V)
		swapped = []
		cascade += 1
		_expand_triggers(clear)
		for i in creations:
			clear.erase(i)
		var cleared_list := PackedInt32Array(clear.keys())
		cleared_list.sort()
		var cleared := []
		for i in cleared_list:
			cleared.append({"idx": i, "piece": cells[i]})
			cells[i] = EMPTY
		var created := []
		for i in creations:
			cells[i] = creations[i]
			created.append({"idx": i, "piece": creations[i]})
		var gained := cleared_list.size() * 10 * cascade
		total += gained
		var moved := _apply_gravity()
		result["steps"].append({
			"type": "clear",
			"cleared": cleared,
			"created": created,
			"falls": moved["falls"],
			"spawns": moved["spawns"],
			"score": gained,
			"cascade": cascade,
		})
	if not has_possible_move():
		shuffle()
		result["steps"].append({"type": "reshuffle"})
	result["score"] = total
	return result

func _creation_cell(run_cells: PackedInt32Array, swapped: Array) -> int:
	for i in swapped:
		if run_cells.has(i):
			return i
	return run_cells[run_cells.size() / 2]

func _collapse_cells(ia: int, ib: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var ca := special_of(cells[ia]) == COLLAPSE
	var cb := special_of(cells[ib]) == COLLAPSE
	if not ca and not cb:
		return out
	if ca and cb:
		for i in cells.size():
			out.append(i)
		return out
	var other := cells[ib] if ca else cells[ia]
	out.append(ia if ca else ib)
	var col := color_of(other)
	for i in cells.size():
		if cells[i] != EMPTY and special_of(cells[i]) != COLLAPSE and color_of(cells[i]) == col:
			out.append(i)
	return out

@warning_ignore("integer_division")
func _expand_triggers(clear: Dictionary) -> void:
	var queue: Array = clear.keys()
	var qi := 0
	while qi < queue.size():
		var i: int = queue[qi]
		qi += 1
		var s := special_of(cells[i])
		if s == LINE_H:
			var y := i / width
			for x in width:
				_add_clear(clear, queue, y * width + x)
		elif s == LINE_V:
			var x := i % width
			for y in height:
				_add_clear(clear, queue, y * width + x)

func _add_clear(clear: Dictionary, queue: Array, i: int) -> void:
	if not clear.has(i):
		clear[i] = true
		queue.append(i)

func _apply_gravity() -> Dictionary:
	var falls := []
	var spawns := []
	for x in width:
		var write := height - 1
		for y in range(height - 1, -1, -1):
			var p := at(x, y)
			if p == EMPTY:
				continue
			if y != write:
				falls.append({"from": idx(x, y), "to": idx(x, write), "piece": p})
				cells[idx(x, write)] = p
				cells[idx(x, y)] = EMPTY
			write -= 1
		var count := write + 1
		for y in range(0, count):
			var p: int = rng.next_int(num_colors)
			cells[idx(x, y)] = p
			spawns.append({"to": idx(x, y), "piece": p, "from_row": y - count})
	return {"falls": falls, "spawns": spawns}

func fingerprint() -> int:
	var h := 2166136261
	for v in cells:
		h = ((h ^ (v & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
	return h
