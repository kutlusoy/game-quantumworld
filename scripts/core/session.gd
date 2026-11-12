extends RefCounted

const Board = preload("res://scripts/core/board.gd")

var level
var board
var moves_left: int
var score := 0
var log := []

func _init(l) -> void:
	level = l
	board = Board.new(l.width, l.height, l.colors, l.seed_value)
	moves_left = l.moves

func is_over() -> bool:
	return moves_left <= 0

func play(a: Vector2i, b: Vector2i) -> Dictionary:
	if is_over():
		return {"valid": false, "steps": [], "score": 0}
	var r: Dictionary = board.play_move(a, b)
	if r["valid"]:
		moves_left -= 1
		score += r["score"]
		log.append([a.x, a.y, b.x, b.y])
	return r

func stars() -> int:
	return level.stars_for(score)
