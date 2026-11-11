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
	for i in 5:
		var a := AnimeAvatar.new()
		a.build(Config.to_params(Config.from_preset(i)))
		check(a.tri_count > 4000, "preset %d builds" % i)
		a.free()
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
