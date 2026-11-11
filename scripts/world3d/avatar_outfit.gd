extends RefCounted

const MeshKit = preload("res://scripts/world3d/mesh_kit.gd")

const PARTS := ["cape", "pauldrons", "belt", "sash", "skirt", "bracers", "kneepads", "collar", "necklace", "earrings", "bow", "tail", "halo"]

static func build(a) -> void:
	var acc: Array = a.params.get("accessories", [])
	for part in PARTS:
		if part not in acc:
			continue
		match part:
			"cape": cape(a)
			"pauldrons": pauldrons(a)
			"belt": belt(a)
			"sash": sash(a)
			"skirt": skirt(a)
			"bracers": bracers(a)
			"kneepads": kneepads(a)
			"collar": collar(a)
			"necklace": necklace(a)
			"earrings": earrings(a)
			"bow": bow(a)
			"tail": tail(a)
			"halo": halo(a)

static func _circle(cx: float, cy: float, cz: float, rx: float, rz: float, n: int) -> Array:
	var pts := []
	for i in n + 1:
		var t := TAU * float(i) / float(n)
		pts.append(Vector3(cx + sin(t) * rx, cy, cz + cos(t) * rz))
	return pts

static func _uniform(n: int, r: float) -> Array:
	var out := []
	for i in n:
		out.append(Vector2(r, r))
	return out

static func belt(a) -> void:
	var s: float = a._d["s"]
	var yh := 0.125 * s
	var pr: Array = a._prof_at(a._torso_keys(), yh)
	var y: float = yh - a._d["spine"]
	var trim: Color = a.params["trim"]
	var base: Color = (a.params["pants"] as Color).darkened(0.25)
	var mb := MeshKit.new()
	var path := _circle(0.0, y, pr[3], pr[1] + 0.012, pr[2] + 0.012, 20)
	mb.tube(path, _uniform(path.size(), 0.014), base, 8, false, false)
	mb.ellipsoid(Vector3(0, y, pr[3] + pr[2] + 0.02), Vector3(0.028, 0.022, 0.012), trim, 8, 12)
	for side in [-1.0, 1.0]:
		mb.ellipsoid(Vector3(side * (pr[1] + 0.022), y - 0.045, pr[3] + 0.01), Vector3(0.022, 0.034, 0.03), base.lightened(0.1), 8, 12)
		mb.ellipsoid(Vector3(side * (pr[1] + 0.03), y - 0.02, pr[3] + 0.01), Vector3(0.014, 0.01, 0.026), trim, 6, 10)
	a._node(a._j["spine"], mb, a._toon)

static func sash(a) -> void:
	var s: float = a._d["s"]
	var yh := 0.14 * s
	var pr: Array = a._prof_at(a._torso_keys(), yh)
	var y: float = yh - a._d["spine"]
	var col: Color = a.params["trim"]
	var mb := MeshKit.new()
	var path := _circle(0.0, y, pr[3], pr[1] + 0.01, pr[2] + 0.01, 20)
	var radii := []
	for i in path.size():
		radii.append(Vector2(0.024, 0.014))
	mb.tube(path, radii, col, 8, false, false)
	var bz: float = pr[3] - pr[2] - 0.02
	mb.ellipsoid(Vector3(0, y, bz), Vector3(0.024, 0.02, 0.016), col.darkened(0.15), 8, 12)
	mb.ellipsoid(Vector3(-0.032, y + 0.004, bz - 0.004), Vector3(0.03, 0.018, 0.012), col, 8, 12)
	mb.ellipsoid(Vector3(0.032, y + 0.004, bz - 0.004), Vector3(0.03, 0.018, 0.012), col, 8, 12)
	a._node(a._j["spine"], mb, a._toon)
	var tails := MeshKit.new()
	for side in [-1.0, 1.0]:
		var pts := [Vector3(side * 0.025, y - 0.01, bz), Vector3(side * 0.045, y - 0.12, bz - 0.04), Vector3(side * 0.06, y - 0.25, bz - 0.075), Vector3(side * 0.065, y - 0.36, bz - 0.095)]
		tails.ribbon(pts, [0.035, 0.045, 0.05, 0.04], Vector3(0, 0, 1), col)
	a._node(a._j["spine"], tails, a._cloth)

