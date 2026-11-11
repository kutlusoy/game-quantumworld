extends Node3D

const AnimeAvatar = preload("res://scripts/world3d/anime_avatar.gd")
const Config = preload("res://scripts/world3d/avatar_config.gd")

var cfg: Dictionary
var avatar
var cam: Camera3D
var yaw := 0.3
var panel_box: VBoxContainer
var name_edit: LineEdit
var _drag_id := -1

func _ready() -> void:
	cfg = Config.load_config()
	_build_scene()
	_build_ui()
	_rebuild()

func _build_scene() -> void:
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
	disc.top_radius = 1.1
	disc.bottom_radius = 1.1
	disc.height = 0.08
	floor.mesh = disc
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("6fdc5a")
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor.material_override = fm
	floor.position.y = -0.04
	add_child(floor)
	cam = Camera3D.new()
	cam.fov = 34.0
	add_child(cam)
	_place_camera()

func _place_camera() -> void:
	var target := Vector3(0.0, 0.88, 0.0)
	cam.position = target + Vector3(sin(yaw) * 3.9, 0.2, cos(yaw) * 3.9)
	cam.look_at(target, Vector3.UP)

func _rebuild() -> void:
	if avatar != null:
		avatar.queue_free()
	avatar = AnimeAvatar.new()
	avatar.build(Config.to_params(cfg))
	add_child(avatar)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -540
	panel.offset_right = -10
	panel.offset_top = 10
	panel.offset_bottom = -10
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.2, 0.82)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	panel_box = VBoxContainer.new()
	panel_box.custom_minimum_size = Vector2(500, 0)
	panel_box.add_theme_constant_override("separation", 10)
	scroll.add_child(panel_box)

	name_edit = LineEdit.new()
	name_edit.text = cfg["name"]
	name_edit.max_length = 12
	name_edit.custom_minimum_size = Vector2(0, 64)
	name_edit.add_theme_font_size_override("font_size", 30)
	name_edit.text_changed.connect(func(t: String) -> void: cfg["name"] = t)
	panel_box.add_child(name_edit)

	var presets := HFlowContainer.new()
	presets.add_theme_constant_override("h_separation", 6)
	presets.add_theme_constant_override("v_separation", 6)
	for i in Config.PRESET_COUNT:
		var b := _button(Config.from_preset(i)["name"], 22)
		b.custom_minimum_size = Vector2(90, 56)
		b.pressed.connect(_on_preset.bind(i))
		presets.add_child(b)
	panel_box.add_child(presets)

	_choice("Body", "gender", Config.GENDERS)
	_slider("Curves", "curve", 0.3, 0.75, true)
	_slider("Muscle", "muscle", 0.35, 0.95, false)
	_int_choice("Age", "age", 19, 30)
	_choice("Hair", "hair_style", Config.HAIR_STYLES)
	_swatches("Hair color", "hair", Config.HAIR.map(func(p): return Color(p[0])))
	_swatches("Skin", "skin", Config.SKIN.map(func(s): return Color(s)))
	_swatches("Eyes", "eyes", Config.EYES.map(func(p): return Color(p[1])))
	_choice("Top", "top", Config.TOPS)
	_choice("Sleeves", "sleeves", Config.SLEEVES)
	_choice("Legwear", "legwear", Config.LEGWEAR)
	_swatches("Outfit colors", "outfit", Config.OUTFITS.map(func(o): return Color(o[1])))
	_choice("Expression", "expression", Config.EXPRESSIONS)
	_toggles("Accessories", Config.ACCESSORIES)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var cheer := _button("Cheer", 26)
	cheer.pressed.connect(func() -> void: avatar.happy())
	var done := _button("Save and play", 26)
	done.pressed.connect(_on_done)
	cheer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cheer)
	row.add_child(done)
	panel_box.add_child(row)

