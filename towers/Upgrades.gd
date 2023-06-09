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
	POISONS,
	FARSHOT,
	GENEROUS,
	POWERFUL
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
	var FARSHOT = false
	var DAMAGE_MULT = 1.0
	var GENEROUS = false
	var POWERFUL = false

	func build_cost():
		return (len(upgrades) + 1) * C.BASE_TOWER_COST
	
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
			stats.DAMAGE_MULT *= 0.7
		T.GREATER_MULTIPROJ:
			stats.PROJECTILES = 5
			stats.DAMAGE_MULT *= 0.45
		T.STUNNING: stats.STUNS = true
		T.BONUS_GOLD: stats.BONUS_GOLD = 0.25
		T.GIANT_PROJ: stats.PROJECTILE_SIZE_MULT = 2.5
		T.RETURNS: stats.RETURNS = true
		T.POISONS: stats.POISONS = true
		T.FARSHOT: stats.FARSHOT = true
		T.GENEROUS: 
			stats.GENEROUS = true
			stats.DAMAGE_MULT *= 0.5
		T.POWERFUL:
			stats.POWERFUL = true
			stats.DAMAGE_MULT *= 1.35
	
	stats.upgrades.append(t)
	return stats


func title(t):
	match t:
		T.CHILLS: return "Chilling"
		T.EXPLODES: return "Explosive"
	#	T.BURNING_GROUND: return "Burning"
		T.PIERCES: return "Piercing"
		T.CHAINS: return "Chaining"
		T.LESSER_MULTIPROJ: return "Multishot"
		T.GREATER_MULTIPROJ: return "MegaMultishot"
		T.STUNNING: return "Stunning"
		T.BONUS_GOLD: return "Avaricious"
		T.GIANT_PROJ: return "Giant"
		T.RETURNS: return "Returning"
		T.POISONS: return "Poisoning"
		T.FARSHOT: return "Farshot"
		T.GENEROUS: return "Generous"
		T.POWERFUL: return "Powerful"

class Requirements extends Node:
	var all_of = {}
	var any_of = []
	var none_of = []
	var length = 0

	func matches(upgrades):
		if len(upgrades) < length:
			return false

		for t in all_of:
			if not (t in upgrades):
				return false
		
		for t in none_of:
			if t in upgrades:
				return false
		
		if len(any_of) == 0:
			return true
		else:
			for t in any_of:
				if t in upgrades:
					return true
			return false

func requires(t):
	var r = Requirements.new()
	match t:
		T.CHILLS:
			pass
		T.EXPLODES:
			pass
		T.PIERCES:
			r.length = 1
			r.none_of = [ T.CHAINS ]
		T.CHAINS:
			r.length = 0
			r.none_of = [T.PIERCES]
		T.LESSER_MULTIPROJ:
			r.length = 0
			r.none_of = [ T.GREATER_MULTIPROJ ]
		T.GREATER_MULTIPROJ:
			r.length = 1
			r.none_of = [ T.LESSER_MULTIPROJ ]
		T.STUNNING:
			r.length = 2
		T.BONUS_GOLD: 
			r.length = 1
		T.GIANT_PROJ: 
			r.any_of = [ T.EXPLODES, T.PIERCES, T.CHAINS ]
			r.length = 2
		T.RETURNS: 
			r.any_of = [ T.PIERCES, T.CHAINS, T.LESSER_MULTIPROJ, T.GREATER_MULTIPROJ]
			r.length = 2
		T.POISONS: 
			pass
		T.FARSHOT:
			r.any_of = [T.PIERCES, T.CHAINS, T.LESSER_MULTIPROJ, T.GREATER_MULTIPROJ]
			r.length = 1
		T.GENEROUS: 
			r.length = 1
			r.none_of = [T.POWERFUL]
		T.POWERFUL:
			r.length = 2
			r.none_of = [T.GENEROUS]
	
	return r

