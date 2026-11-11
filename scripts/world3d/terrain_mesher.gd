extends RefCounted

const TerrainWorld = preload("res://scripts/core3d/terrain_world.gd")

const CHUNK := 32

static func vcolor(world, x: int, z: int) -> Color:
	var h: float = world.vheight(x, z) / 1024.0
	var n: Vector3 = vnormal(world, x, z)
	var v: float = (TerrainWorld.hash3(x, z, 99) & 255) / 255.0
	var grass := Color(0.34 + 0.1 * v, 0.76 - 0.08 * v, 0.3)
	var rock := Color(0.56, 0.5, 0.64)
	var sand := Color(0.95, 0.87, 0.64)
	if h < 1.6:
		return sand
	if n.y < 0.62:
		return rock
	if n.y < 0.8:
		return grass.lerp(rock, (0.8 - n.y) / 0.18)
	return grass.lerp(Color(0.6, 0.9, 0.42), clampf((h - 8.0) / 8.0, 0.0, 1.0))

static func vnormal(world, x: int, z: int) -> Vector3:
	var nx: float = (world.vheight(x - 1, z) - world.vheight(x + 1, z)) / 1024.0
	var nz: float = (world.vheight(x, z - 1) - world.vheight(x, z + 1)) / 1024.0
	return Vector3(nx, 2.0, nz).normalized()

static func build(world, cx: int, cz: int) -> ArrayMesh:
	var x0 := cx * CHUNK
	var z0 := cz * CHUNK
	var x1 := mini(x0 + CHUNK, TerrainWorld.W)
	var z1 := mini(z0 + CHUNK, TerrainWorld.D)
	var nxv := x1 - x0 + 1
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			verts.append(Vector3(x, world.vheight(x, z) / 1024.0, z))
			norms.append(vnormal(world, x, z))
			cols.append(vcolor(world, x, z))
	for z in range(z1 - z0):
		for x in range(x1 - x0):
			var v00 := z * nxv + x
			var v10 := v00 + 1
			var v01 := v00 + nxv
			var v11 := v01 + 1
			idx.append_array([v00, v10, v11, v00, v11, v01])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
