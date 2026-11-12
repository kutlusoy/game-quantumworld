extends SceneTree

const TerrainWorld = preload("res://scripts/core3d/terrain_world.gd")
const PlayerSim = preload("res://scripts/core3d/player_sim.gd")
const Replay3D = preload("res://scripts/core3d/replay3d.gd")
const Rng = preload("res://scripts/core/rng.gd")

const FP := 1024.0
const JUMP := PlayerSim.BIT_JUMP
const DASH := PlayerSim.BIT_DASH

var failures := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func flat_sim():
	var w = TerrainWorld.new(1, 4)
	var s = PlayerSim.new(w)
	for i in 10:
		s.step(0, 0, 0)
	return s

func test_worldgen() -> void:
	var a = TerrainWorld.new(77)
	var b = TerrainWorld.new(77)
	var c = TerrainWorld.new(78)
	check(a.fingerprint() == b.fingerprint(), "worldgen deterministic")
	check(a.fingerprint() != c.fingerprint(), "worldgen seed sensitive")
	check(a.shards == b.shards, "shards deterministic")
	check(a.shards.size() >= 50, "at least 50 shards, got %d" % a.shards.size())
	for i in a.shards.size():
		var s: Vector3i = a.shards[i]
		var g: int = a.height_at(s.x, s.y)
		check(s.y > g or g == TerrainWorld.VOID, "shard %d above the ground" % i)
		var inside := false
		for k in a.box_min.size():
			if s.x > a.box_min[k].x and s.x < a.box_max[k].x and s.y > a.box_min[k].y and s.y < a.box_max[k].y and s.z > a.box_min[k].z and s.z < a.box_max[k].z:
				inside = true
		check(not inside, "shard %d not inside a box" % i)
	var sp: Vector3i = a.spawn
	check(a.height_at(sp.x, sp.z) == sp.y, "spawn stands on the terrain")
	check(a.height_at(sp.x, sp.z) > TerrainWorld.SEA, "spawn is above sea level")
	check(a.trees.size() > 30, "trees placed")

func test_slopes() -> void:
	var w = TerrainWorld.new(1, 4)
	for z in range(0, TerrainWorld.D + 1):
		for x in range(40, TerrainWorld.W + 1):
			w.hv[w.vidx(x, z)] = 4 * 1024 + (x - 40) * 1024
	var s = PlayerSim.new(w)
	s.set_position(Vector3i(36 * 1024, 4 * 1024, 32 * 1024))
	for i in 10:
		s.step(0, 0, 0)
	for i in 160:
		s.step(100, 0, 0)
	check(s.px > 44 * 1024, "45 degree slope is walkable, x=%d" % s.px)
	check(s.grounded, "grounded while climbing")
	var w2 = TerrainWorld.new(1, 4)
	for z in range(0, TerrainWorld.D + 1):
		for x in range(40, TerrainWorld.W + 1):
			w2.hv[w2.vidx(x, z)] = 4 * 1024 + (x - 40) * 3 * 1024
	var s2 = PlayerSim.new(w2)
	s2.set_position(Vector3i(36 * 1024, 4 * 1024, 32 * 1024))
	for i in 10:
		s2.step(0, 0, 0)
	for i in 160:
		s2.step(100, 0, 0)
	check(s2.px < 41 * 1024, "steep slope blocks the player, x=%d" % s2.px)
	var s3 = PlayerSim.new(w)
	s3.set_position(Vector3i(60 * 1024, 4 * 1024 + 20 * 1024, 32 * 1024))
	for i in 200:
		s3.step(-100, 0, 0)
	check(s3.px < 52 * 1024 and s3.grounded, "walking downhill keeps the player grounded, x=%d" % s3.px)

