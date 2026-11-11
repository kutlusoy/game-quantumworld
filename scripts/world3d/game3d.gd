extends Node3D

const TerrainWorld = preload("res://scripts/core3d/terrain_world.gd")
const PlayerSim = preload("res://scripts/core3d/player_sim.gd")
const TerrainMesher = preload("res://scripts/world3d/terrain_mesher.gd")
const TouchControls = preload("res://scripts/world3d/touch_controls.gd")
const AnimeAvatar = preload("res://scripts/world3d/anime_avatar.gd")
const AvatarPresets = preload("res://scripts/world3d/avatar_presets.gd")
const Challenge = preload("res://scripts/core3d/challenge.gd")
const ChallengeTracker = preload("res://scripts/core3d/challenge_tracker.gd")
const Progress = preload("res://scripts/core3d/progress.gd")
const SaveStore = preload("res://scripts/core/save_store.gd")

const FP := 1024.0
const WORLD_SEED := 20241111
const MAX_LOG := 216000
const AVATAR_PRESET := 0

var world
var sim
var avatar
var cam: Camera3D
var touch
var sun: DirectionalLight3D
var yaw := 0.0
var pitch := 0.45
var dist := 5.4
var prev_pos := Vector3.ZERO
var cur_pos := Vector3.ZERO
var last_vel := Vector3.ZERO
var face := Vector2(0, 1)
var shard_nodes: Array = []
var input_log: Array = []
var info_label: Label
var fps_label: Label
var toast_label: Label
var toast_time := 0.0
var cam_pos := Vector3.ZERO
var time := 0.0
var is_touch := false
var _g_down := false
var tracker
var progress
var save_data := {}
var ring_finish: Array = []
var level_label: Label
var xp_bar: ProgressBar
var chal_label: Label

func _ready() -> void:
	is_touch = DisplayServer.is_touchscreen_available()
	var t0 := Time.get_ticks_msec()
	world = TerrainWorld.new(WORLD_SEED)
	sim = PlayerSim.new(world)
	save_data = SaveStore.load_progress()
	progress = Progress.from_dict(save_data)
	tracker = ChallengeTracker.new(Challenge.list_for(world))
	_build_environment()
	_build_world_meshes()
	_build_shards()
	_build_rings()
	AnimeAvatar.light_dir = sun.basis.z
	avatar = AnimeAvatar.new()
	avatar.build(AvatarPresets.get_preset(AVATAR_PRESET))
	add_child(avatar)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.1
	cam.far = 220.0
	add_child(cam)
	_build_hud()
	cur_pos = _sim_pos()
	prev_pos = cur_pos
	avatar.position = cur_pos
	cam_pos = cur_pos + Vector3(0, 3, 7)
	print("world built in ", Time.get_ticks_msec() - t0, " ms")

func _sim_pos() -> Vector3:
	return Vector3(sim.px, sim.py, sim.pz) / FP

func _build_environment() -> void:
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color("3b2a8c")
	psm.sky_horizon_color = Color("ff9ec4")
	psm.ground_horizon_color = Color("ff9ec4")
	psm.ground_bottom_color = Color("2b1055")
	var sky := Sky.new()
	sky.sky_material = psm
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9b8ff")
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color("ffb3d1")
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("fff1d6")
	sun.shadow_enabled = false
	add_child(sun)

func _toon_mat(tint: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/toon_voxel.gdshader")
	mat.set_shader_parameter("light_dir", sun.basis.z)
	mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	return mat

func _build_world_meshes() -> void:
	var mat := _toon_mat(Color.WHITE)
	for cz in range(TerrainWorld.D / TerrainMesher.CHUNK):
		for cx in range(TerrainWorld.W / TerrainMesher.CHUNK):
			var mi := MeshInstance3D.new()
			mi.mesh = TerrainMesher.build(world, cx, cz)
			mi.material_override = mat
			add_child(mi)
	var kinds := {"crystal": Color("86e2ff"), "wood": Color("9a6b3f"), "ruin": Color("b9aed0")}
	var mats := {}
	for k in kinds:
		mats[k] = _toon_mat(kinds[k])
	for i in world.box_min.size():
		var bmin := Vector3(world.box_min[i]) / FP
		var bmax := Vector3(world.box_max[i]) / FP
		var bm := BoxMesh.new()
		bm.size = bmax - bmin
		var bi := MeshInstance3D.new()
		bi.mesh = bm
		bi.position = (bmin + bmax) * 0.5
		bi.material_override = mats[world.box_kind[i]]
		add_child(bi)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	water.mesh = pm
	water.position = Vector3(TerrainWorld.W / 2.0, TerrainWorld.SEA / FP, TerrainWorld.D / 2.0)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.25, 0.6, 0.95, 0.78)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water.material_override = wm
	add_child(water)
	_build_trees()

