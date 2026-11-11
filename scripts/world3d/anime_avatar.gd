extends Node3D

const MeshKit = preload("res://scripts/world3d/mesh_kit.gd")

const HX := 0.108
const HY := 0.128
const HZ := 0.116
const HIP_Y := 0.935
const HEAD_Y := 1.63

static var light_dir := Vector3(0.38, 0.77, 0.5)

var params: Dictionary = {}
var body: Node3D
var head_node: Node3D
var hair_group: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var eye_mats: Array = []
var tri_count := 0
var _toon: ShaderMaterial
var _face: ShaderMaterial
var _hair: ShaderMaterial
var _cloth: ShaderMaterial
var _outline: ShaderMaterial
var _flat: StandardMaterial3D
var _phase := 0.0
var _time := 0.0
var _blink := 0.0
var _next_blink := 2.5
var _squash := 1.0
var _sway := Vector3.ZERO
var _rng := RandomNumberGenerator.new()

static func head_surface(x: float, y: float) -> Vector3:
	var py := clampf(y / HY, -0.999, 0.999)
	var jaw := pow(maxf(-py, 0.0), 1.5)
	var fx := 1.0 - 0.38 * jaw
	var fz := 1.0 - 0.15 * jaw
	var px := clampf(x / (HX * fx), -0.999, 0.999)
	var pz := sqrt(maxf(1.0 - px * px - py * py, 0.0))
	return Vector3(x, y, HZ * fz * pz)

static func head_normal(x: float, y: float) -> Vector3:
	var s := head_surface(x, y)
	return Vector3(s.x / (HX * HX), s.y / (HY * HY), s.z / (HZ * HZ)).normalized()

func build(p: Dictionary) -> void:
	params = p
	_rng.seed = int(p.get("seed", 1))
	_make_materials()
	body = Node3D.new()
	add_child(body)
	_build_torso()
	_build_legs()
	_build_arms()
	_build_head()

func _make_materials() -> void:
	_outline = ShaderMaterial.new()
	_outline.shader = load("res://shaders/outline.gdshader")
	_outline.set_shader_parameter("outline_color", params.get("outline", Color(0.07, 0.04, 0.12)))
	_toon = ShaderMaterial.new()
	_toon.shader = load("res://shaders/toon_character.gdshader")
	_toon.set_shader_parameter("light_dir", light_dir)
	_toon.next_pass = _outline
	_face = ShaderMaterial.new()
	_face.shader = load("res://shaders/toon_character.gdshader")
	_face.set_shader_parameter("light_dir", light_dir)
	_face.set_shader_parameter("shadow_tint", Color(0.97, 0.9, 0.96))
	_face.set_shader_parameter("rim_strength", 0.1)
	_face.next_pass = _outline
	_hair = ShaderMaterial.new()
	_hair.shader = load("res://shaders/hair_strand.gdshader")
	_hair.set_shader_parameter("light_dir", light_dir)
	_hair.set_shader_parameter("hl_color", params["hair_hl"])
	_cloth = ShaderMaterial.new()
	_cloth.shader = load("res://shaders/hair_strand.gdshader")
	_cloth.set_shader_parameter("light_dir", light_dir)
	var accent: Color = params["trim"]
	_cloth.set_shader_parameter("hl_color", accent.lightened(0.35))
	_flat = StandardMaterial3D.new()
	_flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flat.vertex_color_use_as_albedo = true
	_flat.cull_mode = BaseMaterial3D.CULL_DISABLED

