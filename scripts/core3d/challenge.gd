extends RefCounted

const TerrainWorld = preload("res://scripts/core3d/terrain_world.gd")

const FP := 1024
const TICKS := 60

var id := ""
var title := ""
var kind := "parkour"
var start := Vector3i()
var finish := Vector3i()
var radius := 1300
var vtol := 1800
var par := [0, 0, 0]
var required: Array = []
var limit := 180 * TICKS

static func ring_center(bx: float, by: float, bz: float) -> Vector3i:
	return Vector3i(int(bx * FP), int(by * FP), int(bz * FP))

static func list_for(world) -> Array:
	var out := []
	var first: Vector3i = world.tower_platform(0)
	var top: Vector3i = world.tower_platform(TerrainWorld.TOWER_PLATFORMS - 1)
	var c1 = new()
	c1.id = "tower_climb"
	c1.title = "Tower Climb"
	c1.kind = "parkour"
	c1.start = ring_center(first.x - 2.0, TerrainWorld.TOWER_BASE, first.z + 1.0)
	c1.finish = ring_center(top.x + 1.0, top.y + 1.0, top.z + 1.0)
	c1.radius = 1000
	c1.par = [12 * TICKS, 20 * TICKS, 40 * TICKS]
	out.append(c1)
	var i0: Vector3i = world.chain_island(0)
	var i2: Vector3i = world.chain_island(TerrainWorld.CHAIN_ISLANDS - 1)
	var c2 = new()
	c2.id = "crystal_leap"
	c2.title = "Crystal Leap"
	c2.kind = "parkour"
	c2.start = ring_center(i0.x + 1.5, i0.y + 1.0, i0.z + 1.5)
	c2.finish = ring_center(i2.x + 1.5, i2.y + 1.0, i2.z + 1.5)
	c2.radius = 900
	c2.par = [12 * TICKS, 20 * TICKS, 40 * TICKS]
	out.append(c2)
	var c3 = new()
	c3.id = "ruin_run"
	c3.title = "Ruin Run"
	c3.kind = "shard_run"
	c3.start = ring_center(TerrainWorld.RUIN_X + 0.5, TerrainWorld.RUIN_BASE, TerrainWorld.RUIN_Z + 7.0)
	c3.finish = c3.start
	c3.radius = 1200
	c3.par = [16 * TICKS, 26 * TICKS, 50 * TICKS]
	c3.required = world.ruin_shards.duplicate()
	c3.limit = 90 * TICKS
	out.append(c3)
	return out

func in_ring(c: Vector3i, px: int, py: int, pz: int) -> bool:
	var dx := px - c.x
	var dz := pz - c.z
	return dx * dx + dz * dz <= radius * radius and absi(py - c.y) <= vtol

func tier_for(ticks: int) -> int:
	if ticks <= par[0]:
		return 0
	if ticks <= par[1]:
		return 1
	if ticks <= par[2]:
		return 2
	return 3
