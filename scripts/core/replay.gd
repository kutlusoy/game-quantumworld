extends RefCounted

const Session = preload("res://scripts/core/session.gd")

static func run(level, moves: Array) -> Dictionary:
	var s = Session.new(level)
	for m in moves:
		if s.is_over() or m.size() != 4:
			return {"valid": false}
		var r: Dictionary = s.play(Vector2i(m[0], m[1]), Vector2i(m[2], m[3]))
		if not r["valid"]:
			return {"valid": false}
	return {
		"valid": true,
		"score": s.score,
		"stars": s.stars(),
		"fingerprint": s.board.fingerprint(),
		"moves_used": s.log.size(),
	}