func _node(parent: Node3D, mb, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build()
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	tri_count += mb.triangle_count()
	return mi

func _build_torso() -> void:
	var jacket: Color = params["jacket"]
	var trim: Color = params["trim"]
	var pants: Color = params["pants"]
	var skin: Color = params["skin"]
	var mb := MeshKit.new()
	mb.tube([Vector3(0, 0.99, 0), Vector3(0, 0.9, 0)], [Vector2(0.112, 0.082), Vector2(0.12, 0.09)], pants, 14)
	mb.tube(
		[Vector3(0, 1.44, 0), Vector3(0, 1.38, 0), Vector3(0, 1.26, 0), Vector3(0, 1.13, 0), Vector3(0, 1.0, 0)],
		[Vector2(0.075, 0.062), Vector2(0.158, 0.082), Vector2(0.125, 0.09), Vector2(0.1, 0.076), Vector2(0.118, 0.088)],
		jacket, 16)
	mb.tube([Vector3(0, 1.075, 0), Vector3(0, 1.05, 0)], [Vector2(0.106, 0.08), Vector2(0.106, 0.08)], trim, 16)
	mb.tube([Vector3(0, 1.47, 0), Vector3(0, 1.41, 0)], [Vector2(0.066, 0.058), Vector2(0.074, 0.066)], trim, 14)
	if "coat" in params["accessories"]:
		mb.tube([Vector3(0, 1.02, 0), Vector3(0, 0.8, 0), Vector3(0, 0.52, 0)],
			[Vector2(0.126, 0.096), Vector2(0.165, 0.12), Vector2(0.21, 0.14)], jacket.darkened(0.1), 18)
		mb.tube([Vector3(0, 0.54, 0), Vector3(0, 0.51, 0)], [Vector2(0.208, 0.139), Vector2(0.212, 0.142)], trim, 18)
	_node(body, mb, _toon)
	var neck := MeshKit.new()
	neck.tube([Vector3(0, 1.56, 0), Vector3(0, 1.45, 0)], [Vector2(0.036, 0.038), Vector2(0.04, 0.042)], skin, 10)
	_node(body, neck, _face)

func _build_legs() -> void:
	var pants: Color = params["pants"]
	var boots: Color = params["boots"]
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.075 * s, HIP_Y, 0)
		body.add_child(pivot)
		var mb := MeshKit.new()
		mb.tube(
			[Vector3(0, 0, 0), Vector3(0, -0.24, 0.004), Vector3(0, -0.47, -0.006), Vector3(0, -0.7, 0), Vector3(0, -0.84, 0)],
			[Vector2(0.074, 0.077), Vector2(0.066, 0.07), Vector2(0.048, 0.052), Vector2(0.039, 0.043), Vector2(0.036, 0.04)],
			pants, 12)
		mb.tube([Vector3(0, -0.66, 0), Vector3(0, -0.84, 0)], [Vector2(0.046, 0.05), Vector2(0.05, 0.055)], boots, 12)
		mb.ellipsoid(Vector3(0, -0.89, 0.04), Vector3(0.046, 0.034, 0.082), boots, 8, 14)
		_node(pivot, mb, _toon)
		if s < 0:
			leg_l = pivot
		else:
			leg_r = pivot

func _build_arms() -> void:
	var jacket: Color = params["jacket"]
	var trim: Color = params["trim"]
	var skin: Color = params["skin"]
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.186 * s, 1.375, 0)
		body.add_child(pivot)
		var mb := MeshKit.new()
		mb.tube(
			[Vector3(0, 0.0, 0), Vector3(0.012 * s, -0.15, 0), Vector3(0.03 * s, -0.3, 0.012), Vector3(0.044 * s, -0.42, 0.03)],
			[Vector2(0.05, 0.05), Vector2(0.043, 0.043), Vector2(0.037, 0.037), Vector2(0.032, 0.032)],
			jacket, 10)
		mb.tube([Vector3(0.04 * s, -0.395, 0.026), Vector3(0.046 * s, -0.435, 0.034)],
			[Vector2(0.036, 0.036), Vector2(0.038, 0.038)], trim, 10)
		mb.ellipsoid(Vector3(0.05 * s, -0.485, 0.04), Vector3(0.027, 0.04, 0.021), skin, 8, 12)
		_node(pivot, mb, _toon)
		if s < 0:
			arm_l = pivot
		else:
			arm_r = pivot

func _build_head() -> void:
	head_node = Node3D.new()
	head_node.position = Vector3(0, HEAD_Y, 0)
	body.add_child(head_node)
	var skin: Color = params["skin"]
	var mb := MeshKit.new()
	var jaw := func(u: Vector3) -> Vector3:
		var j := pow(maxf(-u.y, 0.0), 1.5)
		return Vector3(u.x * (1.0 - 0.38 * j), u.y, u.z * (1.0 - 0.15 * j))
	mb.ellipsoid(Vector3.ZERO, Vector3(HX, HY, HZ), skin, 20, 28, jaw)
	for s in [-1.0, 1.0]:
		mb.ellipsoid(Vector3(HX * 0.97 * s, -0.012, -0.004), Vector3(0.013, 0.026, 0.018), skin, 6, 10)
	_node(head_node, mb, _face)
	_build_face()
	hair_group = Node3D.new()
	head_node.add_child(hair_group)
	_build_hair()
	_build_accessories()

