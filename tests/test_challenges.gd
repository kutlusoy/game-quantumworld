extends SceneTree

const TerrainWorld = preload("res://scripts/core3d/terrain_world.gd")
const PlayerSim = preload("res://scripts/core3d/player_sim.gd")
const Challenge = preload("res://scripts/core3d/challenge.gd")
const Tracker = preload("res://scripts/core3d/challenge_tracker.gd")
const Progress = preload("res://scripts/core3d/progress.gd")

const FP := 1024
const JUMP := PlayerSim.BIT_JUMP
const DASH := PlayerSim.BIT_DASH

var failures := 0
var world
var sim
var tracker
var events_log := []
var holding_jump := false

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func step(mx: int, mz: int, bits: int) -> void:
	var ev: Dictionary = sim.step(mx, mz, bits)
	for e in tracker.update(sim, ev):
		events_log.append(e)

func dir_to(target: Vector3i) -> Array:
	var dx := float(target.x - sim.px)
	var dz := float(target.z - sim.pz)
	var d := maxf(sqrt(dx * dx + dz * dz), 1.0)
	return [roundi(dx / d * 100.0), roundi(dz / d * 100.0), d / FP]

func walk_to(target: Vector3i, max_ticks: int, jump_range: float, need_height: int = 300) -> int:
	var t := 0
	while t < max_ticks:
		var dd := dir_to(target)
		var bits := 0
		if sim.grounded:
			if holding_jump:
				holding_jump = false
			elif dd[2] < jump_range and target.y > sim.py + need_height:
				holding_jump = true
		if holding_jump:
			bits |= JUMP
		step(dd[0], dd[1], bits)
		t += 1
		if dd[2] < 0.35 and sim.grounded and absi(sim.py - target.y) < 250:
			return t
	return -1

func platform_center(p: Vector3i, size: int) -> Vector3i:
	return Vector3i(int((p.x + size * 0.5) * FP), (p.y + 1) * FP, int((p.z + size * 0.5) * FP))

func fresh() -> void:
	world = TerrainWorld.new(20241111)
	sim = PlayerSim.new(world)
	tracker = Tracker.new(Challenge.list_for(world))
	events_log = []
	for i in 10:
		step(0, 0, 0)

func finish_event(id: String) -> Variant:
	for e in events_log:
		if e["type"] == "finish" and e["id"] == id:
			return e
	return null

func test_progress() -> void:
	var p = Progress.new()
	check(p.level() == 1, "starts at level 1")
	check(p.add_xp(49) == 0 and p.level() == 1, "49 xp stays level 1")
	check(p.add_xp(1) == 1 and p.level() == 2, "50 xp reaches level 2")
	check(p.xp_for_level(3) == 150, "level 3 needs 150 xp")
	var g: int = p.record_tier("a", 2)
	check(g == 30, "bronze pays 30, got %d" % g)
	g = p.record_tier("a", 2)
	check(g == 0, "repeating the same tier pays nothing")
	g = p.record_tier("a", 0)
	check(g == 70, "improving to gold pays the difference, got %d" % g)
	var q = Progress.from_dict(p.to_dict())
	check(q.xp == p.xp and q.best_tier("a") == 0, "progress round trips")

func test_list() -> void:
	fresh()
	var list: Array = tracker.list
	check(list.size() == 3, "three challenges")
	for c in list:
		check(c.par[0] < c.par[1] and c.par[1] < c.par[2], "%s par times ascend" % c.id)
		var g: int = world.height_at(c.start.x, c.start.z)
		check(g != TerrainWorld.VOID, "%s start is over land" % c.id)
	check(sim.grounded, "player starts grounded")
	check(tracker.active == -1, "no challenge active at spawn")

func test_tower() -> void:
	fresh()
	var first: Vector3i = world.tower_platform(0)
	var start: Vector3i = tracker.list[0].start
	var t0 := walk_to(Vector3i(start.x, start.y, start.z), 2400, 0.0)
	check(t0 > 0, "bot reaches the tower start ring")
	step(0, 0, 0)
	for k in 8:
		step(0, 0, 0)
	check(tracker.active == -1 or tracker.active == 0, "ring state ok")
	var ok := true
	for i in TerrainWorld.TOWER_PLATFORMS:
		var target := platform_center(world.tower_platform(i), 2)
		var used := walk_to(target, 600, 2.4)
		if used < 0:
			ok = false
			print("tower bot stuck at platform ", i, " pos ", sim.px / 1024.0, " ", sim.py / 1024.0, " ", sim.pz / 1024.0)
			break
	check(ok, "bot climbs all tower platforms")
	var e: Variant = finish_event("tower_climb")
	check(e != null, "tower challenge finishes")
	if e != null:
		print("tower bot ticks ", e["ticks"], " tier ", e["tier"], " par ", tracker.list[0].par)
		check(e["tier"] == 0, "bot earns gold on the tower")

