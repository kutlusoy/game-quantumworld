extends Node3D

const MeshKit = preload("res://scripts/world3d/mesh_kit.gd")

const HX := 0.108
const HY := 0.128
const HZ := 0.116

static var light_dir := Vector3(0.38, 0.77, 0.5)

var params: Dictionary = {}
var gender := "female"
var body: Node3D
var hips: Node3D
var head_node: Node3D
var hair_group: Node3D
var eye_mats: Array = []
var tri_count := 0
var _jaw := 0.36
var _d: Dictionary = {}
var _j: Dictionary = {}
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
var _emote := ""
var _emote_t := 0.0
var _emote_dur := 0.0
var _body_y := 0.0
var _spin := 0.0
var _happy := 0.0
var _idle_t := 0.0
var _next_fidget := 8.0
var auto_emotes := true

func _p(key: String, default: Variant) -> Variant:
	return params.get(key, default)

func hs(x: float, y: float) -> Vector3:
	var py := clampf(y / HY, -0.999, 0.999)
	var jaw := pow(maxf(-py, 0.0), 1.5)
	var fx := 1.0 - _jaw * jaw
	var fz := 1.0 - 0.15 * jaw
	var px := clampf(x / (HX * fx), -0.999, 0.999)
	var pz := sqrt(maxf(1.0 - px * px - py * py, 0.0))
	return Vector3(x, y, HZ * fz * pz)

func hn(x: float, y: float) -> Vector3:
	var s := hs(x, y)
	return Vector3(s.x / (HX * HX), s.y / (HY * HY), s.z / (HZ * HZ)).normalized()

func build(p: Dictionary) -> void:
	params = p
	gender = _p("gender", "female")
	_jaw = float(_p("jaw", 0.25 if gender == "male" else 0.36))
	_rng.seed = int(_p("seed", 1))
	_make_dims()
	_make_materials()
	body = Node3D.new()
	add_child(body)
	hips = Node3D.new()
	hips.position = Vector3(0, _d["hip_y"], 0)
	body.add_child(hips)
	_j["hips"] = hips
	_build_pelvis()
	_build_legs()
	_build_upper_body()

func _make_dims() -> void:
	var m := gender == "male"
	var s := 1.045 if m else 1.0
	var muscle := float(_p("muscle", 0.6))
	var curve := float(_p("curve", 0.5))
	_d = {
		"s": s, "m": m, "muscle": muscle, "curve": curve,
		"thigh": 0.42 * s, "shin": 0.40 * s,
		"hip_y": (0.82 * s) + 0.085,
		"hip_x": 0.088 if m else 0.082,
		"spine": 0.10 * s, "chest": 0.17 * s,
		"sh_x": (0.19 + 0.02 * muscle) if m else 0.158,
		"sh_up": 0.17 * s, "neck_up": 0.2 * s, "neck_len": 0.085 * s,
		"ua": 0.27 * s, "fa": 0.25 * s,
	}

func _make_materials() -> void:
	_outline = ShaderMaterial.new()
	_outline.shader = load("res://shaders/outline.gdshader")
	_outline.set_shader_parameter("outline_color", _p("outline", Color(0.07, 0.04, 0.12)))
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

func _pivot(parent: Node3D, pos: Vector3, key: String) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	_j[key] = n
	return n

func _tube_ys(mb, ys: Array, rs: Array, color: Color, segs: int = 12) -> void:
	var pts := []
	for y in ys:
		pts.append(Vector3(0, y, 0))
	mb.tube(pts, rs, color, segs)

func _lerp_r(ys: Array, rs: Array, y: float) -> Vector2:
	for i in ys.size() - 1:
		if y <= ys[i] and y >= ys[i + 1]:
			var t: float = (ys[i] - y) / maxf(ys[i] - ys[i + 1], 0.00001)
			return (rs[i] as Vector2).lerp(rs[i + 1], t)
	return rs[rs.size() - 1]

