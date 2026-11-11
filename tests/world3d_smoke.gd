extends SceneTree

var failures := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func _init() -> void:
	var game = load("res://scenes/world3d.tscn").instantiate()
	root.add_child(game)
	for i in 5:
		await physics_frame
	check(game.sim != null and game.world != null, "scene builds world and sim")
	check(game.shard_nodes.size() == game.world.shards.size(), "one node per shard")
	check(game.sim.grounded, "player stands on the ground")
	var z0: int = game.sim.pz
	game.touch.move = Vector2(0, -1)
	for i in 60:
		await physics_frame
	check(game.sim.pz != z0 or game.sim.px != game.world.spawn.x, "stick input moves the player")
	check(game.input_log.size() >= 60, "inputs are recorded")
	game.touch.move = Vector2.ZERO
	game.touch.jump_held = true
	for i in 3:
		await physics_frame
	check(game.sim.py > game.world.spawn.y or not game.sim.grounded, "jump input leaves the ground")
	game.touch.jump_held = false
	if failures == 0:
		print("WORLD3D SMOKE PASSED")
	quit(1 if failures > 0 else 0)
