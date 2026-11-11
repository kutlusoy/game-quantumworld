extends RefCounted

const FP := 1024
const W := 96
const D := 96
const SEA := 922
const VOID := -1073741824

const SPAWN_X := 50
const SPAWN_Z := 58
const SPAWN_BASE := 5
const TOWER_X := 62
const TOWER_Z := 40
const TOWER_BASE := 6
const TOWER_PLATFORMS := 12
const CHAIN_GAP := 5
const CHAIN_ISLANDS := 3
const RUIN_X := 28
const RUIN_Z := 64
const RUIN_BASE := 5

const RING := [Vector2i(4, 0), Vector2i(3, 3), Vector2i(0, 4), Vector2i(-3, 3), Vector2i(-4, 0), Vector2i(-3, -3), Vector2i(0, -4), Vector2i(3, -3)]

var seed_value: int
var hv := PackedInt32Array()
var box_min: Array = []
var box_max: Array = []
var box_kind: Array = []
var shards: Array = []
var ruin_shards: Array = []
var trees: Array = []
var spawn := Vector3i()

func _init(seed_value_: int = 0, flat_height: int = -1) -> void:
	seed_value = seed_value_
	hv.resize((W + 1) * (D + 1))
	if flat_height >= 0:
		for i in hv.size():
			hv[i] = flat_height * FP
		spawn = Vector3i(W / 2 * FP + FP / 2, flat_height * FP, D / 2 * FP + FP / 2)
		return
	_generate_terrain()
	_flatten(SPAWN_X, SPAWN_Z, 4, 9, SPAWN_BASE * FP)
	_flatten(TOWER_X, TOWER_Z, 8, 14, TOWER_BASE * FP)
	_flatten(RUIN_X, RUIN_Z, 7, 11, RUIN_BASE * FP)
	spawn = Vector3i(SPAWN_X * FP + FP / 2, SPAWN_BASE * FP, SPAWN_Z * FP + FP / 2)
	_place_tower()
	_place_chain()
	_place_ruins()
	_place_terrain_shards()
	_place_trees()

static func hash3(x: int, z: int, s: int) -> int:
	var h := (x * 374761393 + z * 668265263 + s * 1274126177) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return (h ^ (h >> 16)) & 0xFFFFFFFF

static func noise(x: int, z: int, cell: int, s: int) -> int:
	var gx := x / cell
	var gz := z / cell
	var fx := (x % cell) * 1024 / cell
	var fz := (z % cell) * 1024 / cell
	var u := fx * fx * (3 * 1024 - 2 * fx) / (1024 * 1024)
	var v := fz * fz * (3 * 1024 - 2 * fz) / (1024 * 1024)
	var a := hash3(gx, gz, s) & 255
	var b := hash3(gx + 1, gz, s) & 255
	var c := hash3(gx, gz + 1, s) & 255
	var d := hash3(gx + 1, gz + 1, s) & 255
	var top := a + (b - a) * u / 1024
	var bot := c + (d - c) * u / 1024
	return top + (bot - top) * v / 1024

func vidx(x: int, z: int) -> int:
	return z * (W + 1) + x

func vheight(x: int, z: int) -> int:
	return hv[vidx(clampi(x, 0, W), clampi(z, 0, D))]