func _tube_split(mb, ys: Array, rs: Array, split_y: float, top_color: Color, bottom_color: Color, segs: int = 12) -> void:
	var ay := []
	var ar := []
	var by := []
	var br := []
	for i in ys.size():
		if ys[i] > split_y:
			ay.append(ys[i])
			ar.append(rs[i])
		elif ys[i] < split_y:
			by.append(ys[i])
			br.append(rs[i])
	var sr := _lerp_r(ys, rs, split_y)
	ay.append(split_y)
	ar.append(sr)
	by.push_front(split_y)
	br.push_front(sr)
	if ay.size() >= 2:
		_tube_ys(mb, ay, ar, top_color, segs)
	if by.size() >= 2:
		_tube_ys(mb, by, br, bottom_color, segs)

func _build_pelvis() -> void:
	var m: bool = _d["m"]
	var curve: float = _d["curve"]
	var pants: Color = params["pants"]
	var trim: Color = params["trim"]
	var hip_r := 0.112 + 0.016 * curve if not m else 0.116
	var mb := MeshKit.new()
	_tube_ys(mb, [0.07, 0.01, -0.04, -0.11],
		[Vector2(hip_r * 0.86, 0.074), Vector2(hip_r, 0.088 + (0.006 * curve if not m else 0.0)), Vector2(hip_r * 0.98, 0.088), Vector2(hip_r * 0.82, 0.07)],
		pants, 16)
	_tube_ys(mb, [0.075, 0.05], [Vector2(hip_r * 0.88, 0.076), Vector2(hip_r * 0.9, 0.078)], trim, 16)
	_node(hips, mb, _toon)

func _build_legs() -> void:
	var s: float = _d["s"]
	var m: bool = _d["m"]
	var th: float = _d["thigh"]
	var sh: float = _d["shin"]
	var skin: Color = params["skin"]
	var pants: Color = params["pants"]
	var boots: Color = params["boots"]
	var shorts: bool = _p("legwear", "pants") == "shorts"
	var mu: float = _d["muscle"]
	var big := 1.0 + (0.06 * mu if m else 0.0)
	for side in [-1.0, 1.0]:
		var tag := "n" if side < 0 else "p"
		var thigh := _pivot(hips, Vector3(side * _d["hip_x"], 0, 0), "thigh_" + tag)
		var mb := MeshKit.new()
		mb.ellipsoid(Vector3.ZERO, Vector3(0.078, 0.07, 0.08) * big, pants, 10, 14)
		var ys := [0.0, -th * 0.3, -th * 0.65, -th]
		var rs := [Vector2(0.077, 0.081) * big, Vector2(0.071, 0.076) * big, Vector2(0.059, 0.063) * big, Vector2(0.05, 0.054) * big]
		if shorts:
			_tube_split(mb, ys, rs, -th * 0.55, pants, skin, 12)
		else:
			_tube_ys(mb, ys, rs, pants, 12)
		_node(thigh, mb, _toon)
		var knee := _pivot(thigh, Vector3(0, -th, 0), "knee_" + tag)
		var kb := MeshKit.new()
		var kcol := skin if shorts else pants
		kb.ellipsoid(Vector3.ZERO, Vector3(0.05, 0.05, 0.052) * big, kcol, 8, 12)
		var sys := [0.0, -sh * 0.28, -sh * 0.6, -sh]
		var srs := [Vector2(0.049, 0.053) * big, Vector2(0.053, 0.058) * big, Vector2(0.04, 0.043), Vector2(0.032, 0.036)]
		_tube_split(kb, sys, srs, -sh * 0.5, kcol, boots, 12)
		_node(knee, kb, _toon)
		var ankle := _pivot(knee, Vector3(0, -sh, 0), "ankle_" + tag)
		var fb := MeshKit.new()
		fb.ellipsoid(Vector3(0, -0.045, 0.045), Vector3(0.044, 0.04, 0.108), boots, 10, 14)
		fb.ellipsoid(Vector3(0, -0.01, -0.01), Vector3(0.04, 0.045, 0.045), boots, 8, 12)
		_node(ankle, fb, _toon)

