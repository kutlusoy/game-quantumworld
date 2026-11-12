extends RefCounted

var id: int
var seed_value: int
var width: int
var height: int
var colors: int
var moves: int
var target: int

static func from_dict(d: Dictionary) -> RefCounted:
	var l = new()
	l.id = int(d["id"])
	l.seed_value = int(d["seed"])
	l.width = int(d["width"])
	l.height = int(d["height"])
	l.colors = int(d["colors"])
	l.moves = int(d["moves"])
	l.target = int(d["target"])
	return l

static func load_all(path: String = "res://levels/levels.json") -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_ARRAY:
		return []
	var out := []
	for d in data:
		out.append(from_dict(d))
	return out

func stars_for(score: int) -> int:
	if score >= target * 2:
		return 3
	if score >= target * 3 / 2:
		return 2
	if score >= target:
		return 1
	return 0
