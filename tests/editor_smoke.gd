extends SceneTree

const Config = preload("res://scripts/world3d/avatar_config.gd")
const AnimeAvatar = preload("res://scripts/world3d/anime_avatar.gd")

var failures := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func _init() -> void:
	var c := Config.clamp_config({"age": 99, "curve": 5.0, "muscle": -1.0, "top": "bogus", "hair": 99, "accessories": ["glasses", "glasses", "wings"]})
	check(c["age"] == 30, "age clamped to 30")
	check(c["curve"] <= 0.75 and c["muscle"] >= 0.35, "sliders clamped")
	check(c["top"] == "jacket" and c["hair"] == Config.HAIR.size() - 1, "invalid options fall back")
	check(c["accessories"] == ["glasses"], "accessories filtered and unique")
	for i in Config.PRESET_COUNT:
		var a := AnimeAvatar.new()
		a.build(Config.to_params(Config.from_preset(i)))
		check(a.tri_count > 4000, "preset %d builds" % i)
		a.free()
	for g in ["female", "male"]:
		var full := Config.default_config()
		full["gender"] = g
		full["accessories"] = Config.ACCESSORIES.duplicate()
		var fa := AnimeAvatar.new()
		fa.build(Config.to_params(full))
		root.add_child(fa)
		check(fa.cape_pivot != null and fa.tail_pivot != null, "%s builds with every accessory" % g)
		for i in 30:
			fa.update_pose(Vector3(0, 0, -0.1), true, false, false, Vector2(0, -1), 0.016)
		fa.queue_free()
	var cfg := Config.default_config()
	cfg["name"] = "Test"
	cfg["hair_style"] = "long"
	Config.save_config(cfg)
	var back := Config.load_config()
	check(back["name"] == "Test" and back["hair_style"] == "long", "config round trips")
	DirAccess.remove_absolute(Config.PATH)
	var ed = load("res://scenes/character_editor.tscn").instantiate()
	root.add_child(ed)
	for i in 3:
		await process_frame
	check(ed.avatar != null, "editor builds an avatar")
	ed._on_preset(3)
	for i in 4:
		await process_frame
	check(ed.cfg["name"] == "Ren" and ed.avatar != null, "preset button reloads the editor")
	if failures == 0:
		print("EDITOR SMOKE PASSED")
	quit(1 if failures > 0 else 0)