static func skirt(a) -> void:
	var s: float = a._d["s"]
	var jacket: Color = a.params["jacket"]
	var trim: Color = a.params["trim"]
	var mb := MeshKit.new()
	var ys := [0.075 * s, 0.0, -0.08 * s, -0.17 * s, -0.24 * s]
	var rs := [Vector2(0.118, 0.092), Vector2(0.138, 0.108), Vector2(0.168, 0.13), Vector2(0.196, 0.152), Vector2(0.214, 0.166)]
	a._tube_ys(mb, ys, rs, jacket.darkened(0.05), 20)
	a._tube_ys(mb, [-0.222 * s, -0.245 * s], [Vector2(0.209, 0.161), Vector2(0.216, 0.168)], trim, 20)
	var under := MeshKit.new()
	a._tube_ys(under, [-0.02 * s, -0.12 * s, -0.215 * s], [Vector2(0.14, 0.11), Vector2(0.172, 0.133), Vector2(0.205, 0.16)], trim.darkened(0.1), 20)
	a._node(a._j["hips"], under, a._toon)
	a._node(a._j["hips"], mb, a._toon)

static func pauldrons(a) -> void:
	var trim: Color = a.params["trim"]
	var jacket: Color = a.params["jacket"]
	var k: float = 1.0 + (0.15 * a._d["muscle"] if a._d["m"] else 0.0)
	for side in [-1.0, 1.0]:
		var tag := "n" if side < 0 else "p"
		var mb := MeshKit.new()
		mb.ellipsoid(Vector3(side * 0.012, 0.02, 0), Vector3(0.068, 0.046, 0.066) * k, trim, 10, 14)
		mb.ellipsoid(Vector3(side * 0.02, 0.046, 0), Vector3(0.056, 0.022, 0.054) * k, jacket.lightened(0.1), 8, 12)
		a._node(a._j["shoulder_" + tag], mb, a._toon)

static func bracers(a) -> void:
	var trim: Color = a.params["trim"]
	var m: bool = a._d["m"]
	var mu: float = a._d["muscle"]
	var fa: float = a._d["fa"]
	var k: float = 1.0 + (0.22 * mu if m else 0.0)
	var r_mid := (0.037 if m else 0.026) * k + 0.007
	var r_low := (0.026 if m else 0.02) * k + 0.006
	for side in [-1.0, 1.0]:
		var tag := "n" if side < 0 else "p"
		var mb := MeshKit.new()
		a._tube_ys(mb, [-fa * 0.5, -fa * 0.9], [Vector2(r_mid, r_mid), Vector2(r_low, r_low)], trim, 12)
		a._tube_ys(mb, [-fa * 0.9, -fa * 0.94], [Vector2(r_low + 0.003, r_low + 0.003), Vector2(r_low + 0.003, r_low + 0.003)], trim.lightened(0.25), 12)
		a._node(a._j["elbow_" + tag], mb, a._toon)

static func kneepads(a) -> void:
	var trim: Color = a.params["trim"]
	var k: float = 1.0 + (0.05 * a._d["muscle"] if a._d["m"] else 0.0)
	for side in [-1.0, 1.0]:
		var tag := "n" if side < 0 else "p"
		var mb := MeshKit.new()
		mb.ellipsoid(Vector3(0, -0.005, 0.034), Vector3(0.048, 0.056, 0.034) * k, trim, 10, 14)
		a._node(a._j["knee_" + tag], mb, a._toon)

static func collar(a) -> void:
	var jacket: Color = a.params["jacket"]
	var nr := 0.047 if a._d["m"] else 0.034
	var mb := MeshKit.new()
	var pts := [Vector3(0, -0.018, 0), Vector3(0, 0.02, 0), Vector3(0, 0.055, 0)]
	mb.tube(pts, [Vector2(nr * 2.1, nr * 2.0), Vector2(nr * 1.65, nr * 1.6), Vector2(nr * 1.45, nr * 1.4)], jacket.lightened(0.08), 16, false, false)
	a._node(a._j["neck"], mb, a._toon)

