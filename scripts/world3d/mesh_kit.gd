extends RefCounted

var verts := PackedVector3Array()
var cols := PackedColorArray()
var uvs := PackedVector2Array()
var idx := PackedInt32Array()

func _add_grid(rows: int, per_row: int, wrap: bool, color: Color, fn: Callable, keep: Callable = Callable(), color_fn: Callable = Callable()) -> void:
	var base := verts.size()
	var pos := []
	for r in rows:
		for c in per_row:
			var p: Vector3 = fn.call(r, c)
			pos.append(p)
			verts.append(p)
			cols.append(color_fn.call(r, c) if color_fn.is_valid() else color)
			var u := float(c) / float(per_row if wrap else maxi(per_row - 1, 1))
			uvs.append(Vector2(u, float(r) / float(maxi(rows - 1, 1))))
	var cmax := per_row if wrap else per_row - 1
	for r in rows - 1:
		for c in cmax:
			var c2 := (c + 1) % per_row
			var a := r * per_row + c
			var b := r * per_row + c2
			var d := (r + 1) * per_row + c
			var e := (r + 1) * per_row + c2
			if keep.is_valid():
				if not (keep.call(pos[a]) and keep.call(pos[b]) and keep.call(pos[d]) and keep.call(pos[e])):
					continue
			idx.append_array([base + a, base + d, base + b, base + b, base + d, base + e])

func ellipsoid(center: Vector3, radii: Vector3, color: Color, rings: int = 14, segs: int = 20, deform: Callable = Callable(), keep: Callable = Callable()) -> void:
	var fn := func(r: int, c: int) -> Vector3:
		var phi := PI * float(r) / float(rings)
		var theta := TAU * float(c) / float(segs)
		var u := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
		if deform.is_valid():
			u = deform.call(u)
		return center + Vector3(u.x * radii.x, u.y * radii.y, u.z * radii.z)
	_add_grid(rings + 1, segs, true, color, fn, keep)

func tube(points: Array, radii: Array, color: Color, segs: int = 12, cap_start: bool = true, cap_end: bool = true, ring_colors: Array = [], round_caps: int = 0) -> void:
	var pts := points.duplicate()
	var rad := radii.duplicate()
	var rcol := ring_colors.duplicate()
	if round_caps != 0 and pts.size() > 1:
		var steps := [1.5, 1.15, 0.8, 0.4]
		var head_p := []
		var head_r := []
		var head_c := []
		var tail_p := []
		var tail_r := []
		var tail_c := []
		var n0 := pts.size()
		var l0 := ((rad[0] as Vector2).x + (rad[0] as Vector2).y) * 0.5
		var l1 := ((rad[n0 - 1] as Vector2).x + (rad[n0 - 1] as Vector2).y) * 0.5
		var t0: Vector3 = (pts[0] - pts[1]).normalized()
		var t1: Vector3 = (pts[n0 - 1] - pts[n0 - 2]).normalized()
		if (round_caps & 1) != 0:
			for a in steps:
				head_p.append(pts[0] + t0 * l0 * sin(a))
				head_r.append((rad[0] as Vector2) * cos(a))
				if not rcol.is_empty():
					head_c.append(rcol[0])
		else:
			cap_start = true
		steps.reverse()
		if (round_caps & 2) != 0:
			for a in steps:
				tail_p.append(pts[n0 - 1] + t1 * l1 * sin(a))
				tail_r.append((rad[n0 - 1] as Vector2) * cos(a))
				if not rcol.is_empty():
					tail_c.append(rcol[n0 - 1])
		else:
			cap_end = true
		pts = head_p + pts + tail_p
		rad = head_r + rad + tail_r
		if not rcol.is_empty():
			rcol = head_c + rcol + tail_c
		if (round_caps & 1) != 0:
			cap_start = false
		if (round_caps & 2) != 0:
			cap_end = false
	if cap_start:
		pts.push_front(pts[0])
		rad.push_front(Vector2.ZERO)
		if not rcol.is_empty():
			rcol.push_front(rcol[0])
	if cap_end:
		pts.push_back(pts[pts.size() - 1])
		rad.push_back(Vector2.ZERO)
		if not rcol.is_empty():
			rcol.push_back(rcol[rcol.size() - 1])
	var n := pts.size()
	var frames := []
	for i in n:
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, n - 1)]
		var t := (b - a)
		if t.length() < 0.00001:
			t = frames[i - 1][2] if i > 0 else Vector3.DOWN
		t = t.normalized()
		var ref := Vector3(0, 0, 1)
		if absf(t.dot(ref)) > 0.9:
			ref = Vector3(1, 0, 0)
		var nn := t.cross(ref).normalized()
		var bb := t.cross(nn).normalized()
		frames.append([nn, bb, t])
	var fn := func(r: int, c: int) -> Vector3:
		var th := TAU * float(c) / float(segs)
		var f: Array = frames[r]
		var rr: Vector2 = rad[r]
		return pts[r] + f[0] * cos(th) * rr.x + f[1] * sin(th) * rr.y
	var cfn := Callable()
	if not rcol.is_empty():
		cfn = func(r: int, _c: int) -> Color:
			return rcol[r]
	_add_grid(n, segs, true, color, fn, Callable(), cfn)

func ribbon(points: Array, widths: Array, hint: Vector3, color: Color) -> void:
	var n := points.size()
	var sides := []
	for i in n:
		var a: Vector3 = points[maxi(i - 1, 0)]
		var b: Vector3 = points[mini(i + 1, n - 1)]
		var t := (b - a).normalized()
		var s := t.cross(hint)
		if s.length() < 0.0001:
			s = Vector3.RIGHT
		sides.append(s.normalized())
	var fn := func(r: int, c: int) -> Vector3:
		var sgn := -0.5 if c == 0 else 0.5
		return points[r] + sides[r] * float(widths[r]) * sgn
	_add_grid(n, 2, false, color, fn)

func build() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if verts.is_empty() or idx.is_empty():
		return mesh
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	for i in range(0, idx.size(), 3):
		var a := verts[idx[i]]
		var b := verts[idx[i + 1]]
		var c := verts[idx[i + 2]]
		var n := (b - a).cross(c - a)
		norms[idx[i]] += n
		norms[idx[i + 1]] += n
		norms[idx[i + 2]] += n
	for i in norms.size():
		var v := norms[i]
		norms[i] = -v.normalized() if v.length() > 0.000001 else Vector3.UP
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func triangle_count() -> int:
	return idx.size() / 3
