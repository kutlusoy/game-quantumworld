extends RefCounted

static func all() -> Array:
	return [
		{
			"name": "Rin", "age": 21, "gender": "female", "seed": 11, "curve": 0.5, "top": "crop", "sleeves": "none", "expression": "friendly",
			"skin": Color("ffe3d2"), "brow": Color("1f4f8f"),
			"hair_style": "bob", "hair_color": Color("3fa0ff"), "hair_hl": Color("c4ecff"),
			"eye_top": Color("6a1257"), "eye_bottom": Color("ff7cc0"),
			"jacket": Color("262d55"), "trim": Color("4dd4ff"), "pants": Color("1c2038"), "boots": Color("e9edff"),
			"accessories": ["headphones"], "accent": Color("ff5d96"), 
		},
		{
			"name": "Kaito", "age": 27, "gender": "male", "seed": 23, "muscle": 0.55, "expression": "neutral",
			"skin": Color("f3d2bb"), "brow": Color("16102a"),
			"hair_style": "spiky", "hair_color": Color("261c45"), "hair_hl": Color("8b74d9"),
			"eye_top": Color("233a6b"), "eye_bottom": Color("86b6ff"),
			"jacket": Color("2d3040"), "trim": Color("d64550"), "pants": Color("181a24"), "boots": Color("3a3d4d"),
			"accessories": ["scarf", "coat"], "accent": Color("d64550"), 
		},
		{
			"name": "Mira", "age": 24, "gender": "female", "seed": 37, "curve": 0.65, "expression": "friendly",
			"skin": Color("ffe6dc"), "brow": Color("7a68c4"),
			"hair_style": "long", "hair_color": Color("b9a6ff"), "hair_hl": Color("ffffff"),
			"eye_top": Color("0b5f6b"), "eye_bottom": Color("78f5dc"),
			"jacket": Color("f1efff"), "trim": Color("8d7bd6"), "pants": Color("2b4b63"), "boots": Color("8d7bd6"),
			"accessories": ["glasses"], "accent": Color("8d7bd6"), 
		},
		{
			"name": "Ren", "age": 23, "gender": "male", "seed": 41, "muscle": 0.95, "top": "tank", "sleeves": "none", "expression": "friendly",
			"skin": Color("e9bf9c"), "brow": Color("7a2a10"),
			"hair_style": "spiky", "hair_color": Color("ff5a2e"), "hair_hl": Color("ffd3a0"),
			"eye_top": Color("7a3d00"), "eye_bottom": Color("ffd24d"),
			"jacket": Color("3c5c4b"), "trim": Color("f2b441"), "pants": Color("5b4a36"), "boots": Color("2a2a2a"),
			"accessories": ["goggles"], "accent": Color("f2b441"), 
		},
		{
			"name": "Sora", "age": 20, "gender": "female", "seed": 53, "curve": 0.5, "legwear": "shorts", "top": "tank", "sleeves": "none", "expression": "friendly",
			"skin": Color("fbd9c8"), "brow": Color("0f7a5c"),
			"hair_style": "ponytail", "hair_color": Color("2fd8a0"), "hair_hl": Color("dcfff2"),
			"eye_top": Color("42207a"), "eye_bottom": Color("c08cff"),
			"jacket": Color("5b45a8"), "trim": Color("ffb199"), "pants": Color("3a3a4f"), "boots": Color("ffb199"),
			"accessories": [], "accent": Color("ffb199"), 
		},
	]

static func get_preset(i: int) -> Dictionary:
	var a := all()
	return a[i % a.size()]