func _button(text: String, fsize: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", fsize)
	return b

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	l.custom_minimum_size = Vector2(150, 0)
	return l

func _choice(title: String, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(title))
	var prev := _button("<", 28)
	var next := _button(">", 28)
	prev.custom_minimum_size = Vector2(64, 64)
	next.custom_minimum_size = Vector2(64, 64)
	var val := Label.new()
	val.add_theme_font_size_override("font_size", 24)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.text = String(cfg[key])
	var step := func(d: int) -> void:
		var i: int = options.find(cfg[key])
		cfg[key] = options[posmod(i + d, options.size())]
		val.text = String(cfg[key])
		_rebuild()
	prev.pressed.connect(step.bind(-1))
	next.pressed.connect(step.bind(1))
	row.add_child(prev)
	row.add_child(val)
	row.add_child(next)
	panel_box.add_child(row)

func _int_choice(title: String, key: String, lo: int, hi: int) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(title))
	var prev := _button("<", 28)
	var next := _button(">", 28)
	prev.custom_minimum_size = Vector2(64, 64)
	next.custom_minimum_size = Vector2(64, 64)
	var val := Label.new()
	val.add_theme_font_size_override("font_size", 24)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.text = str(cfg[key])
	var step := func(d: int) -> void:
		cfg[key] = clampi(int(cfg[key]) + d, lo, hi)
		val.text = str(cfg[key])
		_rebuild()
	prev.pressed.connect(step.bind(-1))
	next.pressed.connect(step.bind(1))
	row.add_child(prev)
	row.add_child(val)
	row.add_child(next)
	panel_box.add_child(row)

func _slider(title: String, key: String, lo: float, hi: float, _female_only: bool) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(title))
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = float(cfg[key])
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 56)
	s.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			cfg[key] = s.value
			_rebuild())
	row.add_child(s)
	panel_box.add_child(row)

func _swatches(title: String, key: String, colors: Array) -> void:
	panel_box.add_child(_label(title))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(56, 56)
		var st := StyleBoxFlat.new()
		st.bg_color = colors[i]
		st.set_corner_radius_all(28)
		st.border_color = Color.WHITE
		st.set_border_width_all(0)
		var sel := st.duplicate()
		sel.set_border_width_all(5)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", sel)
		b.add_theme_stylebox_override("focus", sel)
		b.pressed.connect(func() -> void:
			cfg[key] = i
			_rebuild())
		flow.add_child(b)
	panel_box.add_child(flow)

func _toggles(title: String, options: Array) -> void:
	panel_box.add_child(_label(title))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for o in options:
		var b := _button(o, 22)
		b.toggle_mode = true
		b.button_pressed = o in cfg["accessories"]
		b.custom_minimum_size = Vector2(150, 56)
		b.toggled.connect(func(on: bool) -> void:
			var acc: Array = cfg["accessories"]
			if on and o not in acc:
				acc.append(o)
			elif not on:
				acc.erase(o)
			_rebuild())
		flow.add_child(b)
	panel_box.add_child(flow)

func _on_preset(i: int) -> void:
	cfg = Config.from_preset(i)
	_reload_ui()

func _reload_ui() -> void:
	for n in get_children():
		if n is CanvasLayer:
			n.queue_free()
	await get_tree().process_frame
	_build_ui()
	_rebuild()

func _on_done() -> void:
	Config.save_config(cfg)
	get_tree().change_scene_to_file("res://scenes/world3d.tscn")

func _input(event: InputEvent) -> void:
	var pw := get_viewport().get_visible_rect().size.x - 550.0
	if event is InputEventScreenTouch and event.pressed and event.position.x < pw:
		_drag_id = event.index
	elif event is InputEventScreenTouch and not event.pressed and event.index == _drag_id:
		_drag_id = -1
	elif event is InputEventScreenDrag and event.index == _drag_id:
		yaw -= event.relative.x * 0.01
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and event.position.x < pw:
		yaw -= event.relative.x * 0.01

func _process(delta: float) -> void:
	avatar.update_pose(Vector3.ZERO, true, false, false, Vector2.ZERO, delta)
	_place_camera()
