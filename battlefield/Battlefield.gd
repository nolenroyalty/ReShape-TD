extends Node2D

onready var indicator = $BuildingIndicator
onready var buildable = $BuildableGrid

func move_building_indicator(pos):
	indicator.position = pos + buildable.global_position
	indicator.can_build()

func hide_building_indicator():
	indicator.hidden()

func _ready():
	buildable.connect("mouse_buildable_grid_position", self, "move_building_indicator")
	buildable.connect("mouse_left_buildable_grid", self, "hide_building_indicator")