func test_sea() -> void:
	var w = TerrainWorld.new(5)
	var s = PlayerSim.new(w)
	s.set_position(Vector3i(5 * 1024, 20 * 1024, 5 * 1024))
	var respawned := false
	for i in 400:
		var ev: Dictionary = s.step(0, 0, 0)
		if ev["respawned"]:
			respawned = true
			break
	check(respawned, "falling into the sea respawns")
	check(s.px == w.spawn.x, "respawn at spawn")

func test_basic_physics() -> void:
	var s = flat_sim()
	check(s.grounded, "grounded after settling")
	check(s.py == 4 * 1024, "standing on top of the floor, y=%d" % s.py)
	var z0: int = s.pz
	for i in 40:
		s.step(0, 100, 0)
	check(s.pz > z0 + 4 * 1024, "running moves forward")
	check(absi(s.vz) <= PlayerSim.RUN_SPEED, "speed capped")

func test_wall() -> void:
	var w = TerrainWorld.new(1, 4)
	w.add_box(Vector3i(0, 4 * 1024, 40 * 1024), Vector3i(96 * 1024, 8 * 1024, 41 * 1024), "ruin")
	var s = PlayerSim.new(w)
	for i in 10:
		s.step(0, 0, 0)
	for i in 200:
		s.step(0, -100, 0)
	check(s.pz > 41 * 1024, "wall blocks the player")
	check(s.pz == 41 * 1024 + PlayerSim.HALF_W, "player rests against wall exactly, z=%d" % s.pz)
	var w2 = TerrainWorld.new(1, 4)
	w2.add_box(Vector3i(30 * 1024, 4 * 1024, 30 * 1024), Vector3i(36 * 1024, 5 * 1024, 36 * 1024), "crystal")
	var s2 = PlayerSim.new(w2)
	s2.set_position(Vector3i(33 * 1024, 7 * 1024, 33 * 1024))
	for i in 60:
		s2.step(0, 0, 0)
	check(s2.py == 5 * 1024 and s2.grounded, "player lands on a box, y=%d" % s2.py)
	var w3 = TerrainWorld.new(1, 4)
	w3.add_box(Vector3i(30 * 1024, 6 * 1024, 30 * 1024), Vector3i(36 * 1024, 7 * 1024, 36 * 1024), "crystal")
	var s3 = PlayerSim.new(w3)
	s3.set_position(Vector3i(33 * 1024, 4 * 1024, 33 * 1024))
	for i in 3:
		s3.step(0, 0, 0)
	for i in 30:
		s3.step(0, 0, 1)
	check(s3.py + PlayerSim.HEIGHT <= 6 * 1024, "head stops under a ceiling box, y=%d" % s3.py)

func jump_apex(held_ticks: int, second_press_at: int = -1) -> float:
	var s = flat_sim()
	var apex: int = s.py
	var left := false
	for t in 200:
		var bits := 0
		if t < held_ticks:
			bits = JUMP
		if second_press_at >= 0 and t >= second_press_at and t < second_press_at + 40:
			bits = JUMP
		if second_press_at >= 0 and t == second_press_at - 1:
			bits = 0
		s.step(0, 0, bits)
		apex = maxi(apex, s.py)
		if not s.grounded:
			left = true
		if left and s.grounded:
			break
	return (apex - 4 * 1024) / FP

func test_jumps() -> void:
	var single := jump_apex(60)
	check(single > 1.3 and single < 1.9, "single jump apex %.2f in range" % single)
	var tap := jump_apex(3)
	check(tap < single - 0.2 and tap > 0.6, "short tap gives lower jump %.2f vs %.2f" % [tap, single])
	var dbl := jump_apex(10, 14)
	check(dbl > 2.4 and dbl < 3.2, "double jump apex %.2f in range" % dbl)