func _build_face() -> void:
	for s in [-1.0, 1.0]:
		var x: float = 0.05 * s
		var y: float = -0.006
		var surf := head_surface(x, y)
		var n := head_normal(x, y)
		var mi := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.084, 0.084)
		mi.mesh = quad
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/anime_eye.gdshader")
		m.set_shader_parameter("iris_top", params["eye_top"])
		m.set_shader_parameter("iris_bottom", params["eye_bottom"])
		m.set_shader_parameter("flip", s)
		mi.material_override = m
		mi.position = surf + n * 0.004
		mi.basis = Basis.looking_at(-n, Vector3.UP)
		head_node.add_child(mi)
		eye_mats.append(m)
		var brow := MeshKit.new()
		var bc: Color = params["brow"]
		var pts := []
		var ys := [0.062, 0.07, 0.058]
		var xs := [0.022, 0.056, 0.092]
		for i in 3:
			var sp := head_surface(xs[i] * s, ys[i])
			pts.append(sp + head_normal(xs[i] * s, ys[i]) * 0.004)
		brow.ribbon(pts, [0.009, 0.011, 0.004], Vector3(0, 0, 1), bc)
		_node(head_node, brow, _flat)
	var nose := MeshKit.new()
	var np := [head_surface(0.0, -0.036) + Vector3(0, 0, 0.002), head_surface(0.004, -0.05) + Vector3(0, 0, 0.004)]
	nose.ribbon(np, [0.004, 0.003], Vector3(0, 0, 1), Color(0.75, 0.45, 0.5))
	_node(head_node, nose, _flat)
	var mouth := MeshKit.new()
	var my := -0.079
	var offs := [0.0, -0.004, 0.0]
	var kind: String = params.get("mouth", "smile")
	if kind == "flat":
		offs = [0.0, 0.0, 0.0]
	elif kind == "smirk":
		offs = [-0.002, -0.004, 0.006]
	var mp := []
	for i in 3:
		var mx := (i - 1) * 0.018
		mp.append(head_surface(mx, my + offs[i]) + Vector3(0, 0, 0.004))
	mouth.ribbon(mp, [0.003, 0.0045, 0.003], Vector3(0, 0, 1), Color(0.6, 0.22, 0.32))
	_node(head_node, mouth, _flat)

func _head_dir_point(a: float, y: float, k: float) -> Vector3:
	return Vector3(sin(a) * HX * k, y, -cos(a) * HZ * k)

func _strand(mb, pts: Array, width: float, color: Color) -> void:
	var n := pts.size()
	var widths := []
	for i in n:
		var t := float(i) / float(n - 1)
		widths.append(width * pow(1.0 - t, 0.5) + 0.0015)
	var mid: Vector3 = pts[n / 2]
	var hint := Vector3(mid.x, mid.y * 0.3, mid.z)
	if hint.length() < 0.01:
		hint = Vector3(0, 1, 0)
	mb.ribbon(pts, widths, hint.normalized(), color)

