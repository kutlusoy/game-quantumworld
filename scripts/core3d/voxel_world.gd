extends RefCounted

const W := 64
const D := 64
const H := 48
const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const SAND := 4
const CRYSTAL := 5
const WOOD := 6
const RUIN := 8
const FP := 1024

const TOWER_X := 40
const TOWER_Z := 24
const TOWER_PLATFORMS := 12
const CHAIN_GAP := 5
const CHAIN_ISLANDS := 3

var seed_value: int
var blocks := PackedByteArray()
var heights := PackedInt32Array()
var max_y := 0
var spawn := Vector3i(32, 0, 32)
var shards: Array = []

func _init(seed_value_: int = 0, flat_height: int = -1) -> void:
	seed_value = seed_value_
	blocks.resize(W * D * H)
	heights.resize(W * D)
	if flat_height >= 0:
		_generate_flat(flat_height)
		return
	_generate_terrain()
	_place_tower()
	_place_ruins()
	_place_chain()
	_place_terrain_shards()
	_finish()

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

func in_bounds(x: int, y: int, z: int) -> bool:
	return x >= 0 and z >= 0 and y >= 0 and x < W and z < D and y < H

func get_block(x: int, y: int, z: int) -> int:
	if not in_bounds(x, y, z):
		return AIR
	return blocks[(y * D + z) * W + x]

func set_block(x: int, y: int, z: int, b: int) -> void:
	if in_bounds(x, y, z):
		blocks[(y * D + z) * W + x] = b

func is_solid(x: int, y: int, z: int) -> bool:
	if x < 0 or z < 0 or x >= W or z >= D:
		return true
	return get_block(x, y, z) != AIR

func surface_y(x: int, z: int) -> int:
	for y in range(H - 1, -1, -1):
		if get_block(x, y, z) != AIR:
			return y + 1
	return 0

func shard_center(i: int) -> Vector3i:
	var s: Vector3i = shards[i]
	return s * FP + Vector3i(FP / 2, FP / 2, FP / 2)

func _fill_column(x: int, z: int, h: int) -> void:
	heights[z * W + x] = h
	for y in H:
		set_block(x, y, z, AIR)
	for y in h:
		var t := STONE
		if y == h - 1:
			t = GRASS if h >= 4 else SAND
		elif y >= h - 4:
			t = DIRT
		set_block(x, y, z, t)

func _generate_flat(h: int) -> void:
	for z in D:
		for x in W:
			_fill_column(x, z, h)
	spawn = Vector3i(32, h, 32)
	_finish()

func _generate_terrain() -> void:
	var cx := W / 2
	var cz := D / 2
	var r2 := 30 * 30
	for z in D:
		for x in W:
			var dx := x - cx
			var dz := z - cz
			var m := maxi(0, r2 - (dx * dx + dz * dz)) * 1024 / r2
			var n1 := noise(x, z, 12, seed_value)
			var n2 := noise(x, z, 5, seed_value + 7)
			var h := (4 * 255 + n1 * 8 + n2 * 3) * m / (255 * 1024)
			_fill_column(x, z, h)
	spawn = Vector3i(cx, heights[cz * W + cx], cz)

func _flatten(x0: int, z0: int, w: int, d: int, h: int) -> void:
	for z in range(z0, z0 + d):
		for x in range(x0, x0 + w):
			_fill_column(x, z, h)

func _max_height(x0: int, z0: int, w: int, d: int) -> int:
	var m := 0
	for z in range(z0, z0 + d):
		for x in range(x0, x0 + w):
			m = maxi(m, heights[z * W + x])
	return m

func _platform(x: int, y: int, z: int, size: int, b: int) -> void:
	for dz in size:
		for dx in size:
			set_block(x + dx, y, z + dz, b)

func _add_shard(x: int, y: int, z: int) -> void:
	shards.append(Vector3i(x, y, z))

const RING := [Vector2i(4, 0), Vector2i(3, 3), Vector2i(0, 4), Vector2i(-3, 3), Vector2i(-4, 0), Vector2i(-3, -3), Vector2i(0, -4), Vector2i(3, -3)]

func tower_platform(i: int) -> Vector3i:
	var hmax := _max_height(TOWER_X - 6, TOWER_Z - 6, 13, 13)
	var r: Vector2i = RING[i % 8]
	return Vector3i(TOWER_X + r.x - 1, hmax + 1 + i, TOWER_Z + r.y - 1)

func _place_tower() -> void:
	var first := tower_platform(0)
	for y in range(0, first.y):
		_platform(first.x, y, first.z, 2, WOOD)
	for i in TOWER_PLATFORMS:
		var p := tower_platform(i)
		_platform(p.x, p.y, p.z, 2, CRYSTAL)
		if i % 3 == 2:
			_add_shard(p.x, p.y + 1, p.z)
	var top := tower_platform(TOWER_PLATFORMS - 1)
	_add_shard(top.x, top.y + 2, top.z)

func chain_island(i: int) -> Vector3i:
	var top := tower_platform(TOWER_PLATFORMS - 1)
	return Vector3i(top.x, top.y, top.z - CHAIN_GAP - 3 - i * (CHAIN_GAP + 3))

func _place_chain() -> void:
	for i in CHAIN_ISLANDS:
		var p := chain_island(i)
		if p.z < 1:
			break
		_platform(p.x, p.y, p.z, 3, CRYSTAL)
		_add_shard(p.x + 1, p.y + 1, p.z + 1)

func _place_ruins() -> void:
	var x0 := 14
	var z0 := 38
	var hy := _max_height(x0, z0, 9, 9)
	_flatten(x0, z0, 9, 9, hy)
	for i in 9:
		for h in 3:
			set_block(x0 + i, hy + h, z0, RUIN)
			set_block(x0 + i, hy + h, z0 + 8, RUIN)
			set_block(x0, hy + h, z0 + i, RUIN)
			set_block(x0 + 8, hy + h, z0 + i, RUIN)
	for h in 3:
		set_block(x0 + 4, hy + h, z0 + 8, AIR)
	for dx in range(1, 8):
		for dz in range(1, 8):
			if (dx + dz) % 2 == 0 and dz < 4:
				set_block(x0 + dx, hy + 3, z0 + dz, RUIN)
	_add_shard(x0 + 2, hy, z0 + 2)
	_add_shard(x0 + 6, hy, z0 + 2)
	_add_shard(x0 + 4, hy, z0 + 6)

func _place_terrain_shards() -> void:
	var placed := 0
	var attempt := 0
	while placed < 40 and attempt < 3000:
		attempt += 1
		var x := hash3(attempt, 1, seed_value) % W
		var z := hash3(attempt, 2, seed_value) % D
		var h := heights[z * W + x]
		if h < 3:
			continue
		if get_block(x, h, z) != AIR or get_block(x, h + 1, z) != AIR:
			continue
		if get_block(x, h - 1, z) != GRASS:
			continue
		var ok := true
		for s in shards:
			var dx: int = s.x - x
			var dz: int = s.z - z
			if dx * dx + dz * dz < 25:
				ok = false
				break
		if not ok:
			continue
		_add_shard(x, h, z)
		placed += 1

func _finish() -> void:
	max_y = 0
	for y in range(H - 1, -1, -1):
		var any := false
		for i in W * D:
			if blocks[y * W * D + i] != AIR:
				any = true
				break
		if any:
			max_y = y
			break

func fingerprint() -> int:
	var h := 2166136261
	for v in blocks:
		h = ((h ^ v) * 16777619) & 0xFFFFFFFF
	return h
