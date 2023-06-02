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

func is_horizontal():
	return WIDTH > HEIGHT

func starting_points():
	var points = []
	var width
	var height

	if is_horizontal():
		width = WIDTH
		height = HEIGHT - 1
	else:
		width = WIDTH - 1
		height = HEIGHT

	for x in range(width):
		for y in range(height):
			points.append(U.v(x, y) * C.CELL_SIZE)
	return points
	
func random_starting_point():
	var points = starting_points()
	var choice = rng.randi_range(0, len(points) - 1)
	return points[choice]

func get_center_point():
	return U.v(WIDTH / 2, HEIGHT / 2) * C.CELL_SIZE

func _ready():
	# Not sure if this is inherited otherwise
	add_to_group("pathable")
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _on_Bounds_area_entered(area:Area2D):
	print("Creep entered! %s <- %s" % [self, area.get_parent()])
	area.get_parent().notify_reached_destination()