func _build_upper_body() -> void:
	var m: bool = _d["m"]
	var s: float = _d["s"]
	var mu: float = _d["muscle"]
	var curve: float = _d["curve"]
	var jacket: Color = params["jacket"]
	var trim: Color = params["trim"]
	var skin: Color = params["skin"]
	var spine := _pivot(hips, Vector3(0, _d["spine"], 0), "spine")
	var wb := MeshKit.new()
	var wr: Array
	if m:
		wr = [Vector2(0.112, 0.08), Vector2(0.108, 0.078), Vector2(0.12, 0.086), Vector2(0.134, 0.092)]
	else:
		wr = [Vector2(0.104, 0.076), Vector2(0.088 - 0.01 * curve, 0.066), Vector2(0.098, 0.074), Vector2(0.114, 0.084)]
	_tube_ys(wb, [-0.07, 0.0, 0.08, 0.16 * s], wr, jacket, 16)
	_tube_ys(wb, [-0.01, -0.035], [Vector2(wr[1].x + 0.004, wr[1].y + 0.004), Vector2(wr[1].x + 0.006, wr[1].y + 0.006)], trim, 16)
	if "coat" in params["accessories"]:
		_tube_ys(wb, [-0.04, -0.2, -0.42, -0.62], [Vector2(0.12, 0.092), Vector2(0.15, 0.11), Vector2(0.19, 0.125), Vector2(0.21, 0.135)], jacket.darkened(0.1), 18)
		_tube_ys(wb, [-0.6, -0.625], [Vector2(0.209, 0.134), Vector2(0.213, 0.138)], trim, 18)
	_node(spine, wb, _toon)
	var chest := _pivot(spine, Vector3(0, _d["chest"], 0), "chest")
	var cb := MeshKit.new()
	var cr: Array
	if m:
		var w := 0.03 * mu
		cr = [Vector2(0.13, 0.092), Vector2(0.14 + w, 0.1 + 0.01 * mu), Vector2(0.165 + w, 0.094), Vector2(0.14, 0.078), Vector2(0.058, 0.052)]
	else:
		cr = [Vector2(0.115, 0.086), Vector2(0.12, 0.094), Vector2(0.138, 0.088), Vector2(0.118, 0.074), Vector2(0.052, 0.048)]
	_tube_ys(cb, [-0.02, 0.05, 0.12, 0.17 * s, 0.205 * s], cr, jacket, 18)
	if m:
		for sd in [-1.0, 1.0]:
			cb.ellipsoid(Vector3(0.06 * sd, 0.075, 0.07), Vector3(0.06 + 0.012 * mu, 0.048, 0.04), jacket, 8, 12)
	else:
		var b := 0.034 + 0.014 * curve
		for sd in [-1.0, 1.0]:
			cb.ellipsoid(Vector3(0.05 * sd, 0.07, 0.066), Vector3(b, b * 0.95, b * 0.95), jacket, 8, 12)
	_tube_ys(cb, [0.205 * s, 0.17 * s], [Vector2(0.062, 0.058), Vector2(0.072, 0.066)], trim, 14)
	_node(chest, cb, _toon)
	for side in [-1.0, 1.0]:
		_build_arm(chest, side)
	var neck := _pivot(chest, Vector3(0, _d["neck_up"], 0), "neck")
	var nb := MeshKit.new()
	var nr := 0.047 if m else 0.034
	_tube_ys(nb, [-0.02, 0.0, _d["neck_len"] + 0.03], [Vector2(nr * 1.15, nr * 1.15), Vector2(nr * 1.1, nr * 1.1), Vector2(nr, nr)], skin, 12)
	_node(neck, nb, _face)
	var head := _pivot(neck, Vector3(0, _d["neck_len"], 0), "head")
	head_node = Node3D.new()
	head_node.position = Vector3(0, 0.118, 0)
	head.add_child(head_node)
	_build_head()

