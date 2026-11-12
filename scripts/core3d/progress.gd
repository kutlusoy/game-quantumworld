extends RefCounted

const MAX_LEVEL := 50
const TIER_XP := [100, 60, 30, 10]
const SHARD_XP := 5

var xp := 0
var tiers := {}

static func xp_for_level(level: int) -> int:
	return 50 * (level - 1) * level / 2

func level() -> int:
	var l := 1
	while l < MAX_LEVEL and xp >= xp_for_level(l + 1):
		l += 1
	return l

func level_fraction() -> float:
	var l := level()
	if l >= MAX_LEVEL:
		return 1.0
	var a := xp_for_level(l)
	var b := xp_for_level(l + 1)
	return float(xp - a) / float(b - a)

func add_xp(n: int) -> int:
	var before := level()
	xp += n
	return level() - before

func best_tier(id: String) -> int:
	return int(tiers.get(id, 99))

func record_tier(id: String, tier: int) -> int:
	var best := best_tier(id)
	var old_xp: int = TIER_XP[best] if best <= 3 else 0
	var new_xp: int = TIER_XP[tier]
	if tier < best:
		tiers[id] = tier
	return maxi(new_xp - old_xp, 0)

func to_dict() -> Dictionary:
	return {"xp": xp, "tiers": tiers}

static func from_dict(d: Dictionary):
	var p = new()
	p.xp = int(d.get("xp", 0))
	p.tiers = d.get("tiers", {})
	return p