func _build_trees() -> void:
	var n: int = world.trees.size()
	if n == 0:
		return
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.16
	trunk.height = 1.3
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 0.9
	crown.height = 2.2
	var tm := MultiMesh.new()
	tm.transform_format = MultiMesh.TRANSFORM_3D
	tm.mesh = trunk
	tm.instance_count = n
	var cm := MultiMesh.new()
	cm.transform_format = MultiMesh.TRANSFORM_3D
	cm.mesh = crown
	cm.instance_count = n
	for i in n:
		var p := Vector3(world.trees[i]) / FP
		var sc := 0.8 + float(TerrainWorld.hash3(i, 5, 3) & 255) / 255.0 * 0.6
		tm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(sc, sc, sc)), p + Vector3(0, 0.65 * sc, 0)))
		cm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(sc, sc, sc)), p + Vector3(0, 2.0 * sc, 0)))
	var ti := MultiMeshInstance3D.new()
	ti.multimesh = tm
	ti.material_override = _toon_mat(Color("8a5a3c"))
	add_child(ti)
	var ci := MultiMeshInstance3D.new()
	ci.multimesh = cm
	ci.material_override = _toon_mat(Color("4fcf6a"))
	add_child(ci)

func _shard_mesh() -> ArrayMesh:
	var top := Vector3(0, 0.45, 0)
	var bot := Vector3(0, -0.45, 0)
	var ring := [Vector3(0.28, 0, 0), Vector3(0, 0, 0.28), Vector3(-0.28, 0, 0), Vector3(0, 0, -0.28)]
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		for tri in [[top, b, a], [bot, a, b]]:
			var n: Vector3 = ((tri[1] - tri[0]).cross(tri[2] - tri[0])).normalized()
			for v in tri:
				verts.append(v)
				norms.append(n)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _build_shards() -> void:
	var mesh := _shard_mesh()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("7ff3ff")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color("7ff3ff")
	for i in world.shards.size():
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		var c: Vector3i = world.shard_center(i)
		mi.position = Vector3(c) / FP
		add_child(mi)
		shard_nodes.append(mi)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	touch = TouchControls.new()
	layer.add_child(touch)
	info_label = _hud_label(layer, Vector2(24, 18), 34)
	fps_label = _hud_label(layer, Vector2(24, 62), 22)
	toast_label = _hud_label(layer, Vector2(24, 100), 30)
	level_label = _hud_label(layer, Vector2(1010, 18), 34)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(1010, 66)
	xp_bar.size = Vector2(246, 16)
	xp_bar.max_value = 1.0
	xp_bar.show_percentage = false
	layer.add_child(xp_bar)
	chal_label = _hud_label(layer, Vector2(24, 150), 28)
	if not is_touch:
		var hint := _hud_label(layer, Vector2(24, 680), 20)
		hint.text = "WASD move   Space jump (press again to double jump, hold to glide)   Shift dash   G happy   Q/E or mouse drag camera"

func _ring_node(center: Vector3i, radius: int, color: Color) -> Node3D:
	var root_n := Node3D.new()
	root_n.position = Vector3(center) / FP
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var r := radius / FP
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 3.0
	beam.mesh = cm
	beam.position = Vector3(0, 1.5, 0)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(color.r, color.g, color.b, 0.16)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bm
	root_n.add_child(beam)
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = r
	dm.bottom_radius = r
	dm.height = 0.06
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(color.r, color.g, color.b, 0.6)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = dmat
	root_n.add_child(disc)
	add_child(root_n)
	return root_n

func _build_rings() -> void:
	for c in tracker.list:
		_ring_node(c.start, c.radius, Color("5dff9a"))
		if c.kind == "parkour":
			var fr := _ring_node(c.finish, c.radius, Color("ffd24d"))
			fr.visible = false
			ring_finish.append(fr)
		else:
			ring_finish.append(null)

func _save() -> void:
	save_data["xp"] = progress.xp
	save_data["tiers"] = progress.tiers
	SaveStore.save_progress(save_data)

func _award_xp(n: int) -> void:
	var gained: int = progress.add_xp(n)
	if gained > 0:
		_toast("Level %d!" % progress.level())
		avatar.celebrate(3)

func _handle_challenge(events: Array) -> void:
	for e in events:
		var ch = null
		for c in tracker.list:
			if c.id == e["id"]:
				ch = c
		match e["type"]:
			"start":
				_toast("%s: go!" % ch.title)
				var idx: int = tracker.list.find(ch)
				for k in ring_finish.size():
					if ring_finish[k] != null:
						ring_finish[k].visible = (k == idx)
			"finish":
				_hide_finish_rings()
				var tier: int = e["tier"]
				var names := ["GOLD", "SILVER", "BRONZE", "DONE"]
				var gain: int = progress.record_tier(ch.id, tier)
				_toast("%s %s  %.1fs  +%d XP" % [ch.title, names[tier], float(e["ticks"]) / 60.0, gain])
				_award_xp(gain)
				if tier <= 2:
					avatar.celebrate(3 - tier)
				_save()
			"fail":
				_hide_finish_rings()
				_toast("%s failed" % ch.title)

func _hide_finish_rings() -> void:
	for r in ring_finish:
		if r != null:
			r.visible = false