func _build_arm(chest: Node3D, side: float) -> void:
	var m: bool = _d["m"]
	var mu: float = _d["muscle"]
	var ua: float = _d["ua"]
	var fa: float = _d["fa"]
	var jacket: Color = params["jacket"]
	var trim: Color = params["trim"]
	var skin: Color = params["skin"]
	var tag := "n" if side < 0 else "p"
	var sleeves: String = _p("sleeves", "long")
	var k := 1.0 + (0.28 * mu if m else 0.0)
	var shoulder := _pivot(chest, Vector3(side * _d["sh_x"], _d["sh_up"], 0), "shoulder_" + tag)
	var mb := MeshKit.new()
	var jc := jacket if sleeves != "none" else skin
	var dr: Vector3 = Vector3(0.038, 0.042, 0.038)
	if m:
		dr = Vector3(0.052, 0.056, 0.05) * (1.0 + 0.15 * mu)
	mb.ellipsoid(Vector3(0, -0.01, 0), dr, jc, 10, 14)
	var uys := [0.0, -ua * 0.3, -ua * 0.62, -ua]
	var urs: Array
	if m:
		urs = [Vector2(0.052, 0.052) * k, Vector2(0.056, 0.058) * k, Vector2(0.047, 0.047) * k, Vector2(0.04, 0.04)]
	else:
		urs = [Vector2(0.04, 0.04), Vector2(0.037, 0.037), Vector2(0.032, 0.032), Vector2(0.03, 0.03)]
	if sleeves == "short":
		_tube_split(mb, uys, urs, -ua * 0.42, jacket, skin, 12)
	else:
		_tube_ys(mb, uys, urs, jc, 12)
	_node(shoulder, mb, _toon)
	var elbow := _pivot(shoulder, Vector3(0, -ua, 0), "elbow_" + tag)
	var eb := MeshKit.new()
	var ec := jacket if sleeves == "long" else skin
	eb.ellipsoid(Vector3.ZERO, Vector3(0.034, 0.034, 0.034) * (1.0 + (0.2 * mu if m else 0.0)), ec, 8, 12)
	var fys := [0.0, -fa * 0.3, -fa * 0.7, -fa]
	var frs: Array
	if m:
		frs = [Vector2(0.04, 0.04) * k, Vector2(0.044, 0.042) * k, Vector2(0.032, 0.03), Vector2(0.026, 0.024)]
	else:
		frs = [Vector2(0.03, 0.03), Vector2(0.03, 0.028), Vector2(0.023, 0.021), Vector2(0.02, 0.018)]
	_tube_ys(eb, fys, frs, ec, 12)
	if sleeves == "long":
		_tube_ys(eb, [-fa + 0.045, -fa + 0.01], [Vector2(0.026, 0.026) * (1.0 + (0.4 * mu if m else 0.0)), Vector2(0.028, 0.028) * (1.0 + (0.4 * mu if m else 0.0))], trim, 12)
	_node(elbow, eb, _toon)
	var wrist := _pivot(elbow, Vector3(0, -fa, 0), "wrist_" + tag)
	var hb := MeshKit.new()
	var hsz := 1.18 if m else 1.0
	hb.ellipsoid(Vector3(0, -0.05, 0.004), Vector3(0.026, 0.044, 0.02) * hsz, skin, 8, 12)
	hb.ellipsoid(Vector3(0.016 * side, -0.035, 0.012), Vector3(0.011, 0.025, 0.011) * hsz, skin, 6, 8)
	_node(wrist, hb, _toon)

