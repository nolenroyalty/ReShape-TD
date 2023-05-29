extends Node2D

onready var indicator = $BuildingIndicator
onready var buildable = $BuildableGrid
onready var grid = $PathingGrid

var Creep = preload("res://creeps/CreepGeneric.tscn")

var current_build_location = null
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

# func can_currently_build(pos):
# 	var relevant_positions = []
# 	for dx in [0, C.CELL_SIZE]:
# 		for dy in [0, C.CELL_SIZE]:
# 			relevant_positions.append(pos + U.v(dx, dy))
	
# 	return true

func move_building_indicator(pos):
	current_build_location = pos + buildable.position
	indicator.position = current_build_location
	indicator.begin_showing()
	
func hide_building_indicator():
	current_build_location = null
	indicator.begin_hiding()

func init_pathing_grid():
	var all_points = []
	for child in get_tree().get_nodes_in_group("pathable"):
		var offset = U.snap_to_grid(child.position)
		assert(offset == child.position, "CHILD NOT ON GRID: %s" % [child])
		
		var pp = len(child.pathable_points()) < 50
		if pp: print(child)
		for point in child.pathable_points():
			point += offset
			if pp: print(point)
			all_points.append(point)
	
	grid.init(all_points)
	
func spawn_creep():
	var i = rng.randi_range(0, 1)
	var vertical = i == 0
	var start
	var end
	
	if vertical:
		start = $SpawnTop.get_random_point()
		end = $DestBot.get_random_point()
	else:
		start = $SpawnLeft.get_random_point()
		end = $DestRight.get_random_point()
	
	var creep = Creep.instance()
	creep.position = U.center(start)
	creep.init(end)
	add_child(creep)

func _process(_delta):
	if Input.is_action_just_pressed("DEBUG_SPAWN"):
		spawn_creep()

func _ready():
	buildable.connect("mouse_buildable_grid_position", self, "move_building_indicator")
	buildable.connect("mouse_left_buildable_grid", self, "hide_building_indicator")
	init_pathing_grid()
	U.GRID = grid
	rng.randomize()
