extends RefCounted

const FP := 1024
const HALF_W := 300
const HEIGHT := 1840
const GRAVITY := 26
const MAX_FALL := 620
const RUN_SPEED := 125
const GROUND_ACCEL := 18
const GROUND_FRICTION := 22
const AIR_ACCEL := 10
const AIR_FRICTION := 2
const JUMP_VEL := 300
const DOUBLE_JUMP_VEL := 265
const RISE_CUT := 2
const COYOTE_TICKS := 6
const BUFFER_TICKS := 6
const DASH_SPEED := 300
const DASH_TICKS := 9
const DASH_COOLDOWN := 20
const DASH_EXIT_SPEED := 162
const GLIDE_FALL := 34
const VOID_Y := -20 * FP
const SHARD_RADIUS := 900

const BIT_JUMP := 1
const BIT_DASH := 2

var world
var px := 0
var py := 0
var pz := 0
var vx := 0
var vy := 0
var vz := 0
var grounded := false
var jumps_left := 1
var coyote := 0
var buffer := 0
var dash_ticks := 0
var dash_cd := 0
var dash_charges := 1
var dash_vx := 0
var dash_vz := 0
var gliding := false
var facing_x := 0
var facing_z := 100
var prev_bits := 0
var tick := 0
var collected := PackedByteArray()
var collected_count := 0
var can_double_jump := true
var can_dash := true
var can_glide := true

func _init(w) -> void:
	world = w
	collected.resize(w.shards.size())
	respawn()

func respawn() -> void:
	px = world.spawn.x * FP + FP / 2
	py = world.spawn.y * FP
	pz = world.spawn.z * FP + FP / 2
	vx = 0
	vy = 0
	vz = 0
	dash_ticks = 0
	gliding = false

func set_position(p: Vector3i) -> void:
	px = p.x
	py = p.y
	pz = p.z
	vx = 0
	vy = 0
	vz = 0
	grounded = false
	coyote = 0
	buffer = 0

static func fdiv(v: int) -> int:
	return floori(v / 1024.0)

static func isqrt(n: int) -> int:
	if n <= 0:
		return 0
	var x := int(sqrt(float(n)))
	while x * x > n:
		x -= 1
	while (x + 1) * (x + 1) <= n:
		x += 1
	return x

static func approach(v: int, target: int, accel: int, friction: int) -> int:
	var step := accel
	if absi(v) > absi(target) and (target == 0 or (v > 0) == (target > 0)):
		step = friction
	if v < target:
		return mini(v + step, target)
	return maxi(v - step, target)

func collides(x: int, y: int, z: int) -> bool:
	var x0 := fdiv(x - HALF_W)
	var x1 := fdiv(x + HALF_W - 1)
	var z0 := fdiv(z - HALF_W)
	var z1 := fdiv(z + HALF_W - 1)
	var y0 := fdiv(y)
	var y1 := fdiv(y + HEIGHT - 1)
	for by in range(y0, y1 + 1):
		for bz in range(z0, z1 + 1):
			for bx in range(x0, x1 + 1):
				if world.is_solid(bx, by, bz):
					return true
	return false

func _move_x(d: int) -> void:
	if d == 0:
		return
	var nx := px + d
	if not collides(nx, py, pz):
		px = nx
		return
	if d > 0:
		px = fdiv(nx + HALF_W - 1) * FP - HALF_W
	else:
		px = (fdiv(nx - HALF_W) + 1) * FP + HALF_W
	vx = 0

func _move_z(d: int) -> void:
	if d == 0:
		return
	var nz := pz + d
	if not collides(px, py, nz):
		pz = nz
		return
	if d > 0:
		pz = fdiv(nz + HALF_W - 1) * FP - HALF_W
	else:
		pz = (fdiv(nz - HALF_W) + 1) * FP + HALF_W
	vz = 0

func _move_y(d: int) -> void:
	if d == 0:
		return
	var ny := py + d
	if not collides(px, ny, pz):
		py = ny
		return
	if d > 0:
		py = fdiv(ny + HEIGHT - 1) * FP - HEIGHT
	else:
		py = (fdiv(ny) + 1) * FP
	vy = 0

