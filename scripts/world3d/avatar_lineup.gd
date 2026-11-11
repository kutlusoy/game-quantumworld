extends Node3D

const AnimeAvatar = preload("res://scripts/world3d/anime_avatar.gd")
const Config = preload("res://scripts/world3d/avatar_config.gd")

var avatars: Array = []
var cam: Camera3D
var orbit := 0.0
var time := 0.0
var _g_down := false

func _ready() -> void:
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
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var floor := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 4.8
	disc.bottom_radius = 4.8
	disc.height = 0.1
	floor.mesh = disc
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("6fdc5a")
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor.material_override = fm
	floor.position.y = -0.05
	add_child(floor)
	var count: int = Config.PRESET_COUNT
	for i in count:
		var a := AnimeAvatar.new()
		a.build(Config.to_params(Config.from_preset(i)))
		var x := (i - (count - 1) / 2.0) * 1.0
		a.position = Vector3(x, 0, 0)
		add_child(a)
		avatars.append(a)
	cam = Camera3D.new()
	cam.fov = 38.0
	add_child(cam)
	_place_camera()

func _place_camera() -> void:
	var target := Vector3(0, 1.05, 0)
	cam.position = target + Vector3(sin(orbit) * 8.2, 0.25, cos(orbit) * 8.2)
	cam.look_at(target, Vector3.UP)

func _process(delta: float) -> void:
	time += delta
	for a in avatars:
		a.update_pose(Vector3.ZERO, true, false, false, Vector2.ZERO, delta)
	if Input.is_physical_key_pressed(KEY_G) and not _g_down:
		for a in avatars:
			a.happy()
	_g_down = Input.is_physical_key_pressed(KEY_G)
	if Input.is_physical_key_pressed(KEY_LEFT):
		orbit -= delta
	if Input.is_physical_key_pressed(KEY_RIGHT):
		orbit += delta
	_place_camera()
