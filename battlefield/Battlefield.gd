extends Node2D

signal selected_creep(creep)
signal selected_tower(tower)

onready var indicator = $BuildingIndicator
onready var buildable = $BuildableGrid
onready var grid = $PathingGrid
onready var spawn_timer = $SpawnTimer

var Creep = preload("res://creeps/CreepGeneric.tscn")
var Normal = preload("res://creeps/CreepNormal.tscn")
var NormalBoss = preload("res://creeps/NormalBoss.tscn")
var Thick = preload("res://creeps/CreepThick.tscn")
var ThickBoss = preload("res://creeps/ThickBoss.tscn")
var Quick = preload("res://creeps/CreepQuick.tscn")
var QuickBoss = preload("res://creeps/QuickBoss.tscn")
var Resist = preload("res://creeps/CreepResist.tscn")
var ResistBoss = preload("res://creeps/ResistantBoss.tscn")
var Tower = preload("res://towers/Tower.tscn")

enum S { PLAYING, IN_MENU }

var current_build_location = null
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var selected_shape = null
var state = S.PLAYING
var selected_creep_or_tower = null
var spawn_queue = []

func move_building_indicator(pos):
	current_build_location = pos + buildable.position
	indicator.position = current_build_location
	indicator.begin_showing()
	
func hide_building_indicator():
	current_build_location = null
	indicator.begin_hiding()

func notify_creeps_of_pathing_change():
	get_tree().call_group("creep", "update_current_path")

func relevant_points_for_tower(pos):
	var points = []
	for dx in [0, C.CELL_SIZE]:
		for dy in [0, C.CELL_SIZE]:
			points.append(pos + U.v(dx, dy))
	
	return points

func disable_pathing_for_tower(pos):
	grid.disable_points(relevant_points_for_tower(pos))

func enable_pathing_for_tower(pos):
	grid.enable_points(relevant_points_for_tower(pos))

func tower_selected(tower):
	emit_signal("selected_tower", tower)

func creep_selected(creep):
	emit_signal("selected_creep", creep)

func handle_tower_sold(tower):
	enable_pathing_for_tower(tower.position)
	notify_creeps_of_pathing_change()

func actually_build_tower(location):
	var tower = Tower.instance()
	tower.init(selected_shape)
	tower.position = current_build_location
	disable_pathing_for_tower(location)
	tower.connect("selected", self, "tower_selected", [tower])
	tower.connect("sold", self, "handle_tower_sold", [tower])
	add_child(tower)
	
func try_to_build_tower(_event):
	if not indicator.unblocked():
		return
	if selected_shape == null:
		return

	# Maybe double-check that we can build here, I don't know
	var cost = Upgrades.tower_cost(selected_shape)
	if not State.try_to_buy(cost):
		print("Not enough money to place tower!")
		# play sound?
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

func add_creep_soon(creep):
	var wait_time = rng.randf() * 0.2
	yield(get_tree().create_timer(wait_time), "timeout")
	add_child(creep)

func spawn(vertical):
	if vertical: return $SpawnLeft
	else: return $SpawnTop

func dest(vertical):
	if vertical: return $DestRight
	else: return $DestBot

var last_vertical = null
var last_horizontal = null
func pop_from_spawn_queue():
	spawn_timer.start()
	var creep_info = spawn_queue.pop_front()
	var CreepKind = creep_info[0]
	var level = creep_info[1]
	for vertical in [ true, false]:
		var start_area = spawn(vertical)
		var end_area = dest(vertical)

		var points = start_area.starting_points
		var idx = rng.randi_range(0, len(points) - 1)
		if vertical:
			if idx == last_vertical: 
				idx += 1
			last_vertical = idx
		else:
			if idx == last_horizontal:
				idx += 1
			last_horizontal = idx
		
		var start = points[idx % len(points)] + U.snap_to_grid(start_area.position)
		var end = end_area.get_center_point() + U.snap_to_grid(end_area.position)
		var creep = CreepKind.instance()
		creep.position = U.center(start)
		creep.init(level, end)
		creep.connect("selected", self, "creep_selected", [creep])
		add_creep_soon(creep)

func handle_event__playing(event):
	if event is InputEventMouseButton:
		if current_build_location != null and event.pressed and event.button_index == BUTTON_LEFT:
			try_to_build_tower(event)

func add_to_spawn_queue(creep, count, level):
	for _i in range(count):
		spawn_queue.append([creep, level])

func handle_keypresses__playing(_delta):
	if Input.is_action_just_pressed("DEBUG_SPAWN_WAVES"):
		add_to_spawn_queue(QuickBoss, 1, 2)
	if Input.is_action_just_pressed("DEBUG_SPAWN_TEST"):
		add_to_spawn_queue(Normal, 5, 1)
		# spawn_waves(NormalBoss, 2, 1)
		# spawn_waves(Thick, 2)
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

func _input(event):
	match state:
		S.PLAYING: handle_event__playing(event)
		S.IN_MENU: pass
	
func _process(delta):
	match state:
		S.PLAYING: 
			handle_keypresses__playing(delta)
			if len(spawn_queue) > 0 and spawn_timer.is_stopped():
				pop_from_spawn_queue()

		S.IN_MENU: pass

func _ready():
	buildable.connect("mouse_buildable_grid_position", self, "move_building_indicator")
	buildable.connect("mouse_left_buildable_grid", self, "hide_building_indicator")
	init_pathing_grid()
	# If we put this in CreepArea then when it's called WIDTH hasn't been overridden and
	# it doesn't work, which seems insane?? Godot is a pretty bad language.
	$SpawnTop.init_starting_points()
	$SpawnLeft.init_starting_points()
	U.GRID = grid
	rng.randomize()