func _build_hair() -> void:
	var color: Color = params["hair_color"]
	var style: String = params["hair_style"]
	var mb := MeshKit.new()
	var keep := func(p: Vector3) -> bool:
		if p.y < -0.075:
			return false
		if p.z > 0.0 and p.y < 0.065:
			return false
		if absf(p.x) > 0.095 and p.y < 0.0 and p.z > -0.04:
			return false
		return true
	var k := 1.075
	var spiky := style == "spiky"
	mb.ellipsoid(Vector3(0, 0.006, -0.006), Vector3(HX * k, HY * (1.04 if spiky else 1.09), HZ * k), color, 16, 26, Callable(), keep)
	var bang_n := 12 if not spiky else 8
	for i in bang_n:
		var t := float(i) / float(bang_n - 1)
		var x := lerpf(-0.092, 0.092, t)
		var edge := absf(t - 0.5) * 2.0
		var length := 0.06 + 0.055 * edge + _rng.randf() * 0.02
		if spiky:
			length += 0.02
		var sweep := (t - 0.5) * 0.05 + (0.012 if i % 2 == 0 else -0.01)
		var y0 := 0.105
		var s0 := head_surface(x, y0)
		var pts := [
			s0 * 1.04 + Vector3(0, 0.0, 0.004),
			Vector3(x * 1.02 + sweep * 0.3, y0 - length * 0.25, head_surface(x, y0 - length * 0.25).z * 1.05 + 0.012),
			Vector3(x * 1.04 + sweep * 0.7, y0 - length * 0.6, head_surface(x, 0.04).z * 1.06 + 0.02),
			Vector3(x * 1.06 + sweep, y0 - length, head_surface(x, 0.04).z * 1.04 + 0.018),
		]
		_strand(mb, pts, 0.052 if not spiky else 0.05, color)
	var side_len := 0.12
	var back_len := 0.0
	match style:
		"bob":
			side_len = 0.17
			back_len = 0.1
		"long":
			side_len = 0.4
			back_len = 0.55
		"ponytail":
			side_len = 0.14
			back_len = 0.0
		"spiky":
			side_len = 0.1
			back_len = 0.0
	for s in [-1.0, 1.0]:
		for j in 3:
			var off := j * 0.012
			var pts := [
				Vector3(s * (0.098 + off * 0.2), 0.07, 0.01 - off),
				Vector3(s * (0.112 + off * 0.3), 0.01, 0.026 - off),
				Vector3(s * (0.115 + off * 0.5), 0.0 - side_len * 0.5, 0.035 - off * 0.8),
				Vector3(s * (0.11 + off * 0.6), -side_len, 0.03 - off),
			]
			_strand(mb, pts, 0.055 - j * 0.008, color)
	if back_len > 0.0:
		var n := 15
		for i in n:
			var a := lerpf(-1.25, 1.25, float(i) / float(n - 1))
			var p0 := _head_dir_point(a, 0.09, 1.0)
			var l := back_len * (0.85 + _rng.randf() * 0.3)
			var pts := [
				p0,
				_head_dir_point(a, 0.0, 1.1),
				_head_dir_point(a, -l * 0.5, 1.2) + Vector3(0, 0, -0.01),
				_head_dir_point(a, -l, 1.18 + (0.1 if style == "long" else 0.0)) + Vector3(0, 0, -0.02),
			]
			_strand(mb, pts, 0.078, color)
	if style == "ponytail":
		for j in 4:
			var o := (j - 1.5) * 0.02
			var pts := [
				Vector3(o * 0.3, 0.085, -0.108),
				Vector3(o, 0.1, -0.17),
				Vector3(o * 1.6, 0.02, -0.235),
				Vector3(o * 2.0, -0.18, -0.24),
				Vector3(o * 2.4, -0.4, -0.2),
			]
			_strand(mb, pts, 0.075, color)
	if spiky:
		var n := 11
		for i in n:
			var a := TAU * float(i) / float(n) + _rng.randf() * 0.3
			var up := 0.6 + _rng.randf() * 0.7
			var dirv := Vector3(sin(a), up, -cos(a) * 0.9).normalized()
			var base := Vector3(sin(a) * HX * 0.7, 0.1 + _rng.randf() * 0.02, -cos(a) * HZ * 0.7)
			var tip := base + dirv * (0.11 + _rng.randf() * 0.05)
			var pts := [base, base.lerp(tip, 0.5) + Vector3(0, 0.01, 0), tip]
			_strand(mb, pts, 0.05, color)
	_node(hair_group, mb, _hair)

func _circle_path(cx: float, cy: float, z: float, r: float, n: int) -> Array:
	var pts := []
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		var px := cx + cos(a) * r
		var py := cy + sin(a) * r * 0.92
		pts.append(Vector3(px, py, head_surface(cx, cy).z + z))
	return pts

func _build_accessories() -> void:
	var acc: Array = params["accessories"]
	var accent: Color = params["accent"]
	if "headphones" in acc:
		var mb := MeshKit.new()
		var band := []
		for i in 11:
			var a := lerpf(-1.45, 1.45, float(i) / 10.0)
			band.append(Vector3(sin(a) * 0.128, cos(a) * 0.15 - 0.0, 0.0))
		var radii := []
		for i in 11:
			radii.append(Vector2(0.009, 0.009))
		mb.tube(band, radii, accent, 8)
		for s in [-1.0, 1.0]:
			mb.ellipsoid(Vector3(0.124 * s, -0.008, 0.0), Vector3(0.022, 0.042, 0.04), accent, 10, 14)
		_node(head_node, mb, _toon)
	if "glasses" in acc:
		var mb := MeshKit.new()
		var rim := Color(0.15, 0.12, 0.25)
		for s in [-1.0, 1.0]:
			var path := _circle_path(0.05 * s, -0.006, 0.012, 0.039, 18)
			var radii := []
			for i in path.size():
				radii.append(Vector2(0.0026, 0.0026))
			mb.tube(path, radii, rim, 6, false, false)
		var bridge := [Vector3(-0.012, -0.002, head_surface(0, -0.002).z + 0.02), Vector3(0.012, -0.002, head_surface(0, -0.002).z + 0.02)]
		mb.tube(bridge, [Vector2(0.003, 0.003), Vector2(0.003, 0.003)], rim, 6)
		_node(head_node, mb, _toon)
	if "goggles" in acc:
		var mb := MeshKit.new()
		var strap := []
		for i in 15:
			var a := lerpf(-2.0, 2.0, float(i) / 14.0)
			strap.append(Vector3(sin(a) * 0.112, 0.07, cos(a) * 0.117))
		var radii := []
		for i in 15:
			radii.append(Vector2(0.011, 0.011))
		mb.tube(strap, radii, accent.darkened(0.3), 8)
		for s in [-1.0, 1.0]:
			mb.ellipsoid(Vector3(0.042 * s, 0.092, 0.107), Vector3(0.033, 0.031, 0.02), accent, 10, 14)
			mb.ellipsoid(Vector3(0.042 * s, 0.092, 0.118), Vector3(0.024, 0.022, 0.008), Color(0.5, 0.9, 1.0), 8, 12)
		_node(head_node, mb, _toon)
	if "scarf" in acc:
		var mb := MeshKit.new()
		var ring := []
		for i in 17:
			var a := TAU * float(i) / 16.0
			ring.append(Vector3(sin(a) * 0.075, 1.455, cos(a) * 0.07))
		var radii := []
		for i in 17:
			radii.append(Vector2(0.026, 0.026))
		mb.tube(ring, radii, accent, 8, false, false)
		_node(body, mb, _toon)
		var tail := MeshKit.new()
		var tp := [Vector3(0.05, 1.44, -0.07), Vector3(0.07, 1.3, -0.1), Vector3(0.08, 1.1, -0.115), Vector3(0.075, 0.92, -0.1)]
		tail.ribbon(tp, [0.07, 0.075, 0.07, 0.04], Vector3(0, 0, 1), accent)
		_node(body, tail, _cloth)