func _build_head() -> void:
	var skin: Color = params["skin"]
	var mb := MeshKit.new()
	var jt := _jaw
	var jaw := func(u: Vector3) -> Vector3:
		var j := pow(maxf(-u.y, 0.0), 1.5)
		return Vector3(u.x * (1.0 - jt * j), u.y, u.z * (1.0 - 0.15 * j))
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
	var esz: float = float(_p("eye_size", 0.082 if gender == "female" else 0.074))
	var brow_w: float = float(_p("brow_w", 0.009 if gender == "female" else 0.014))
	for s in [-1.0, 1.0]:
		var x: float = 0.05 * s
		var y: float = -0.006
		var surf := hs(x, y)
		var n := hn(x, y)
		var mi := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(esz, esz)
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
		var ys := [0.062, 0.07, 0.058] if gender == "female" else [0.058, 0.066, 0.058]
		var xs := [0.022, 0.056, 0.092]
		for i in 3:
			var sp := hs(xs[i] * s, ys[i])
			pts.append(sp + hn(xs[i] * s, ys[i]) * 0.004)
		brow.ribbon(pts, [brow_w, brow_w * 1.2, brow_w * 0.45], Vector3(0, 0, 1), bc)
		_node(head_node, brow, _flat)
	var nose := MeshKit.new()
	var np := [hs(0.0, -0.036) + Vector3(0, 0, 0.002), hs(0.004, -0.05) + Vector3(0, 0, 0.004)]
	nose.ribbon(np, [0.004, 0.003], Vector3(0, 0, 1), Color(0.75, 0.45, 0.5))
	_node(head_node, nose, _flat)
	var mouth := MeshKit.new()
	var my := -0.079
	var offs := [0.0, -0.004, 0.0]
	var kind: String = _p("mouth", "smile")
	if kind == "flat":
		offs = [0.0, 0.0, 0.0]
	elif kind == "smirk":
		offs = [-0.002, -0.004, 0.006]
	var mp := []
	for i in 3:
		var mx := (i - 1) * 0.018
		mp.append(hs(mx, my + offs[i]) + Vector3(0, 0, 0.004))
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
		var s0 := hs(x, y0)
		var pts := [
			s0 * 1.04 + Vector3(0, 0.0, 0.004),
			Vector3(x * 1.02 + sweep * 0.3, y0 - length * 0.25, hs(x, y0 - length * 0.25).z * 1.05 + 0.012),
			Vector3(x * 1.04 + sweep * 0.7, y0 - length * 0.6, hs(x, 0.04).z * 1.06 + 0.02),
			Vector3(x * 1.06 + sweep, y0 - length, hs(x, 0.04).z * 1.04 + 0.018),
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
		pts.append(Vector3(px, py, hs(cx, cy).z + z))
	return pts

func _build_accessories() -> void:
	var acc: Array = params["accessories"]
	var accent: Color = params["accent"]
	if "headphones" in acc:
		var mb := MeshKit.new()
		var band := []
		for i in 11:
			var a := lerpf(-1.45, 1.45, float(i) / 10.0)
			band.append(Vector3(sin(a) * 0.128, cos(a) * 0.15, 0.0))
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
		var bridge := [Vector3(-0.012, -0.002, hs(0, -0.002).z + 0.02), Vector3(0.012, -0.002, hs(0, -0.002).z + 0.02)]
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
			ring.append(Vector3(sin(a) * 0.08, 0.0, cos(a) * 0.075))
		var radii := []
		for i in 17:
			radii.append(Vector2(0.026, 0.026))
		mb.tube(ring, radii, accent, 8, false, false)
		_node(_j["neck"], mb, _toon)
		var tail := MeshKit.new()
		var tp := [Vector3(0.05, -0.01, -0.075), Vector3(0.07, -0.15, -0.105), Vector3(0.08, -0.35, -0.12), Vector3(0.075, -0.52, -0.105)]
		tail.ribbon(tp, [0.07, 0.075, 0.07, 0.04], Vector3(0, 0, 1), accent)
		_node(_j["chest"], tail, _cloth)

func set_blink(amount: float) -> void:
	for m in eye_mats:
		m.set_shader_parameter("open", 1.0 - clampf(amount, 0.0, 1.0) * 0.92)

func set_happy(w: float) -> void:
	_happy = w
	for m in eye_mats:
		m.set_shader_parameter("happy", w)

func emotes() -> Array:
	if gender == "female":
		return ["pirouette", "twirl_jump", "cheer", "wave"]
	return ["flex", "fist_pump", "cheer", "wave"]

func happy() -> void:
	play_emote(emotes()[0] if _rng.randf() < 0.6 else emotes()[_rng.randi() % emotes().size()])

func play_emote(name: String) -> void:
	var durs := {"pirouette": 2.1, "twirl_jump": 1.3, "cheer": 1.5, "wave": 2.2, "flex": 1.9, "fist_pump": 1.3}
	if not durs.has(name):
		return
	_emote = name
	_emote_t = 0.0
	_emote_dur = durs[name]

func cancel_emote() -> void:
	_emote = ""
	_spin = 0.0

func is_emoting() -> bool:
	return _emote != ""

func _smooth(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

func _emote_pose(T: Dictionary) -> void:
	var u := clampf(_emote_t / _emote_dur, 0.0, 1.0)
	var w := _smooth(minf(u / 0.12, 1.0)) * (1.0 - _smooth((u - 0.88) / 0.12))
	_body_y = 0.0
	_spin = 0.0
	match _emote:
		"pirouette":
			var toe := w
			T["ankle_n"] = Vector3(0.95 * toe, 0, 0)
			T["ankle_p"] = Vector3(0.95 * toe, 0, 0)
			T["thigh_p"] = Vector3(-1.1 * w, 0.0, 0.5 * w)
			T["knee_p"] = Vector3(2.1 * w, 0, 0)
			T["shoulder_n"] = Vector3(0, 0, -2.35 * w)
			T["shoulder_p"] = Vector3(0, 0, 2.35 * w)
			T["elbow_n"] = Vector3(0, 0, 1.15 * w)
			T["elbow_p"] = Vector3(0, 0, -1.15 * w)
			T["head"] = Vector3(-0.1 * w, 0, 0)
			T["spine"] = Vector3(-0.05 * w, 0, 0)
			_body_y = 0.065 * w
			_spin = TAU * 2.0 * _smooth((u - 0.1) / 0.8)
			if u > 0.88:
				var f := _smooth((u - 0.88) / 0.12)
				T["shoulder_n"] = Vector3(0, 0, -(2.35 * (1.0 - f) + 1.25 * f))
				T["shoulder_p"] = Vector3(0, 0, 2.35 * (1.0 - f) + 1.25 * f)
		"twirl_jump":
			var h := sin(PI * u)
			_body_y = 0.3 * h
			_spin = TAU * _smooth(u)
			T["thigh_n"] = Vector3(-0.5 * h, 0, 0)
			T["thigh_p"] = Vector3(-0.2 * h, 0, 0)
			T["knee_n"] = Vector3(1.0 * h, 0, 0)
			T["knee_p"] = Vector3(1.3 * h, 0, 0)
			T["shoulder_n"] = Vector3(0, 0, -1.9 * h)
			T["shoulder_p"] = Vector3(0, 0, 1.9 * h)
			T["elbow_n"] = Vector3(0, 0, 0.3 * h)
			T["elbow_p"] = Vector3(0, 0, -0.3 * h)
		"cheer":
			var h2 := absf(sin(TAU * u))
			_body_y = 0.2 * h2
			T["thigh_n"] = Vector3(-0.4 * h2, 0, 0)
			T["thigh_p"] = Vector3(-0.4 * h2, 0, 0)
			T["knee_n"] = Vector3(0.9 * h2, 0, 0)
			T["knee_p"] = Vector3(0.9 * h2, 0, 0)
			T["shoulder_n"] = Vector3(0, 0, -2.7 * w)
			T["shoulder_p"] = Vector3(0, 0, 2.7 * w)
			T["elbow_n"] = Vector3(0, 0, 0.2 * w)
			T["elbow_p"] = Vector3(0, 0, -0.2 * w)
			T["head"] = Vector3(-0.15 * w, 0, 0)
		"wave":
			T["shoulder_p"] = Vector3(0, 0, 2.3 * w)
			T["elbow_p"] = Vector3(0, 0, -0.35 * w + sin(_emote_t * 11.0) * 0.5 * w)
			T["head"] = Vector3(0, 0, -0.1 * w)
			T["spine"] = Vector3(0, 0, 0.05 * w)
		"flex":
			T["shoulder_n"] = Vector3(0, 0, -1.4 * w)
			T["shoulder_p"] = Vector3(0, 0, 1.4 * w)
			T["elbow_n"] = Vector3(0, 0, -1.55 * w)
			T["elbow_p"] = Vector3(0, 0, 1.55 * w)
			T["thigh_n"] = Vector3(0, 0, -0.1 * w)
			T["thigh_p"] = Vector3(0, 0, 0.1 * w)
			T["chest"] = Vector3(-0.08 * w, 0, 0)
			T["head"] = Vector3(-0.08 * w, 0, 0)
		"fist_pump":
			var h3 := absf(sin(PI * 2.0 * u))
			_body_y = 0.1 * h3
			T["shoulder_p"] = Vector3(-0.2 * w, 0, 2.5 * w - 0.4 * h3)
			T["elbow_p"] = Vector3(0, 0, -0.5 * w)
			T["shoulder_n"] = Vector3(-0.5 * w, 0, -0.3 * w)
			T["elbow_n"] = Vector3(-1.2 * w, 0, 0)
			T["knee_n"] = Vector3(0.3 * h3, 0, 0)
			T["knee_p"] = Vector3(0.3 * h3, 0, 0)
	set_happy(w)

func update_pose(vel: Vector3, grounded: bool, gliding: bool, dashing: bool, facing: Vector2, delta: float) -> void:
	if facing.length() > 0.01 and _emote == "":
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.y), clampf(delta * 14.0, 0.0, 1.0))
	var speed := clampf(Vector2(vel.x, vel.z).length() / 0.12, 0.0, 1.4)
	_time += delta
	if _emote != "" and (speed > 0.3 or not grounded or gliding or dashing):
		cancel_emote()
	if _emote == "":
		set_happy(maxf(_happy - delta * 4.0, 0.0))
		if grounded and speed < 0.05:
			_idle_t += delta
			if auto_emotes and _idle_t > _next_fidget:
				happy()
				_next_fidget = 9.0 + _rng.randf() * 8.0
				_idle_t = 0.0
		else:
			_idle_t = 0.0
	var sp := minf(speed, 1.0)
	if grounded and speed > 0.05:
		_phase += delta * (5.5 + 8.0 * sp)
	var T := {}
	var lean := 0.0
	var body_pitch := 0.0
	var target_squash := 1.0
	var bob := 0.0
	if grounded:
		var swing := 0.95 * sp
		for side in [-1.0, 1.0]:
			var tag := "n" if side < 0 else "p"
			var ph := _phase + (PI if side > 0 else 0.0)
			var fwd := sin(ph)
			var swing_phase := maxf(0.0, cos(ph))
			T["thigh_" + tag] = Vector3(-fwd * swing, 0, 0)
			T["knee_" + tag] = Vector3((0.12 + 1.05 * swing_phase) * sp, 0, 0)
			T["ankle_" + tag] = Vector3((0.25 * fwd + 0.15 * swing_phase) * sp, 0, 0)
			var afwd := -fwd * 0.85 * sp
			T["shoulder_" + tag] = Vector3(-afwd, 0, side * (0.1 + 0.05 * sp))
			T["elbow_" + tag] = Vector3(-(0.22 + 0.95 * sp + 0.35 * maxf(afwd, 0.0)), 0, 0)
		T["hips"] = Vector3(0, sin(_phase) * 0.13 * sp, sin(_phase * 2.0) * 0.03 * sp)
		T["spine"] = Vector3(0.2 * sp, -sin(_phase) * 0.18 * sp, 0)
		T["chest"] = Vector3(0.05 * sp, 0, 0)
		T["head"] = Vector3(-0.08 * sp, sin(_phase) * 0.06 * sp, 0)
		bob = (absf(sin(_phase)) * 0.04 - 0.01) * sp
		if sp < 0.05:
			var br := sin(_time * 2.0)
			T["shoulder_n"] = Vector3(0.02 * br, 0, -0.1)
			T["shoulder_p"] = Vector3(-0.02 * br, 0, 0.1)
			T["elbow_n"] = Vector3(-0.2, 0, 0)
			T["elbow_p"] = Vector3(-0.2, 0, 0)
			T["hips"] = Vector3(0, 0, sin(_time * 0.6) * 0.035)
			T["spine"] = Vector3(0.02 * br, 0, -sin(_time * 0.6) * 0.03)
			T["head"] = Vector3(0.01 * br, sin(_time * 0.4) * 0.06, 0)
	else:
		var rising := vel.y > 0.0
		T["thigh_n"] = Vector3(-0.75, 0, 0)
		T["knee_n"] = Vector3(1.15, 0, 0)
		T["ankle_n"] = Vector3(0.3, 0, 0)
		T["thigh_p"] = Vector3(0.2 if rising else -0.35, 0, 0)
		T["knee_p"] = Vector3(0.45 if rising else 0.8, 0, 0)
		T["ankle_p"] = Vector3(0.5, 0, 0)
		var up := 0.55 if rising else 1.0
		T["shoulder_n"] = Vector3(-0.5, 0, -up)
		T["shoulder_p"] = Vector3(-0.5, 0, up)
		T["elbow_n"] = Vector3(-0.5, 0, 0)
		T["elbow_p"] = Vector3(-0.5, 0, 0)
		T["spine"] = Vector3(0.12, 0, 0)
		T["head"] = Vector3(-0.1, 0, 0)
		target_squash = 1.0 + clampf(vel.y * 2.5, -0.12, 0.12)
	if gliding:
		body_pitch = 1.1
		T["shoulder_n"] = Vector3(-0.1, 0, -1.5)
		T["shoulder_p"] = Vector3(-0.1, 0, 1.5)
		T["elbow_n"] = Vector3(-0.1, 0, 0)
		T["elbow_p"] = Vector3(-0.1, 0, 0)
		T["thigh_n"] = Vector3(0.15, 0, -0.05)
		T["thigh_p"] = Vector3(0.15, 0, 0.05)
		T["knee_n"] = Vector3(0.2, 0, 0)
		T["knee_p"] = Vector3(0.2, 0, 0)
		T["head"] = Vector3(-0.9, 0, 0)
		T["spine"] = Vector3(-0.2, 0, 0)
	if dashing:
		body_pitch = 0.95
		T["shoulder_n"] = Vector3(0.9, 0, -0.15)
		T["shoulder_p"] = Vector3(0.9, 0, 0.15)
		T["elbow_n"] = Vector3(-0.35, 0, 0)
		T["elbow_p"] = Vector3(-0.35, 0, 0)
		T["thigh_n"] = Vector3(-0.2, 0, 0)
		T["thigh_p"] = Vector3(0.7, 0, 0)
		T["knee_n"] = Vector3(0.5, 0, 0)
		T["knee_p"] = Vector3(0.2, 0, 0)
		T["head"] = Vector3(-0.6, 0, 0)
	_body_y = 0.0
	if _emote != "":
		_emote_t += delta
		if _emote_t >= _emote_dur:
			_emote = ""
			_spin = 0.0
		else:
			T = {}
			_emote_pose(T)
	var k := clampf(delta * (16.0 if _emote != "" else 14.0), 0.0, 1.0)
	for key in _j:
		var node: Node3D = _j[key]
		var target: Vector3 = T.get(key, Vector3.ZERO)
		node.rotation = node.rotation.lerp(target, k)
	_squash = lerpf(_squash, target_squash, clampf(delta * 16.0, 0.0, 1.0))
	body.scale = Vector3(1.0 / sqrt(_squash), _squash, 1.0 / sqrt(_squash))
	body.rotation.x = lerpf(body.rotation.x, body_pitch, k)
	body.rotation.y = _spin
	body.position.y = bob + _body_y
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
