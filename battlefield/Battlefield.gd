extends Node2D

onready var indicator = $BuildingIndicator
onready var buildable = $BuildableGrid

var current_build_location = null

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

func _ready():
	buildable.connect("mouse_buildable_grid_position", self, "move_building_indicator")
	buildable.connect("mouse_left_buildable_grid", self, "hide_building_indicator")