func description(t):
	match t:
		T.CHILLS: return "Projectiles have slow enemies"
		T.EXPLODES: return "Projectiles explode on impact"
	#	T.BURNING_GROUND: return "Leaves burning ground that deals damage over time"
		T.PIERCES: return "Projectiles pierce up to 2 enemies"
		T.CHAINS: return "Projectiles chain to up to 2 nearby enemies"
		T.LESSER_MULTIPROJ: return "Shoots 3 projectiles but does 30% less damage"
		T.GREATER_MULTIPROJ: return "Shoots 5 projectiles but does 55% less damage"
		T.STUNNING: return "Projectiles have a 10% chance to stun enemies"
		T.BONUS_GOLD: return "Tower earns 25% more gold for kills"
		T.GIANT_PROJ: return "Projectiles are much larger"
		T.RETURNS: return "Projectiles return to the tower after hitting an enemy"
		T.POISONS: return "Projectiles deal an additional 50% of the tower's damage over time"
		T.FARSHOT: return "Projectiles deal up to 100% more damage the farther they travel"
		T.GENEROUS: return "Deals 50% less damage but gives a stacking 15% damage buff to other towers in range"
		T.POWERFUL: return "Deals 35% more damage"

class IndividualTower extends Node:
	var LEVEL = 1
	var RANGE_RADIUS = 64
	var ATTACK_SPEED = 1.0
	var PROJECTILE_COUNT = 1
	var DAMAGE = 10
	var PROJECTILE_SPEED = 225
	var STATUS_MULTIPLIER = 1.0
	var _GENEROUS_STACKS = 0
	
	func generous_mult():
		return 1.0 + + C.GENEROUS_TOWER_BONUS * _GENEROUS_STACKS

	func level_damage():
		match LEVEL:
			1: return 10
			2: return 25
			3: return 50
			4: return 100
			5: return 250
	
	func range_radius():
		match LEVEL:
			1: return 64
			2: return 80
			3: return 96
			4: return 112
			5: return 144
	
	func attack_speed():
		match LEVEL:
			1: return 1.0
			2: return 0.9
			3: return 0.85
			4: return 0.7
			5: return 0.65
	
	func status_multiplier():
		match LEVEL:
			1: return 1.0
			2: return 1.2
			3: return 1.5
			4: return 1.8
			5: return 2.5

	func set_generous_stacks(stacks):
		_GENEROUS_STACKS = stacks
		DAMAGE = level_damage() * generous_mult()

	func level_up():
		LEVEL += 1
		DAMAGE = level_damage() * generous_mult()
		RANGE_RADIUS = range_radius()
		ATTACK_SPEED = attack_speed()
		STATUS_MULTIPLIER = status_multiplier()
	
	func rank_up_base_cost():
		match LEVEL:
			1: return 20
			2: return 60
			3: return 150
			4: return 350
			5:
				print("why are we asking for the rank up cost of a level 5 tower")
				return 500
	
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
	var used = {}
	var active = active_upgrades(shape)

	if len(active) == C.MAX_UPGRADES:
		return []
	
	for s in shapes:
		for t in active_upgrades(s):
			used[t] = true

	for t in all_upgrades():
		if not (t in used):
			var req = requires(t)
			if req.matches(active):
				possible.append(t)

	return possible

func tower_cost(shape):
	return int(state[shape].build_cost())

var first_reshape = true
func reshape_cost(shape):
	if first_reshape: return 0
	else: return int(state[shape].reshape_cost())

func rank_up_cost(shape, stats):
	if stats.LEVEL == C.MAX_LEVEL:
		return null

	var base_cost = stats.rank_up_base_cost()
	var mult = 1.0 + 0.10 * len(active_upgrades(shape))
	return int(base_cost * mult)

func upgrade(shape, t):
	first_reshape = false
	state[shape] = _apply(t, state[shape])
	emit_signal("reshaped", shape, t)

func farshot(t):
	return state[t].FARSHOT

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

func generous(t):
	return state[t].GENEROUS

func projectile_size_mult(t):
	return state[t].PROJECTILE_SIZE_MULT

func reset():
	first_reshape = true
	for shape in shapes:
		state[shape] = Stats.new()

func _ready():
	reset()
