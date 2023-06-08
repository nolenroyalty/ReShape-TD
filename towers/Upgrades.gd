extends Node2D

signal reshaped(shape, upgrade)

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

	func build_cost():
		var mult = pow(2, len(upgrades))
		return mult * C.BASE_TOWER_COST
	
	func reshape_cost():
		var mult = pow(2, len(upgrades))
		return mult * 75

func _apply(t, stats):
	match t:
		T.CHILLS: stats.CHILLS = true
		T.EXPLODES: stats.EXPLODES = true
	# 	T.BURNING_GROUND: stats.BURNING_GROUND = true
		T.PIERCES: stats.PIERCES = 2
		T.CHAINS: stats.CHAINS = 2
		T.LESSER_MULTIPROJ: 
			stats.PROJECTILES = 3
			stats.DAMAGE_MULT = 0.7
		T.GREATER_MULTIPROJ:
			stats.PROJECTILES = 5
			stats.DAMAGE_MULT = 0.45
		T.STUNNING: stats.STUNS = true
		T.BONUS_GOLD: stats.BONUS_GOLD = 0.25
		T.GIANT_PROJ: stats.PROJECTILE_SIZE_MULT = 2.5
		T.RETURNS: stats.RETURNS = true
		T.POISONS: stats.POISONS = true
	
	stats.upgrades.append(t)
	return stats

func excludes(t):
	match t:
		T.LESSER_MULTIPROJ: return [ T.GREATER_MULTIPROJ ]
		T.GREATER_MULTIPROJ: return [ T.LESSER_MULTIPROJ ]
		T.PIERCES: return [ T.CHAINS ]
		T.CHAINS: return [ T.PIERCES ]
		_: return []

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
		T.CHILLS: return "Projectiles have a high chance to slow enemies"
		T.EXPLODES: return "Projectiles explode on impact"
	#	T.BURNING_GROUND: return "Leaves burning ground that deals damage over time"
		T.PIERCES: return "Projectiles pierce up to 2 enemies"
		T.CHAINS: return "Projectiles chain to up to 2 nearby enemies"
		T.LESSER_MULTIPROJ: return "Shoots 3 projectiles but does 30% less damage"
		T.GREATER_MULTIPROJ: return "Shoots 5 projectiles but does 55% less damage"
		T.STUNNING: return "Projectiles have a low chance to stun enemies"
		T.BONUS_GOLD: return "Tower earns 25% more gold for kills"
		T.GIANT_PROJ: return "Projectiles are much larger"
		T.RETURNS: return "Projectiles return to the tower after hitting an enemy"
		T.POISONS: return "Projectiles deal 50%x of the tower's damage over time"

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
	
	func upgrade_mult():
		return pow(C.UPGRADE_COST_MULT, LEVEL)
	
	func attacks_per_second():
		return 1.0 / ATTACK_SPEED

var shapes = [ C.SHAPE.CROSS, C.SHAPE.CRESCENT, C.SHAPE.DIAMOND ]	
var state = {}

func all_upgrades():
	return T.values()

func active_upgrades(shape):
	return state[shape].upgrades

func possible_upgrades(shape):
	# Add exclusions
	var possible = []
	var excluded = {}
	var used = {}
	for t in active_upgrades(shape):
		for exclude in excludes(t):
			excluded[exclude] = true
	
	for s in shapes:
		for t in active_upgrades(s):
			used[t] = true

	for t in all_upgrades():
		if not (t in used) and not (t in excluded):
			possible.append(t)
		# if not (t in active_upgrades(shape)) and not (t in excluded):
			# possible.append(t)

	return possible

func tower_cost(shape):
	return int(state[shape].build_cost())

func reshape_cost(shape):
	return int(state[shape].reshape_cost())

func upgrade_cost(shape, stats):
	var base = tower_cost(shape)
	var mult = stats.upgrade_mult()
	return int(base * mult)

func upgrade(shape, t):
	state[shape] = _apply(t, state[shape])
	emit_signal("reshaped", shape, t)

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

func bonus_gold(t):
	return state[t].BONUS_GOLD

func projectile_size_mult(t):
	return state[t].PROJECTILE_SIZE_MULT

func _ready():
	for shape in shapes:
		state[shape] = Stats.new()
