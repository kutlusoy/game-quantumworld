extends RefCounted

const VoxelWorld = preload("res://scripts/core3d/voxel_world.gd")

const CHUNK := 16

const FACES := [
	{"n": Vector3i(1, 0, 0), "u": Vector3i(0, 1, 0), "v": Vector3i(0, 0, 1), "o": Vector3i(1, 0, 0), "shade": 0.8},
	{"n": Vector3i(-1, 0, 0), "u": Vector3i(0, 0, 1), "v": Vector3i(0, 1, 0), "o": Vector3i(0, 0, 0), "shade": 0.8},
	{"n": Vector3i(0, 1, 0), "u": Vector3i(0, 0, 1), "v": Vector3i(1, 0, 0), "o": Vector3i(0, 1, 0), "shade": 1.0},
	{"n": Vector3i(0, -1, 0), "u": Vector3i(1, 0, 0), "v": Vector3i(0, 0, 1), "o": Vector3i(0, 0, 0), "shade": 0.55},
	{"n": Vector3i(0, 0, 1), "u": Vector3i(1, 0, 0), "v": Vector3i(0, 1, 0), "o": Vector3i(0, 0, 1), "shade": 0.7},
	{"n": Vector3i(0, 0, -1), "u": Vector3i(0, 1, 0), "v": Vector3i(1, 0, 0), "o": Vector3i(0, 0, 0), "shade": 0.7},
]

static func color_for(block: int, top: bool, bottom: bool) -> Color:
	match block:
		VoxelWorld.GRASS:
			if top:
				return Color("6fdc5a")
			if bottom:
				return Color("8a5a3c")
			return Color("8fbf55")
		VoxelWorld.DIRT:
			return Color("8a5a3c")
		VoxelWorld.STONE:
			return Color("8c92a8")
		VoxelWorld.SAND:
			return Color("f0dd9e")
		VoxelWorld.CRYSTAL:
			return Color("7fe0ff") if top else Color("5fb8f0")
		VoxelWorld.WOOD:
			return Color("9a6b3f")
		VoxelWorld.RUIN:
			return Color("b9aed0")
	return Color.WHITE

static func _solid(world, p: Vector3i) -> int:
	return 1 if world.get_block(p.x, p.y, p.z) != VoxelWorld.AIR else 0

static func build(world, cx: int, cz: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for z in range(cz * CHUNK, mini((cz + 1) * CHUNK, world.D)):
		for x in range(cx * CHUNK, mini((cx + 1) * CHUNK, world.W)):
			for y in range(0, world.max_y + 1):
				var b: int = world.get_block(x, y, z)
				if b == VoxelWorld.AIR:
					continue
				var cell := Vector3i(x, y, z)
				for f in FACES:
					var n: Vector3i = f["n"]
					var nb := cell + n
					if world.get_block(nb.x, nb.y, nb.z) != VoxelWorld.AIR:
						continue
					if nb.y < 0:
						continue
					var u: Vector3i = f["u"]
					var v: Vector3i = f["v"]
					var o: Vector3i = f["o"]
					var base := color_for(b, n.y > 0, n.y < 0)
					var ao := [0.0, 0.0, 0.0, 0.0]
					var corners := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]
					for k in 4:
						var su: int = -1 if corners[k].x == 0 else 1
						var sv: int = -1 if corners[k].y == 0 else 1
						var s1 := _solid(world, nb + u * su)
						var s2 := _solid(world, nb + v * sv)
						var c := _solid(world, nb + u * su + v * sv)
						var level := 3 - (s1 + s2 + c)
						if s1 == 1 and s2 == 1:
							level = 0
						ao[k] = 0.55 + 0.15 * level
					var start := verts.size()
					for k in 4:
						var pos := Vector3(cell + o + u * corners[k].x + v * corners[k].y)
						verts.append(pos)
						norms.append(Vector3(n))
						var shade: float = f["shade"] * ao[k]
						cols.append(Color(base.r * shade, base.g * shade, base.b * shade, 1.0))
					if ao[0] + ao[2] > ao[1] + ao[3]:
						idx.append_array([start, start + 3, start + 1, start + 1, start + 3, start + 2])
					else:
						idx.append_array([start, start + 2, start + 1, start, start + 3, start + 2])
	var mesh := ArrayMesh.new()
	if verts.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
