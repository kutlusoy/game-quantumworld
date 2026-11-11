extends RefCounted

const PATH := "user://save.json"

static func load_progress() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {"stars": {}, "xp": 0, "tiers": {}}
	var f := FileAccess.open(PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {"stars": {}, "xp": 0, "tiers": {}}
	if not data.has("stars"):
		data["stars"] = {}
	if not data.has("xp"):
		data["xp"] = 0
	if not data.has("tiers"):
		data["tiers"] = {}
	return data

static func save_progress(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
