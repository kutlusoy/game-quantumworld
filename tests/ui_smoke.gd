extends SceneTree

var failures := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._start_level(0)
	await process_frame
	var bv = main.board_view
	check(bv.views.size() == 64, "all pieces have views")
	for i in 5:
		var moves: Array = main.session.board.valid_moves()
		if moves.is_empty():
			break
		bv._attempt(moves[0][0], moves[0][1])
		while bv.busy:
			await process_frame
		check(bv.views.size() == 64, "view count stable after move %d" % i)
		var consistent := true
		for k in bv.views:
			var v = bv.views[k]
			var c: Vector2i = bv._cell_pos(k)
			if v.position.distance_to(bv._center(c)) > 0.5 or v.piece != main.session.board.cells[k]:
				consistent = false
		check(consistent, "views match board after move %d" % i)
	check(main.session.moves_left == 25, "moves consumed")
	if failures == 0:
		print("UI SMOKE PASSED")
	quit(1 if failures > 0 else 0)