func height_at(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= W * FP or z >= D * FP:
		return VOID
	var cx := x >> 10
	var cz := z >> 10
	var fx := x & 1023
	var fz := z & 1023
	var i := cz * (W + 1) + cx
	var h00 := hv[i]
	var h10 := hv[i + 1]
	var h01 := hv[i + W + 1]
	var h11 := hv[i + W + 2]
	if fx >= fz:
		return h00 + ((h10 - h00) * fx + (h11 - h10) * fz) / 1024
	return h00 + ((h01 - h00) * fz + (h11 - h01) * fx) / 1024

func ground_at(x: int, z: int, r: int) -> int:
	var h := height_at(x, z)
	h = maxi(h, height_at(x + r, z))
	h = maxi(h, height_at(x - r, z))
	h = maxi(h, height_at(x, z + r))
	h = maxi(h, height_at(x, z - r))
	return h

func shard_center(i: int) -> Vector3i:
	return shards[i]

func add_box(bmin: Vector3i, bmax: Vector3i, kind: String) -> void:
	box_min.append(bmin)
	box_max.append(bmax)
	box_kind.append(kind)

func _generate_terrain() -> void:
	var cx := W / 2
	var cz := D / 2
	var r2 := 44 * 44
	for vz in D + 1:
		for vx in W + 1:
			var dx := vx - cx
			var dz := vz - cz
			var m := maxi(0, r2 - (dx * dx + dz * dz)) * 1024 / r2
			m = m * m / 1024
			var n1 := noise(vx, vz, 26, seed_value)
			var n2 := noise(vx, vz, 12, seed_value + 7)
			var n3 := noise(vx, vz, 6, seed_value + 13)
			var land := (n1 * 7 + n2 * 4 + n3 * 2) * FP / 255
			var t := clampi((n2 - 140) * 1024 / 24, 0, 1024)
			var sm := t * t * (3 * 1024 - 2 * t) / (1024 * 1024)
			land += sm * 4 * FP / 1024
			hv[vidx(vx, vz)] = (land + 2 * FP) * m / 1024

func _flatten(cx: int, cz: int, r_in: int, r_out: int, target: int) -> void:
	for vz in range(maxi(cz - r_out, 0), mini(cz + r_out, D) + 1):
		for vx in range(maxi(cx - r_out, 0), mini(cx + r_out, W) + 1):
			var dx := vx - cx
			var dz := vz - cz
			var dist := int(sqrt(float(dx * dx + dz * dz)) * 1024.0)
			var inner := r_in * 1024
			var outer := r_out * 1024
			if dist >= outer:
				continue
			var w := 1024
			if dist > inner:
				var t := (outer - dist) * 1024 / (outer - inner)
				w = t * t * (3 * 1024 - 2 * t) / (1024 * 1024)
			var i := vidx(vx, vz)
			hv[i] = hv[i] + (target - hv[i]) * w / 1024

func tower_platform(i: int) -> Vector3i:
	var r: Vector2i = RING[i % 8]
	return Vector3i(TOWER_X + r.x - 1, TOWER_BASE + i, TOWER_Z + r.y - 1)

func chain_island(i: int) -> Vector3i:
	var top := tower_platform(TOWER_PLATFORMS - 1)
	return Vector3i(top.x, top.y, top.z - CHAIN_GAP - 3 - i * (CHAIN_GAP + 3))

func _block_box(p: Vector3i, size: Vector3i, kind: String) -> void:
	add_box(p * FP, (p + size) * FP, kind)

func _add_shard_at_block(x: int, y: int, z: int) -> void:
	shards.append(Vector3i(x * FP + FP / 2, y * FP + FP / 2, z * FP + FP / 2))

func _place_tower() -> void:
	for i in TOWER_PLATFORMS:
		var p := tower_platform(i)
		_block_box(p, Vector3i(2, 1, 2), "crystal")
		if i % 3 == 2:
			_add_shard_at_block(p.x, p.y + 1, p.z)
	var top := tower_platform(TOWER_PLATFORMS - 1)
	_add_shard_at_block(top.x, top.y + 2, top.z)

func _place_chain() -> void:
	for i in CHAIN_ISLANDS:
		var p := chain_island(i)
		if p.z < 1:
			break
		_block_box(p, Vector3i(3, 1, 3), "crystal")
		_add_shard_at_block(p.x + 1, p.y + 1, p.z + 1)

func _place_ruins() -> void:
	var x0 := RUIN_X - 4
	var z0 := RUIN_Z - 4
	var y0 := RUIN_BASE
	_block_box(Vector3i(x0, y0, z0), Vector3i(9, 3, 1), "ruin")
	_block_box(Vector3i(x0, y0, z0 + 8), Vector3i(4, 3, 1), "ruin")
	_block_box(Vector3i(x0 + 5, y0, z0 + 8), Vector3i(4, 3, 1), "ruin")
	_block_box(Vector3i(x0, y0, z0 + 1), Vector3i(1, 3, 7), "ruin")
	_block_box(Vector3i(x0 + 8, y0, z0 + 1), Vector3i(1, 3, 7), "ruin")
	_block_box(Vector3i(x0 + 1, y0 + 3, z0 + 1), Vector3i(3, 1, 3), "ruin")
	_block_box(Vector3i(x0 + 5, y0 + 3, z0 + 1), Vector3i(3, 1, 3), "ruin")
	for sp in [Vector3i(x0 + 2, y0, z0 + 3), Vector3i(x0 + 6, y0, z0 + 3), Vector3i(x0 + 4, y0, z0 + 6)]:
		ruin_shards.append(shards.size())
		_add_shard_at_block(sp.x, sp.y, sp.z)

func _near_set_piece(x: int, z: int) -> bool:
	for c in [Vector2i(SPAWN_X, SPAWN_Z), Vector2i(TOWER_X, TOWER_Z), Vector2i(RUIN_X, RUIN_Z)]:
		var dx: int = x - c.x
		var dz: int = z - c.y
		if dx * dx + dz * dz < 100:
			return true
	return false

func _place_terrain_shards() -> void:
	var placed := 0
	var attempt := 0
	while placed < 40 and attempt < 4000:
		attempt += 1
		var x := 4 + hash3(attempt, 1, seed_value) % (W - 8)
		var z := 4 + hash3(attempt, 2, seed_value) % (D - 8)
		var h := height_at(x * FP + FP / 2, z * FP + FP / 2)
		if h < SEA + FP + FP / 2:
			continue
		if _near_set_piece(x, z):
			continue
		var steep := absi(vheight(x + 1, z) - vheight(x - 1, z)) + absi(vheight(x, z + 1) - vheight(x, z - 1))
		if steep > 2 * FP:
			continue
		var ok := true
		for s in shards:
			var dx: int = s.x / FP - x
			var dz: int = s.z / FP - z
			if dx * dx + dz * dz < 36:
				ok = false
				break
		if not ok:
			continue
		shards.append(Vector3i(x * FP + FP / 2, h + 900, z * FP + FP / 2))
		placed += 1

func _place_trees() -> void:
	var attempt := 0
	while trees.size() < 70 and attempt < 4000:
		attempt += 1
		var x := 3 + hash3(attempt, 11, seed_value) % (W - 6)
		var z := 3 + hash3(attempt, 12, seed_value) % (D - 6)
		var h := height_at(x * FP + FP / 2, z * FP + FP / 2)
		if h < 2 * FP + FP / 2 or h > 12 * FP:
			continue
		if _near_set_piece(x, z):
			continue
		var steep := absi(vheight(x + 1, z) - vheight(x - 1, z)) + absi(vheight(x, z + 1) - vheight(x, z - 1))
		if steep > 2 * FP:
			continue
		var ok := true
		for t in trees:
			var dx: int = t.x / FP - x
			var dz: int = t.z / FP - z
			if dx * dx + dz * dz < 16:
				ok = false
				break
		if ok:
			for s in shards:
				var dx2: int = s.x / FP - x
				var dz2: int = s.z / FP - z
				if dx2 * dx2 + dz2 * dz2 < 9:
					ok = false
					break
		if ok:
			trees.append(Vector3i(x * FP + FP / 2, h, z * FP + FP / 2))

func fingerprint() -> int:
	var h := 2166136261
	for v in hv:
		h = ((h ^ (v & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
	for i in box_min.size():
		for v in [box_min[i].x, box_min[i].y, box_min[i].z, box_max[i].x, box_max[i].y, box_max[i].z]:
			h = ((h ^ (v & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
	return h
