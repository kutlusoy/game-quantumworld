extends RefCounted

const PATH := "user://avatar.json"

const HAIR_STYLES := ["bob", "spiky", "long", "ponytail"]
const TOPS := ["jacket", "crop", "tank"]
const SLEEVES := ["long", "short", "none"]
const LEGWEAR := ["pants", "shorts"]
const EXPRESSIONS := ["friendly", "neutral"]
const ACCESSORIES := ["headphones", "glasses", "goggles", "scarf", "coat"]
const GENDERS := ["female", "male"]

const SKIN := ["ffe3d2", "f3d2bb", "e9bf9c", "d6a07c", "b57c58", "8a5a3c", "684330"]
const HAIR := [
	["3fa0ff", "c4ecff"], ["261c45", "8b74d9"], ["b9a6ff", "ffffff"], ["ff5a2e", "ffd3a0"],
	["2fd8a0", "dcfff2"], ["ff7cc0", "ffe0f0"], ["f2d16b", "fff6c8"], ["3a2a22", "a8805f"],
	["1a1a22", "6a6a8a"], ["e8e8f2", "ffffff"],
]
const EYES := [
	["6a1257", "ff7cc0"], ["233a6b", "86b6ff"], ["0b5f6b", "78f5dc"], ["7a3d00", "ffd24d"],
	["42207a", "c08cff"], ["2a5a2a", "9be07a"], ["4a2a1a", "c58a5a"],
]
const OUTFITS := [
	["262d55", "4dd4ff", "1c2038", "e9edff"], ["2d3040", "d64550", "181a24", "3a3d4d"],
	["f1efff", "8d7bd6", "2b4b63", "8d7bd6"], ["3c5c4b", "f2b441", "5b4a36", "2a2a2a"],
	["5b45a8", "ffb199", "3a3a4f", "ffb199"], ["f4f0e6", "e0457b", "2a3a5a", "ffffff"],
	["2b2b2b", "7dff9b", "202020", "444444"], ["b24a2e", "ffd37a", "3a2a20", "6a4a30"],
]

static func default_config() -> Dictionary:
	return {
		"name": "Rin", "gender": "female", "age": 22, "curve": 0.5, "muscle": 0.6,
		"hair_style": "bob", "hair": 0, "skin": 0, "eyes": 0, "outfit": 0,
		"top": "crop", "sleeves": "none", "legwear": "pants", "expression": "friendly",
		"accessories": ["headphones"], "seed": 11,
	}

static func clamp_config(c: Dictionary) -> Dictionary:
	var d := default_config()
	for k in d:
		if c.has(k) and typeof(c[k]) == typeof(d[k]):
			d[k] = c[k]
	d["gender"] = d["gender"] if d["gender"] in GENDERS else "female"
	d["age"] = clampi(int(d["age"]), 19, 30)
	d["curve"] = clampf(float(d["curve"]), 0.3, 0.75)
	d["muscle"] = clampf(float(d["muscle"]), 0.35, 0.95)
	d["hair_style"] = d["hair_style"] if d["hair_style"] in HAIR_STYLES else "bob"
	d["top"] = d["top"] if d["top"] in TOPS else "jacket"
	d["sleeves"] = d["sleeves"] if d["sleeves"] in SLEEVES else "long"
	d["legwear"] = d["legwear"] if d["legwear"] in LEGWEAR else "pants"
	d["expression"] = d["expression"] if d["expression"] in EXPRESSIONS else "friendly"
	d["hair"] = clampi(int(d["hair"]), 0, HAIR.size() - 1)
	d["skin"] = clampi(int(d["skin"]), 0, SKIN.size() - 1)
	d["eyes"] = clampi(int(d["eyes"]), 0, EYES.size() - 1)
	d["outfit"] = clampi(int(d["outfit"]), 0, OUTFITS.size() - 1)
	var acc := []
	for a in d["accessories"]:
		if a in ACCESSORIES and a not in acc:
			acc.append(a)
	d["accessories"] = acc
	d["name"] = String(d["name"]).substr(0, 12)
	d["seed"] = int(d["seed"])
	return d

static func to_params(c: Dictionary) -> Dictionary:
	c = clamp_config(c)
	var hair: Array = HAIR[c["hair"]]
	var eyes: Array = EYES[c["eyes"]]
	var o: Array = OUTFITS[c["outfit"]]
	var hair_color := Color(hair[0])
	return {
		"name": c["name"], "age": c["age"], "gender": c["gender"], "seed": c["seed"],
		"curve": c["curve"], "muscle": c["muscle"], "top": c["top"], "sleeves": c["sleeves"],
		"legwear": c["legwear"], "expression": c["expression"],
		"skin": Color(SKIN[c["skin"]]), "brow": hair_color.darkened(0.35),
		"hair_style": c["hair_style"], "hair_color": hair_color, "hair_hl": Color(hair[1]),
		"eye_top": Color(eyes[0]), "eye_bottom": Color(eyes[1]),
		"jacket": Color(o[0]), "trim": Color(o[1]), "pants": Color(o[2]), "boots": Color(o[3]),
		"accessories": c["accessories"].duplicate(), "accent": Color(o[1]),
	}

static func load_config() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return default_config()
	var f := FileAccess.open(PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return default_config()
	return clamp_config(data)

static func save_config(c: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(clamp_config(c)))

static func from_preset(i: int) -> Dictionary:
	var presets := [
		{"name": "Rin", "gender": "female", "age": 21, "curve": 0.5, "hair_style": "bob", "hair": 0, "skin": 0, "eyes": 0, "outfit": 0, "top": "crop", "sleeves": "none", "legwear": "pants", "accessories": ["headphones"], "seed": 11},
		{"name": "Kaito", "gender": "male", "age": 27, "muscle": 0.55, "hair_style": "spiky", "hair": 1, "skin": 1, "eyes": 1, "outfit": 1, "top": "jacket", "sleeves": "long", "expression": "neutral", "accessories": ["scarf", "coat"], "seed": 23},
		{"name": "Mira", "gender": "female", "age": 24, "curve": 0.65, "hair_style": "long", "hair": 2, "skin": 0, "eyes": 2, "outfit": 2, "top": "jacket", "sleeves": "long", "accessories": ["glasses"], "seed": 37},
		{"name": "Ren", "gender": "male", "age": 23, "muscle": 0.95, "hair_style": "spiky", "hair": 3, "skin": 2, "eyes": 3, "outfit": 3, "top": "tank", "sleeves": "none", "accessories": ["goggles"], "seed": 41},
		{"name": "Sora", "gender": "female", "age": 20, "curve": 0.5, "hair_style": "ponytail", "hair": 4, "skin": 0, "eyes": 4, "outfit": 4, "top": "tank", "sleeves": "none", "legwear": "shorts", "accessories": [], "seed": 53},
	]
	var d := default_config()
	for k in presets[i % presets.size()]:
		d[k] = presets[i % presets.size()][k]
	return clamp_config(d)
