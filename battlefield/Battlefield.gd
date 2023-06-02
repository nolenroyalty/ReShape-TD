extends Node2D

signal selected_creep(creep)
signal selected_tower(tower)

onready var indicator = $BuildingIndicator
onready var buildable = $BuildableGrid
onready var grid = $PathingGrid

var Creep = preload("res://creeps/CreepGeneric.tscn")
var Tower = preload("res://towers/Tower.tscn")

enum S { PLAYING, IN_MENU }

var current_build_location = null
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var selected_shape = null
var state = S.PLAYING
var selected_creep_or_tower = null

func move_building_indicator(pos):
	current_build_location = pos + buildable.position
	indicator.position = current_build_location
	indicator.begin_showing()
	
func hide_building_indicator():
	current_build_location = null
	indicator.begin_hiding()

func notify_creeps_of_pathing_change():
	get_tree().call_group("creep", "update_current_path")

func have_the_money_to_place_tower():
	return true

func disable_pathing_for_tower(pos):
	var points = []
	for dx in [0, C.CELL_SIZE]:
		for dy in [0, C.CELL_SIZE]:
			points.append(pos + U.v(dx, dy))
	
	grid.disable_points(points)

func tower_selected(tower):
	emit_signal("selected_tower", tower)

func creep_selected(creep):
	emit_signal("selected_creep", creep)

func actually_build_tower(location):
	var tower = Tower.instance()
	tower.init(selected_shape)
	tower.position = current_build_location
	disable_pathing_for_tower(location)
	tower.connect("selected", self, "tower_selected", [tower])
	add_child(tower)
	
func try_to_build_tower(_event):
	if not indicator.unblocked():
		return
	
	# Maybe double-check that we can build here, I don't know
	if not have_the_money_to_place_tower():
		return

	actually_build_tower(current_build_location)
	notify_creeps_of_pathing_change()
	hide_building_indicator()

func init_pathing_grid():
	var all_points = []
	for child in get_tree().get_nodes_in_group("pathable"):
		var offset = U.snap_to_grid(child.position)
		assert(offset == child.position, "CHILD NOT ON GRID: %s" % [child])
		
		for point in child.pathable_points():
			point += offset
			all_points.append(point)
	
	grid.init(all_points)

func init_creep(start, end):
	var creep = Creep.instance()
	creep.position = start
	creep.init(end)
	creep.connect("selected", self, "creep_selected", [creep])
	add_child(creep)
	
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
	
	init_creep(start, end)

func handle_event__playing(event):
	if event is InputEventMouseButton:
		if current_build_location != null and event.pressed and event.button_index == BUTTON_LEFT:
			try_to_build_tower(event)

func handle_keypresses__playing(_delta):
	if Input.is_action_just_pressed("DEBUG_SPAWN"):
		spawn_creep()
	if Input.is_action_just_pressed("DEBUG_REFRESH_RANGE"):
		for child in get_tree().get_nodes_in_group("tower"):
			child.refresh_range()

func get_towers():
	return get_tree().get_nodes_in_group("tower")

func set_in_menu():
	state = S.IN_MENU

func set_playing():
	state = S.PLAYING

func set_shape(shape):
	selected_shape = shape
	# indicator.set_shape(shape)

func _input(event):
	match state:
		S.PLAYING: handle_event__playing(event)
		S.IN_MENU: pass
	
func _process(delta):
	match state:
		S.PLAYING: handle_keypresses__playing(delta)
		S.IN_MENU: pass

func _ready():
	buildable.connect("mouse_buildable_grid_position", self, "move_building_indicator")
	buildable.connect("mouse_left_buildable_grid", self, "hide_building_indicator")
	init_pathing_grid()
	U.GRID = grid
	rng.randomize()
