extends RefCounted

var _state: int

func _init(seed_value: int = 1) -> void:
	_state = (seed_value * 2654435761 + 1) & 0xFFFFFFFF
	if _state == 0:
		_state = 1

func next_u32() -> int:
	var x := _state
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= x >> 17
	x ^= (x << 5) & 0xFFFFFFFF
	_state = x
	return x

func next_int(n: int) -> int:
	return next_u32() % n
