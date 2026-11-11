extends RefCounted

const PATH := "user://save.json"

static func load_progress() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {"stars": {}}
	var f := FileAccess.open(PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("stars"):
		return {"stars": {}}
	return data

static func save_progress(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
