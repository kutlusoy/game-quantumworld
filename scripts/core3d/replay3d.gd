extends RefCounted

const VoxelWorld = preload("res://scripts/core3d/voxel_world.gd")
const PlayerSim = preload("res://scripts/core3d/player_sim.gd")

static func run(seed_value: int, frames: Array) -> Dictionary:
	var world = VoxelWorld.new(seed_value)
	var sim = PlayerSim.new(world)
	for f in frames:
		sim.step(f[0], f[1], f[2])
	return {
		"ticks": sim.tick,
		"collected": sim.collected_count,
		"fingerprint": sim.fingerprint(),
		"position": Vector3i(sim.px, sim.py, sim.pz),
	}
