extends Node2D

class Tower extends Node:
	var RANGE_RADIUS = 64
	
	# Lower is better
	var ATTACK_SPEED = 1.0

	var PROJECTILE_COUNT = 1

class Bullet extends Node:
	var SPLIT = 0
	var PIERCE = 0

var shapes = [ C.SHAPE.CROSS, C.SHAPE.CRESCENT, C.SHAPE.DIAMOND ]	
var state = {}

func tower(shape):
	return state[shape][0]

func bullet(shape):
	return state[shape][1]

func _ready():
	for shape in shapes:
		state[shape] = [null, null]
		state[shape][0] = Tower.new()
		state[shape][1] = Bullet.new()

	tower(C.SHAPE.CROSS).PROJECTILE_COUNT = 2
	tower(C.SHAPE.CRESCENT).PROJECTILE_COUNT = 3
	tower(C.SHAPE.DIAMOND).RANGE_RADIUS = 256