func hop_gap(dir_z: float, edge_z: int, dash_at: int) -> bool:
	var t := 0
	var air_t := -1
	while t < 400:
		var bits := 0
		var mz := roundi(dir_z * 100.0)
		if air_t < 0:
			if sim.grounded and ((dir_z < 0 and sim.pz < edge_z) or (dir_z > 0 and sim.pz > edge_z)):
				air_t = 0
		if air_t >= 0:
			if air_t < 4 or air_t >= dash_at + 12:
				bits |= JUMP
			if air_t >= dash_at and air_t < dash_at + 2:
				bits |= DASH
			air_t += 1
			if air_t > 6 and sim.grounded:
				return true
		step(0, mz, bits)
		t += 1
	return false

func test_chain() -> void:
	fresh()
	var top: Vector3i = world.tower_platform(TerrainWorld.TOWER_PLATFORMS - 1)
	var top_c := platform_center(top, 2)
	sim.set_position(Vector3i(top_c.x, top_c.y, top_c.z))
	for i in 10:
		step(0, 0, 0)
	check(sim.grounded, "player stands on the tower top")
	var isl0: Vector3i = world.chain_island(0)
	var edge0 := top.z * FP + 150
	var landed := hop_gap(-1.0, edge0, 6)
	check(landed, "bot crosses the first gap with a dash jump")
	var on_island0: bool = sim.pz >= isl0.z * FP and sim.pz < (isl0.z + 3) * FP and sim.py == (isl0.y + 1) * FP
	check(on_island0, "bot stands on island 0 at z=%.2f y=%.2f" % [sim.pz / 1024.0, sim.py / 1024.0])
	if on_island0:
		walk_to(Vector3i(int((isl0.x + 1.5) * FP), (isl0.y + 1) * FP, int((isl0.z + 1.5) * FP)), 300, 0.0)
		var isl1: Vector3i = world.chain_island(1)
		var landed2 := hop_gap(-1.0, isl0.z * FP + 150, 6)
		check(landed2, "bot crosses the second gap")
		var on1: bool = sim.pz >= isl1.z * FP and sim.pz < (isl1.z + 3) * FP
		check(on1, "bot stands on island 1")
	var nodash := PlayerSim.new(world)
	nodash.set_position(Vector3i(top_c.x, top_c.y, top_c.z))
	for i in 10:
		nodash.step(0, 0, 0)
	var t := 0
	var air := 0
	var reached := false
	while t < 400:
		var bits := 0
		if nodash.grounded and nodash.pz < top.z * FP + 150 and air == 0:
			air = 1
		if air > 0:
			bits = JUMP
			if air == 2:
				bits = 0
			if air >= 3 and air < 16:
				bits = JUMP
			air += 1
		nodash.step(0, -100, bits)
		t += 1
		if air > 4 and nodash.grounded:
			reached = nodash.pz < (isl0.z + 3) * FP
			break
	check(not reached, "the first gap cannot be crossed with double jump alone")

func test_ruin() -> void:
	fresh()
	var c = tracker.list[2]
	var x0 := TerrainWorld.RUIN_X - 4
	var z0 := TerrainWorld.RUIN_Z - 4
	var ground := TerrainWorld.RUIN_BASE * FP
	var walk := func(bx: float, bz: float) -> int:
		return walk_to(Vector3i(int(bx * FP), ground, int(bz * FP)), 900, 0.0)
	sim.set_position(Vector3i(int((x0 + 4.5) * FP), ground, int((z0 + 12.0) * FP)))
	for i in 10:
		step(0, 0, 0)
	check(walk.call(x0 + 4.5, z0 + 9.5) > 0, "bot walks to the ruin gate")
	check(tracker.active == 0 or tracker.active == 2 or tracker.active == -1, "tracker state sane")
	var pts := [Vector2(x0 + 4.5, z0 + 6.5), Vector2(x0 + 2.5, z0 + 3.5), Vector2(x0 + 6.5, z0 + 3.5)]
	var ok := true
	for p in pts:
		if walk.call(p.x, p.y) < 0:
			ok = false
			print("ruin bot stuck near ", sim.px / 1024.0, " ", sim.pz / 1024.0)
			break
	check(ok, "bot reaches all ruin shards")
	var collected := 0
	for k in c.required:
		if sim.collected[k] != 0:
			collected += 1
	check(collected == 3, "all three ruin shards collected (%d)" % collected)

func test_fail_and_arming() -> void:
	fresh()
	var c = tracker.list[0]
	sim.set_position(Vector3i(c.start.x + 6 * FP, c.start.y, c.start.z))
	for i in 10:
		step(0, 0, 0)
	check(tracker.active == -1, "not active outside the start ring")
	sim.set_position(Vector3i(c.start.x, c.start.y, c.start.z))
	for i in 5:
		step(0, 0, 0)
	check(tracker.active == 0, "entering the start ring starts the challenge")
	sim.set_position(Vector3i(5 * FP, 20 * FP, 5 * FP))
	var failed := false
	for i in 300:
		step(0, 0, 0)
		for e in events_log:
			if e["type"] == "fail":
				failed = true
	check(failed, "falling into the sea fails the challenge")
	check(tracker.active == -1, "tracker resets after a failure")

func _init() -> void:
	test_progress()
	test_list()
	test_tower()
	test_chain()
	test_ruin()
	test_fail_and_arming()
	if failures == 0:
		print("CHALLENGE TESTS PASSED")
	quit(1 if failures > 0 else 0)