func test_dash() -> void:
	var s = flat_sim()
	var z0: int = s.pz
	s.step(0, 100, 0)
	var ev: Dictionary = s.step(0, 100, DASH)
	check(ev["dashed"], "dash triggered")
	for i in 9:
		s.step(0, 100, DASH)
	var dist: float = (s.pz - z0) / FP
	check(dist > 2.5, "dash covers distance %.2f" % dist)
	var ev2: Dictionary = s.step(0, 100, 0)
	check(not ev2["dashed"], "no dash without new press")
	var s2 = flat_sim()
	s2.step(0, 100, DASH)
	s2.step(0, 100, 0)
	var e: Dictionary = s2.step(0, 100, DASH)
	check(not e["dashed"], "dash on cooldown")

func test_glide() -> void:
	var s = flat_sim()
	s.set_position(Vector3i(32 * 1024 + 512, 30 * 1024, 32 * 1024 + 512))
	s.jumps_left = 0
	s.step(0, 0, 0)
	s.step(0, 0, JUMP)
	check(s.gliding, "glide starts after air jumps are used")
	for i in 20:
		s.step(0, 0, JUMP)
	check(s.vy >= -PlayerSim.GLIDE_FALL, "glide caps fall speed")
	s.step(0, 0, 0)
	check(not s.gliding, "glide ends on release")
	for i in 40:
		s.step(0, 0, 0)
	check(s.vy < -PlayerSim.GLIDE_FALL, "free fall is faster than glide")

func ledge_sim():
	var w = TerrainWorld.new(1, 4)
	for z in range(0, TerrainWorld.D + 1):
		for x in range(35, TerrainWorld.W + 1):
			w.hv[w.vidx(x, z)] = 0
	var s = PlayerSim.new(w)
	s.set_position(Vector3i(30 * 1024, 4 * 1024, 32 * 1024))
	for i in 10:
		s.step(0, 0, 0)
	return s

func test_coyote() -> void:
	for case in [[2, true], [9, false]]:
		var s = ledge_sim()
		var left_at := -1
		var t := 0
		while t < 200 and left_at < 0:
			s.step(100, 0, 0)
			t += 1
			if not s.grounded:
				left_at = t
		check(left_at > 0, "walked off the ledge")
		for i in case[0]:
			s.step(100, 0, 0)
		var ev: Dictionary = s.step(100, 0, JUMP)
		check(ev["jumped"] == case[1], "coyote jump %d ticks after leaving: %s" % [case[0], str(ev["jumped"])])

func test_jump_buffer() -> void:
	var s = flat_sim()
	s.set_position(Vector3i(32 * 1024, 4 * 1024 + 400, 32 * 1024))
	s.jumps_left = 0
	s.step(0, 0, 0)
	s.step(0, 0, JUMP)
	s.step(0, 0, 0)
	var jumped := false
	for i in 12:
		var ev: Dictionary = s.step(0, 0, 0)
		if ev["jumped"]:
			jumped = true
	check(jumped, "buffered jump fires on landing")

func test_shard_collect() -> void:
	var w = TerrainWorld.new(9)
	var s = PlayerSim.new(w)
	var c: Vector3i = w.shard_center(0)
	s.set_position(Vector3i(c.x, c.y - PlayerSim.HEIGHT / 2, c.z))
	var ev: Dictionary = s.step(0, 0, 0)
	check(ev["collected"].has(0), "shard collected on contact")
	check(s.collected_count == 1, "count updated")
	var ev2: Dictionary = s.step(0, 0, 0)
	check(ev2["collected"].is_empty(), "shard only collected once")

func random_frames(seed_value: int, n: int) -> Array:
	var r = Rng.new(seed_value)
	var frames := []
	var mx := 0
	var mz := 0
	var bits := 0
	for i in n:
		if i % 20 == 0:
			mx = int(r.next_int(201)) - 100
			mz = int(r.next_int(201)) - 100
		if i % 7 == 0:
			bits = int(r.next_int(4))
		frames.append([mx, mz, bits])
	return frames

