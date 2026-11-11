extends SceneTree

const AnimeAvatar = preload("res://scripts/world3d/anime_avatar.gd")
const Presets = preload("res://scripts/world3d/avatar_presets.gd")

var failures := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func _init() -> void:
	var presets := Presets.all()
	check(presets.size() >= 5, "at least five presets")
	var names := {}
	for p in presets:
		names[p["name"]] = true
		var a := AnimeAvatar.new()
		root.add_child(a)
		a.build(p)
		await process_frame
		check(a.tri_count > 2000 and a.tri_count < 15000, "%s triangle budget %d" % [p["name"], a.tri_count])
		check(a.eye_mats.size() == 2, "%s has two eyes" % p["name"])
		for key in ["hips", "spine", "chest", "neck", "head", "thigh_n", "knee_p", "ankle_n", "shoulder_p", "elbow_n", "wrist_p"]:
			check(a._j.has(key), "%s has joint %s" % [p["name"], key])
		check(a.hair_group != null, "%s has hair" % p["name"])
		for i in 30:
			a.update_pose(Vector3(0.1, 0.0, 0.0), true, false, false, Vector2(1, 0), 0.016)
		a.update_pose(Vector3(0.0, 0.1, 0.0), false, true, false, Vector2(0, 1), 0.016)
		a.update_pose(Vector3.ZERO, false, false, true, Vector2(0, 1), 0.016)
		check(not is_nan(a.body.rotation.x) and not is_nan(a.body.scale.y), "%s pose stays finite" % p["name"])
		for e in a.emotes():
			a.play_emote(e)
			check(a.is_emoting(), "%s starts emote %s" % [p["name"], e])
			for i in 200:
				a.update_pose(Vector3.ZERO, true, false, false, Vector2(0, 1), 0.016)
			check(not a.is_emoting(), "%s finishes emote %s" % [p["name"], e])
			check(not is_nan(a.body.position.y) and not is_nan(a.body.rotation.y), "%s emote %s stays finite" % [p["name"], e])
		a.play_emote("wave")
		a.update_pose(Vector3(0.12, 0, 0), true, false, false, Vector2(1, 0), 0.016)
		check(not a.is_emoting(), "%s cancels emote when moving" % p["name"])
		check(a.gender == p["gender"], "%s gender set" % p["name"])
		check(p["age"] >= 19 and p["age"] <= 30, "%s age in range" % p["name"])
		a.queue_free()
	check(names.size() == presets.size(), "preset names are unique")
	var lineup = load("res://scenes/avatar_lineup.tscn").instantiate()
	root.add_child(lineup)
	await process_frame
	check(lineup.avatars.size() == presets.size(), "lineup shows every preset")
	if failures == 0:
		print("AVATAR SMOKE PASSED")
	quit(1 if failures > 0 else 0)