func step(mx: int, mz: int, bits: int) -> Dictionary:
	var ev := {"collected": [], "respawned": false, "jumped": false, "double_jumped": false, "dashed": false, "landed": false, "glide_started": false}
	tick += 1
	var jump_held := (bits & BIT_JUMP) != 0
	var jump_pressed := jump_held and (prev_bits & BIT_JUMP) == 0
	var dash_pressed := (bits & BIT_DASH) != 0 and (prev_bits & BIT_DASH) == 0
	prev_bits = bits
	mx = clampi(mx, -100, 100)
	mz = clampi(mz, -100, 100)
	var mag := isqrt(mx * mx + mz * mz)
	var norm := maxi(mag, 100)
	var dvx := mx * RUN_SPEED / norm
	var dvz := mz * RUN_SPEED / norm
	if mag > 20:
		facing_x = mx
		facing_z = mz
	if dash_cd > 0:
		dash_cd -= 1
	if jump_pressed:
		buffer = BUFFER_TICKS
	elif buffer > 0:
		buffer -= 1
	if grounded:
		coyote = COYOTE_TICKS
	else:
		coyote = maxi(coyote - 1, 0)
	if not jump_held:
		gliding = false

	if buffer > 0 and coyote > 0:
		vy = JUMP_VEL
		buffer = 0
		coyote = 0
		grounded = false
		jumps_left = 1
		gliding = false
		ev["jumped"] = true
	elif jump_pressed and not grounded:
		if jumps_left > 0 and can_double_jump:
			vy = DOUBLE_JUMP_VEL
			jumps_left -= 1
			buffer = 0
			ev["double_jumped"] = true
		elif can_glide and jumps_left == 0 and vy <= 100:
			gliding = true
			ev["glide_started"] = true

	if dash_pressed and can_dash and dash_cd == 0 and dash_charges > 0 and dash_ticks == 0:
		var fx := facing_x
		var fz := facing_z
		var fm := isqrt(fx * fx + fz * fz)
		if fm == 0:
			fx = 0
			fz = 100
			fm = 100
		dash_vx = fx * DASH_SPEED / fm
		dash_vz = fz * DASH_SPEED / fm
		dash_ticks = DASH_TICKS
		dash_cd = DASH_COOLDOWN
		dash_charges -= 1
		gliding = false
		ev["dashed"] = true

	if dash_ticks > 0:
		vx = dash_vx
		vz = dash_vz
		vy = 0
		dash_ticks -= 1
		if dash_ticks == 0:
			vx = dash_vx * DASH_EXIT_SPEED / DASH_SPEED
			vz = dash_vz * DASH_EXIT_SPEED / DASH_SPEED
	else:
		var accel := GROUND_ACCEL if grounded else AIR_ACCEL
		var fric := GROUND_FRICTION if grounded else AIR_FRICTION
		if mag > 5:
			vx = approach(vx, dvx, accel, fric)
			vz = approach(vz, dvz, accel, fric)
		else:
			vx = approach(vx, 0, fric, fric)
			vz = approach(vz, 0, fric, fric)
		var g := GRAVITY
		if vy > 0 and not jump_held:
			g *= RISE_CUT
		vy -= g
		if gliding and vy < -GLIDE_FALL:
			vy = -GLIDE_FALL
		if vy < -MAX_FALL:
			vy = -MAX_FALL

	_move_x(vx)
	_move_z(vz)
	_move_y(vy)

	var was_grounded := grounded
	grounded = vy <= 0 and collides(px, py - 1, pz)
	if grounded:
		jumps_left = 1
		dash_charges = 1
		gliding = false
		if not was_grounded:
			ev["landed"] = true

	if py < VOID_Y:
		respawn()
		ev["respawned"] = true

	_collect(ev)
	return ev

func _collect(ev: Dictionary) -> void:
	var cx := px
	var cy := py + HEIGHT / 2
	var cz := pz
	var r2 := SHARD_RADIUS * SHARD_RADIUS
	for i in world.shards.size():
		if collected[i] != 0:
			continue
		var c: Vector3i = world.shard_center(i)
		var dx := c.x - cx
		var dy := c.y - cy
		var dz := c.z - cz
		if dx * dx + dy * dy + dz * dz < r2:
			collected[i] = 1
			collected_count += 1
			ev["collected"].append(i)

func fingerprint() -> int:
	var h := 2166136261
	for v in [px, py, pz, vx, vy, vz, tick, collected_count, int(grounded), jumps_left, dash_ticks, dash_cd, int(gliding)]:
		h = ((h ^ (v & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
	for v in collected:
		h = ((h ^ v) * 16777619) & 0xFFFFFFFF
	return h