func set_blink(amount: float) -> void:
	for m in eye_mats:
		m.set_shader_parameter("open", 1.0 - clampf(amount, 0.0, 1.0) * 0.92)

func update_pose(vel: Vector3, grounded: bool, gliding: bool, dashing: bool, facing: Vector2, delta: float) -> void:
	if facing.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.y), clampf(delta * 14.0, 0.0, 1.0))
	var speed := clampf(Vector2(vel.x, vel.z).length() / 0.12, 0.0, 1.4)
	_time += delta
	if grounded and speed > 0.05:
		_phase += delta * (5.0 + 9.0 * speed)
	var amp := 0.85 * minf(speed, 1.0)
	var ll := sin(_phase) * amp
	var lr := -ll
	var al := -ll * 0.9
	var ar := ll * 0.9
	var lean := clampf(speed * 0.22, 0.0, 0.3)
	var arm_out := 0.12
	var target_squash := 1.0
	if not grounded:
		ll = -0.6
		lr = 0.25
		al = -0.7
		ar = -0.7
		target_squash = 1.0 + clampf(vel.y * 2.5, -0.15, 0.15)
		arm_out = 0.35
	if gliding:
		lean = 1.15
		al = -0.2
		ar = -0.2
		arm_out = 1.35
		ll = 0.1
		lr = 0.1
	if dashing:
		lean = 0.9
		al = 0.9
		ar = 0.9
		ll = 0.5
		lr = -0.5
	if grounded and speed < 0.05:
		var breathe := sin(_time * 2.2) * 0.02
		al = breathe
		ar = -breathe
	var k := clampf(delta * 14.0, 0.0, 1.0)
	leg_l.rotation.x = lerpf(leg_l.rotation.x, ll, k)
	leg_r.rotation.x = lerpf(leg_r.rotation.x, lr, k)
	arm_l.rotation.x = lerpf(arm_l.rotation.x, al, k)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, ar, k)
	arm_l.rotation.z = lerpf(arm_l.rotation.z, -arm_out, k)
	arm_r.rotation.z = lerpf(arm_r.rotation.z, arm_out, k)
	_squash = lerpf(_squash, target_squash, clampf(delta * 16.0, 0.0, 1.0))
	body.scale = Vector3(1.0 / sqrt(_squash), _squash, 1.0 / sqrt(_squash))
	body.rotation.x = lerpf(body.rotation.x, lean, k)
	body.position.y = absf(sin(_phase)) * 0.03 * minf(speed, 1.0)
	var target_sway := Vector3(clampf(-vel.y * 4.0, -0.5, 0.5), 0.0, clampf(-vel.x * 3.0, -0.3, 0.3))
	_sway = _sway.lerp(target_sway, clampf(delta * 6.0, 0.0, 1.0))
	hair_group.rotation.x = _sway.x * 0.5 + speed * 0.12
	hair_group.rotation.z = _sway.z * 0.4
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 1.0
		_next_blink = 2.0 + _rng.randf() * 3.0
	_blink = maxf(_blink - delta * 9.0, 0.0)
	set_blink(_blink)
