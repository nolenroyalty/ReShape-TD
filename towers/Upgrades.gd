extends Node2D

enum T {
	CHILLS,
	EXPLODES,
	# BURNING_GROUND,
	PIERCES,
	CHAINS,
	LESSER_MULTIPROJ,
	GREATER_MULTIPROJ,
	STUNNING,
	BONUS_GOLD,
	GIANT_PROJ,
	RETURNS,
	POISONS
}

class Stats extends Node:
	var upgrades = []
	var CHILLS = false
	var EXPLODES = false
# 	var BURNING_GROUND = false
	var PIERCES = 0
	var CHAINS = 0
	var PROJECTILES = 1
	var STUNS = false
	var BONUS_GOLD = 0
	var PROJECTILE_SIZE_MULT = 1
	var RETURNS = false
	var POISONS = false
	var DAMAGE_MULT = 1.0

func _apply(t, stats):
	match t:
		T.CHILLS: stats.CHILLS = true
		T.EXPLODES: stats.EXPLODES = true
	# 	T.BURNING_GROUND: stats.BURNING_GROUND = true
		T.PIERCES: stats.PIERCES = 2
		T.CHAINS: stats.CHAINS = 2
		T.LESSER_MULTIPROJ: 
			stats.PROJECTILES = 3
			stats.DAMAGE_MULT = 0.75
		T.GREATER_MULTIPROJ:
			stats.PROJECTILES = 5
			stats.DAMAGE_MULT = 0.5
		T.STUNNING: stats.STUNS = true
		T.BONUS_GOLD: stats.BONUS_GOLD = 0.25
		T.GIANT_PROJ: stats.PROJECTILE_SIZE_MULT = 2.5
		T.RETURNS: stats.RETURNS = true
		T.POISONS: stats.POISONS = true
	
	stats.upgrades.append(t)
	return stats

# IMPLEMENTED:
# CHILLS = true
# EXPLODES = true
# BURNING_GROUND = false
# PIERCES = true
# CHAINS = true
# PROJECTILES = true
# STUNS = true
# BONUS_GOLD = false
# PROJECTILE_SIZE_MULT = true
# RETURNS = true
# POISONS = true
# DAMAGE_MULT = true

func title(t):
	match t:
		T.CHILLS: return "Chilling"
		T.EXPLODES: return "Explosive"
	#	T.BURNING_GROUND: return "Burning"
		T.PIERCES: return "Piercing"
		T.CHAINS: return "Chaining"
		T.LESSER_MULTIPROJ: return "Multishotting"
		T.GREATER_MULTIPROJ: return "MegaMultishotting"
		T.STUNNING: return "Stunning"
		T.BONUS_GOLD: return "Avaricious"
		T.GIANT_PROJ: return "Giant"
		T.RETURNS: return "Returning"
		T.POISONS: return "Poisoning"

func description(t):
	match t:
		T.CHILLS: return "Slows enemies"
		T.EXPLODES: return "Explodes on impact"
	#	T.BURNING_GROUND: return "Leaves burning ground that deals damage over time"
		T.PIERCES: return "Pierces enemies"
		T.CHAINS: return "Chains to nearby enemies"
		T.LESSER_MULTIPROJ: return "Shoots 3 projectiles but does less damage"
		T.GREATER_MULTIPROJ: return "Shoots 5 projectiles but does much less damage"
		T.STUNNING: return "Has a chance to stun enemies on hit"
		T.BONUS_GOLD: return "Gives 25% more gold for kills"
		T.GIANT_PROJ: return "Shoots much larger projectiles"
		T.RETURNS: return "Returns to the tower after hitting an enemy"
		T.POISONS: return "Poisons enemies, dealing damage over time"

class IndividualTower extends Node:
	var LEVEL = 1
	var RANGE_RADIUS = 64
	var ATTACK_SPEED = 1.0
	var PROJECTILE_COUNT = 1
	var DAMAGE = 10
	var PROJECTILE_SPEED = 225

	func level_up():
		LEVEL += 1
		RANGE_RADIUS += 16
		ATTACK_SPEED -= 0.1 * ATTACK_SPEED
		DAMAGE *= 2
	
	func attacks_per_second():
		return 1.0 / ATTACK_SPEED

var shapes = [ C.SHAPE.CROSS, C.SHAPE.CRESCENT, C.SHAPE.DIAMOND ]	
var state = {}

func all_upgrades():
	return T.values()

func active_upgrades(shape):
	return state[shape].upgrades

func possible_upgrades(shape):
	var possible = []
	for t in all_upgrades():
		if not (t in active_upgrades(shape)):
			possible.append(t)
	return possible

func upgrade(shape, t):
	state[shape] = _apply(t, state[shape])

func projectiles(t):
	return state[t].PROJECTILES

func pierces(t):
	return state[t].PIERCES

func chains(t):
	return state[t].CHAINS

func damage_mult(t):
	return state[t].DAMAGE_MULT

func has_chill(t):
	return state[t].CHILLS

func has_poison(t):
	return state[t].POISONS

func has_stun(t):
	return state[t].STUNS

func has_return(t):
	return state[t].RETURNS

func explodes(t):
	return state[t].EXPLODES

func projectile_size_mult(t):
	return state[t].PROJECTILE_SIZE_MULT

func _ready():
	for shape in shapes:
		state[shape] = Stats.new()