func test_replay() -> void:
	var frames := random_frames(3, 3000)
	var a: Dictionary = Replay3D.run(4242, frames)
	var b: Dictionary = Replay3D.run(4242, frames)
	check(a["fingerprint"] == b["fingerprint"], "replay is deterministic")
	check(a["ticks"] == 3000, "all ticks replayed")
	check(a["position"] != Vector3i(32 * 1024 + 512, 0, 32 * 1024 + 512), "player moved in replay")
	var frames2: Array = frames.duplicate(true)
	for i in range(1000, 1200):
		frames2[i] = [-frames2[i][0], -frames2[i][1], frames2[i][2]]
	var c: Dictionary = Replay3D.run(4242, frames2)
	check(c["fingerprint"] != a["fingerprint"], "different inputs give a different result")
	var d: Dictionary = Replay3D.run(4243, frames)
	check(d["fingerprint"] != a["fingerprint"], "different world seed gives a different result")

func reach_after(bits_fn: Callable, ticks: int) -> float:
	var s = flat_sim()
	for i in 40:
		s.step(0, 100, 0)
	var z0: int = s.pz
	var air := false
	for t in ticks:
		var bits: int = bits_fn.call(t)
		s.step(0, 100, bits)
		if not s.grounded:
			air = true
		if air and s.grounded:
			break
	return (s.pz - z0) / FP

func test_layout() -> void:
	var single := reach_after(func(t): return JUMP if t < 60 else 0, 200)
	var dbl := reach_after(func(t): return JUMP if (t < 14 or (t >= 16 and t < 80)) else 0, 200)
	var dash := reach_after(func(t): return (JUMP if (t < 4 or (t >= 22 and t < 120)) else 0) | (DASH if (t >= 10 and t < 12) else 0), 300)
	print("reach single=%.2f double=%.2f dash+double=%.2f" % [single, dbl, dash])
	check(single < dbl and dbl < dash, "reach grows with abilities")
	check(1.0 < single, "tower gap of 1 block is reachable with a single jump")
	check(TerrainWorld.CHAIN_GAP > dbl - 0.2, "dash chain gap needs a dash (gap %d, double reach %.2f)" % [TerrainWorld.CHAIN_GAP, dbl])
	check(TerrainWorld.CHAIN_GAP < dash - 1.0, "dash chain gap is reachable with margin (gap %d, reach %.2f)" % [TerrainWorld.CHAIN_GAP, dash])
	var w = TerrainWorld.new(1)
	for i in TerrainWorld.TOWER_PLATFORMS - 1:
		var p: Vector3i = w.tower_platform(i)
		var q: Vector3i = w.tower_platform(i + 1)
		check(q.y - p.y == 1, "tower steps up by one block")
		var gx := maxi(absi(q.x - p.x) - 2, 0)
		var gz := maxi(absi(q.z - p.z) - 2, 0)
		check(maxf(gx, gz) <= 1.0, "tower gap %d,%d between %d and %d" % [gx, gz, i, i + 1])
	var first: Vector3i = w.tower_platform(0)
	var base_h: int = w.height_at(first.x * 1024 + 1024, first.z * 1024 + 1024)
	check(absi(base_h - TerrainWorld.TOWER_BASE * 1024) < 200, "tower base is flattened, h=%d" % base_h)
	var found := 0
	for i in TerrainWorld.CHAIN_ISLANDS:
		var p: Vector3i = w.chain_island(i)
		if p.z >= 1:
			found += 1
	check(found == TerrainWorld.CHAIN_ISLANDS, "all chain islands fit in the world (%d)" % found)

func _init() -> void:
	var t0 := Time.get_ticks_msec()
	test_worldgen()
	test_basic_physics()
	test_wall()
	test_jumps()
	test_dash()
	test_glide()
	test_coyote()
	test_jump_buffer()
	test_sea()
	test_slopes()
	test_shard_collect()
	test_replay()
	test_layout()
	print("controller tests took ", Time.get_ticks_msec() - t0, " ms")
	if failures == 0:
		print("CONTROLLER TESTS PASSED")
	quit(1 if failures > 0 else 0)