func _hud_label(parent: Node, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l

func _read_input() -> Array:
	var sx := 0.0
	var sy := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		sx -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		sx += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		sy += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		sy -= 1.0
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() > 0.2:
		sx = joy.x
		sy = -joy.y
	if touch.move.length() > 0.05:
		sx = touch.move.x
		sy = -touch.move.y
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	var d := right * sx + fwd * sy
	if d.length() > 1.0:
		d = d.normalized()
	var bits := 0
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A) or touch.jump_held:
		bits |= PlayerSim.BIT_JUMP
	if Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_X) or touch.dash_held:
		bits |= PlayerSim.BIT_DASH
	return [roundi(d.x * 100.0), roundi(d.y * 100.0), bits]

func _physics_process(_delta: float) -> void:
	var frame := _read_input()
	if input_log.size() < MAX_LOG:
		input_log.append(frame)
	prev_pos = cur_pos
	var ev: Dictionary = sim.step(frame[0], frame[1], frame[2])
	cur_pos = _sim_pos()
	if ev["respawned"]:
		prev_pos = cur_pos
		_toast("Back to the start")
	last_vel = Vector3(sim.vx, sim.vy, sim.vz) / FP
	if absi(frame[0]) + absi(frame[1]) > 20:
		face = Vector2(frame[0], frame[1])
	for i in ev["collected"]:
		_on_collect(i)
	_handle_challenge(tracker.update(sim, ev))

func _on_collect(i: int) -> void:
	var node: Node3D = shard_nodes[i]
	node.visible = false
	var p := CPUParticles3D.new()
	p.position = node.position
	p.amount = 18
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -6, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	p.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("7ff3ff")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = m
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	_toast("Shard %d / %d" % [sim.collected_count, world.shards.size()])
	var seen: Array = save_data.get("shard_xp", [])
	if not seen.has(i):
		seen.append(i)
		save_data["shard_xp"] = seen
		_award_xp(Progress.SHARD_XP)
		_save()
	if sim.collected_count % 10 == 0:
		avatar.celebrate(1)

func _toast(text: String) -> void:
	toast_label.text = text
	toast_time = 1.6

func _unhandled_input(event: InputEvent) -> void:
	if is_touch:
		return
	if event is InputEventMouseMotion and event.button_mask != 0:
		yaw -= event.relative.x * 0.005
		pitch = clampf(pitch + event.relative.y * 0.005, -0.3, 1.3)

func _process(delta: float) -> void:
	time += delta
	var f := Engine.get_physics_interpolation_fraction()
	var p := prev_pos.lerp(cur_pos, f)
	avatar.position = p
	avatar.update_pose(last_vel, sim.grounded, sim.gliding, sim.dash_ticks > 0, face, delta)
	var g_now := Input.is_physical_key_pressed(KEY_G)
	if (g_now and not _g_down) or touch.consume_emote():
		avatar.happy()
	_g_down = g_now
	var cd: Vector2 = touch.consume_camera_delta()
	yaw -= cd.x * 0.006
	pitch = clampf(pitch + cd.y * 0.006, -0.3, 1.3)
	if Input.is_physical_key_pressed(KEY_Q):
		yaw += delta * 2.2
	if Input.is_physical_key_pressed(KEY_E):
		yaw -= delta * 2.2
	var rs := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if rs.length() > 0.2:
		yaw -= rs.x * delta * 2.5
		pitch = clampf(pitch + rs.y * delta * 1.8, -0.3, 1.3)
	_update_camera(p, delta)
	for i in shard_nodes.size():
		var n: Node3D = shard_nodes[i]
		if n.visible:
			n.rotation.y = time * 2.0 + i
			n.position.y = world.shard_center(i).y / FP + sin(time * 2.5 + i) * 0.08
	info_label.text = "Shards %d / %d" % [sim.collected_count, world.shards.size()]
	level_label.text = "Level %d" % progress.level()
	xp_bar.value = progress.level_fraction()
	var act = tracker.active_challenge()
	if act != null:
		chal_label.text = "%s  %.1fs   (gold %.0fs)" % [act.title, float(tracker.ticks) / 60.0, float(act.par[0]) / 60.0]
	else:
		chal_label.text = ""
	fps_label.text = "%d fps" % Engine.get_frames_per_second()
	toast_time -= delta
	if toast_time <= 0.0:
		toast_label.text = ""

func _update_camera(p: Vector3, delta: float) -> void:
	var target := p + Vector3(0, 1.4, 0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var d := dist
	var steps := int(dist / 0.3)
	for i in range(1, steps + 1):
		var pt := target + dir * (i * 0.3)
		var h: int = world.height_at(int(pt.x * FP), int(pt.z * FP))
		if h != TerrainWorld.VOID and pt.y * FP < h + 220.0:
			d = maxf((i - 1) * 0.3 - 0.2, 0.8)
			break
	var desired := target + dir * d
	cam_pos = cam_pos.lerp(desired, 1.0 - exp(-delta * 16.0))
	cam.global_position = cam_pos
	cam.look_at(target, Vector3.UP)