static func necklace(a) -> void:
	var accent: Color = a.params["accent"]
	var nr := 0.047 if a._d["m"] else 0.034
	var mb := MeshKit.new()
	var path := _circle(0.0, -0.03, 0.0, nr + 0.013, nr + 0.013, 16)
	mb.tube(path, _uniform(path.size(), 0.0032), Color(0.92, 0.88, 0.7), 5, false, false)
	var chain := [Vector3(0, -0.035, nr + 0.014), Vector3(0, -0.075, 0.074)]
	mb.tube(chain, _uniform(2, 0.0032), Color(0.92, 0.88, 0.7), 5)
	mb.ellipsoid(Vector3(0, -0.087, 0.078), Vector3(0.011, 0.015, 0.007), accent, 8, 10)
	a._node(a._j["neck"], mb, a._toon)

static func earrings(a) -> void:
	var accent: Color = a.params["accent"]
	var mb := MeshKit.new()
	for side in [-1.0, 1.0]:
		mb.ellipsoid(Vector3(side * 0.107, -0.032, 0.004), Vector3(0.007, 0.007, 0.007), Color(0.95, 0.9, 0.7), 6, 8)
		mb.ellipsoid(Vector3(side * 0.108, -0.058, 0.004), Vector3(0.008, 0.013, 0.008), accent, 6, 8)
	a._node(a.head_node, mb, a._toon)

static func bow(a) -> void:
	var accent: Color = a.params["accent"]
	var mb := MeshKit.new()
	var c := Vector3(0.088, 0.1, -0.012)
	mb.ellipsoid(c, Vector3(0.012, 0.012, 0.012), accent.darkened(0.2), 8, 10)
	mb.ellipsoid(c + Vector3(0.006, 0.03, 0), Vector3(0.012, 0.03, 0.018), accent, 8, 12)
	mb.ellipsoid(c + Vector3(0.006, -0.03, 0), Vector3(0.012, 0.03, 0.018), accent, 8, 12)
	a._node(a.head_node, mb, a._toon)

static func tail(a) -> void:
	var col: Color = a.params["hair_color"]
	var tip: Color = a.params["hair_hl"]
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.02, -0.07)
	a._j["hips"].add_child(pivot)
	a.tail_pivot = pivot
	var mb := MeshKit.new()
	var pts := [Vector3(0, 0, 0), Vector3(0, -0.06, -0.1), Vector3(0, -0.09, -0.22), Vector3(0, -0.03, -0.34), Vector3(0, 0.07, -0.4), Vector3(0, 0.17, -0.4)]
	var radii := [Vector2(0.022, 0.022), Vector2(0.042, 0.042), Vector2(0.056, 0.056), Vector2(0.054, 0.054), Vector2(0.036, 0.036), Vector2(0.006, 0.006)]
	var cols := [col, col, col, col, tip, tip]
	mb.tube(pts, radii, Color.WHITE, 10, true, true, cols)
	a._node(pivot, mb, a._toon)

static func cape(a) -> void:
	var jacket: Color = a.params["jacket"]
	var trim: Color = a.params["trim"]
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.15 * a._d["s"], -0.088)
	a._j["chest"].add_child(pivot)
	a.cape_pivot = pivot
	var mb := MeshKit.new()
	var pts := [Vector3(0, 0, 0), Vector3(0, -0.15, -0.03), Vector3(0, -0.4, -0.07), Vector3(0, -0.68, -0.12)]
	mb.ribbon(pts, [0.2, 0.27, 0.36, 0.46], Vector3(0, 0, 1), jacket.darkened(0.1))
	var edge := MeshKit.new()
	edge.ribbon([Vector3(0, -0.66, -0.116), Vector3(0, -0.68, -0.12)], [0.455, 0.46], Vector3(0, 0, 1), trim)
	a._node(pivot, mb, a._cloth)
	a._node(pivot, edge, a._cloth)
	var clasp := MeshKit.new()
	for side in [-1.0, 1.0]:
		clasp.ellipsoid(Vector3(side * 0.09, 0.0, 0.03), Vector3(0.014, 0.014, 0.012), trim, 6, 8)
	a._node(pivot, clasp, a._toon)

static func halo(a) -> void:
	var accent: Color = a.params["accent"]
	var mb := MeshKit.new()
	var path := _circle(0.0, 0.25, -0.01, 0.09, 0.09, 24)
	mb.tube(path, _uniform(path.size(), 0.006), accent.lightened(0.5), 6, false, false)
	a._node(a.head_node, mb, a._flat)
