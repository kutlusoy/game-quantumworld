extends RefCounted

var list: Array = []
var active := -1
var ticks := 0
var armed: Array = []
var cooldown := 0

func _init(challenges: Array) -> void:
	list = challenges
	for c in list:
		armed.append(false)

func active_challenge():
	return list[active] if active >= 0 else null

func update(sim, ev: Dictionary) -> Array:
	var events := []
	if cooldown > 0:
		cooldown -= 1
	if active < 0:
		for i in list.size():
			var inside: bool = list[i].in_ring(list[i].start, sim.px, sim.py, sim.pz)
			if inside and armed[i] and cooldown == 0:
				active = i
				ticks = 0
				events.append({"type": "start", "id": list[i].id})
				break
			armed[i] = not inside
		return events
	ticks += 1
	var ch = list[active]
	if ev["respawned"]:
		events.append({"type": "fail", "id": ch.id, "reason": "fell"})
		_stop()
	elif ticks > ch.limit:
		events.append({"type": "fail", "id": ch.id, "reason": "time"})
		_stop()
	elif ch.kind == "parkour":
		if ticks > 20 and ch.in_ring(ch.finish, sim.px, sim.py, sim.pz):
			events.append({"type": "finish", "id": ch.id, "tier": ch.tier_for(ticks), "ticks": ticks})
			_stop()
	elif ch.kind == "shard_run":
		var all_done := true
		for k in ch.required:
			if sim.collected[k] == 0:
				all_done = false
		if all_done:
			events.append({"type": "finish", "id": ch.id, "tier": ch.tier_for(ticks), "ticks": ticks})
			_stop()
	return events

func _stop() -> void:
	active = -1
	cooldown = 90
	for i in armed.size():
		armed[i] = false
