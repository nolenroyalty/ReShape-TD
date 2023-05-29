extends Node2D

class_name CreepArea

var WIDTH = 0
var HEIGHT = 0
var rng

func pathable_points():
	var points = []
	for x in range(WIDTH):
		for y in range(HEIGHT):
			points.append(U.v(x, y) * C.CELL_SIZE)
	return points

func get_random_point():
	var x = rng.randi_range(0, WIDTH - 1)
	var y = rng.randi_range(0, HEIGHT - 1)
	return U.v(x, y) * C.CELL_SIZE

func _ready():
	# Not sure if this is inherited otherwise
	add_to_group("pathable")
	rng = RandomNumberGenerator.new()
	rng.randomize()
