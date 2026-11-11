extends SceneTree

const Rng = preload("res://scripts/core/rng.gd")
const Board = preload("res://scripts/core/board.gd")
const Level = preload("res://scripts/core/level.gd")
const Session = preload("res://scripts/core/session.gd")
const Replay = preload("res://scripts/core/replay.gd")

var failures := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func set_cells(b, rows: Array) -> void:
	for y in rows.size():
		for x in rows[y].size():
			b.cells[b.idx(x, y)] = rows[y][x]

func plain_board():
	var b = Board.new(6, 6, 4, 7)
	set_cells(b, [
		[0, 0, 1, 0, 2, 3],
		[2, 3, 0, 1, 3, 2],
		[1, 2, 3, 2, 0, 1],
		[3, 0, 1, 3, 1, 0],
		[0, 1, 2, 0, 2, 3],
		[2, 3, 0, 1, 3, 2],
	])
	return b

func test_rng() -> void:
	var a = Rng.new(42)
	var b = Rng.new(42)
	var same := true
	for i in 100:
		if a.next_u32() != b.next_u32():
			same = false
	check(same, "rng deterministic")
	var c = Rng.new(43)
	var d = Rng.new(42)
	check(c.next_u32() != d.next_u32(), "rng seed sensitivity")
	var e = Rng.new(5)
	var in_range := true
	for i in 1000:
		var v: int = e.next_int(6)
		if v < 0 or v >= 6:
			in_range = false
	check(in_range, "rng next_int range")

func test_initial_board() -> void:
	for s in range(1, 40):
		var b = Board.new(8, 8, 4 + s % 3, s)
		check(b.find_runs().is_empty(), "no initial matches seed %d" % s)
		check(b.has_possible_move(), "initial move exists seed %d" % s)

func test_line_special() -> void:
	var b = plain_board()
	check(b.is_valid_swap(Vector2i(2, 0), Vector2i(2, 1)), "swap valid")
	check(not b.is_valid_swap(Vector2i(0, 0), Vector2i(0, 1)), "swap invalid")
	check(not b.is_valid_swap(Vector2i(0, 0), Vector2i(1, 1)), "diagonal invalid")
	var r: Dictionary = b.play_move(Vector2i(2, 0), Vector2i(2, 1))
	check(r["valid"], "play valid")
	var step: Dictionary = r["steps"][0]
	check(step["created"].size() == 1, "special created")
	check(step["created"][0]["idx"] == 2, "special at swap cell")
	check(Board.special_of(step["created"][0]["piece"]) == Board.LINE_H, "line h special")
	check(step["cleared"].size() == 3, "three cleared")
	check(r["score"] >= 30, "score counted")
	check(b.find_runs().is_empty(), "board settled")

func test_collapse() -> void:
	var b = plain_board()
	b.cells[b.idx(0, 0)] = Board.make_piece(Board.NO_COLOR, Board.COLLAPSE)
	var target: int = b.cells[b.idx(1, 0)]
	var count := 0
	for p in b.cells:
		if Board.special_of(p) != Board.COLLAPSE and Board.color_of(p) == target:
			count += 1
	check(b.is_valid_swap(Vector2i(0, 0), Vector2i(1, 0)), "collapse swap valid")
	var r: Dictionary = b.play_move(Vector2i(0, 0), Vector2i(1, 0))
	check(r["steps"][0]["cleared"].size() == count + 1, "collapse clears color")

func test_board_stays_full() -> void:
	var b = Board.new(8, 8, 5, 99)
	for i in 30:
		var moves: Array = b.valid_moves()
		if moves.is_empty():
			break
		var m: Array = moves[i % moves.size()]
		b.play_move(m[0], m[1])
		var full := true
		for p in b.cells:
			if p == Board.EMPTY:
				full = false
		check(full, "no empty cells after move %d" % i)
		check(b.find_runs().is_empty(), "no pending matches after move %d" % i)

func play_random(level, seed_value: int) -> Session:
	var s = Session.new(level)
	var r = Rng.new(seed_value)
	while not s.is_over():
		var moves: Array = s.board.valid_moves()
		var m: Array = moves[r.next_int(moves.size())]
		s.play(m[0], m[1])
	return s

func test_replay() -> void:
	var level = Level.from_dict({"id": 1, "seed": 1234, "width": 8, "height": 8, "colors": 5, "moves": 15, "target": 400})
	var s = play_random(level, 5)
	var out: Dictionary = Replay.run(level, s.log)
	check(out["valid"], "replay valid")
	check(out["score"] == s.score, "replay score matches")
	check(out["fingerprint"] == s.board.fingerprint(), "replay fingerprint matches")
	var bad: Array = s.log.duplicate(true)
	bad[3] = [0, 0, 0, 0]
	check(not Replay.run(level, bad)["valid"], "tampered replay rejected")
	var too_long: Array = s.log.duplicate(true)
	too_long.append([0, 0, 1, 0])
	check(not Replay.run(level, too_long)["valid"], "too many moves rejected")

func test_levels() -> void:
	var levels: Array = Level.load_all()
	check(levels.size() >= 1, "levels load")
	var prev := 0
	for l in levels:
		check(l.id > prev, "level ids ascending")
		prev = l.id
		check(l.colors >= 3 and l.colors <= 6, "level colors range")
		check(l.width >= 5 and l.height >= 5, "level size")
		check(l.moves > 0 and l.target > 0, "level goals")
		check(Board.new(l.width, l.height, l.colors, l.seed_value).has_possible_move(), "level %d playable" % l.id)

func _init() -> void:
	test_rng()
	test_initial_board()
	test_line_special()
	test_collapse()
	test_board_stays_full()
	test_replay()
	test_levels()
	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
