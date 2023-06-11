extends Node2D

signal selected_creep(creep)
signal selected_tower(tower)
signal tower_built
signal damage_test_complete(damage_done, killed)

onready var indicator = $BuildingIndicator
onready var buildable = $BuildableGrid
onready var grid = $PathingGrid
onready var spawn_timer = $SpawnTimer
onready var audio = $AudioStreamPlayer
var WaveReleaseSound = preload("res://battlefield/sounds/waverelease.wav")

var Creep = preload("res://creeps/CreepGeneric.tscn")
var Normal = preload("res://creeps/CreepNormal.tscn")
var NormalBoss = preload("res://creeps/NormalBoss.tscn")
var Thick = preload("res://creeps/CreepThick.tscn")
var ThickBoss = preload("res://creeps/ThickBoss.tscn")
var Quick = preload("res://creeps/CreepQuick.tscn")
var QuickBoss = preload("res://creeps/QuickBoss.tscn")
var Resist = preload("res://creeps/CreepResist.tscn")
var ResistBoss = preload("res://creeps/ResistantBoss.tscn")
var Pack = preload("res://creeps/CreepPack.tscn")
var PackBoss = preload("res://creeps/PackBoss.tscn")
var DamageTest = preload("res://creeps/DamageTest.tscn")
var Tower = preload("res://towers/Tower.tscn")

enum S { NOT_YET_STARTED, PLAYING, IN_MENU }

var current_build_location = null
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var selected_shape = null
var state = S.NOT_YET_STARTED
var selected_creep_or_tower = null
var spawn_queue = []

func move_building_indicator(pos):
	current_build_location = pos + buildable.position
	if selected_shape != null:
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
	emit_signal("tower_built")

func can_build_tower():
	if not indicator.unblocked():
		return false
	
	if selected_shape == null:
		return false
	
	var creep_pos = {}
	var start_end_pairs = []
	
	for vertical in [true, false]:
		var start = spawn(vertical).starting_points[0] + U.snap_to_grid(spawn(vertical).position)
		var end = dest(vertical).get_center_point() + U.snap_to_grid(dest(vertical).position)
		start_end_pairs.append([start, end])

	for creep in get_tree().get_nodes_in_group("creep"):
		var p = U.snap_to_grid(creep.position)
		var d = U.snap_to_grid(creep.destination)
		start_end_pairs.append([p, d])

		if creep.position.distance_to(current_build_location) < C.CELL_SIZE * 2:
			creep_pos[p] = true

	var tower_points = relevant_points_for_tower(current_build_location)
	for pos in tower_points:
		if not grid.has_point(pos):
			print("Not allowing tower build because it's off the grid - maybe the user alt-tabbed?")
			return false

		if grid.is_disabled(pos):
			print("Not allowing tower build because it overlaps with a tower")
			return false
		
		if pos in creep_pos:
			print("Not allowing tower build because it overlaps with a creep")
			return false

	if grid.would_block_a_path(tower_points, start_end_pairs):
		print("Not allowing tower build because it blocks a path")
		return false
	
	return true

func try_to_build_tower(_event):
	if not can_build_tower():
		return false

	var cost = Upgrades.tower_cost(selected_shape)
	if not State.try_to_buy(cost):
		print("Not enough money to place tower!")
		# play sound!!!
		return false

	actually_build_tower(current_build_location)
	notify_creeps_of_pathing_change()

func init_pathing_grid():
	var all_points = []
	for child in get_tree().get_nodes_in_group("pathable"):
		var offset = U.snap_to_grid(child.position)
		assert(offset == child.position, "CHILD NOT ON GRID: %s" % [child])
		
		for point in child.pathable_points():
			point += offset
			all_points.append(point) 
	
	grid.init(all_points)

func timer_done__add_creep(timer, creep):
	if state == S.PLAYING:
		add_child(creep)
	else:
		print("Not adding creep because the game is not playing - game probably reset?")
	timer.queue_free()

func add_creep_soon(creep):
	var wait_time = rng.randf() * 0.2
	var t = Timer.new()
	t.add_to_group("creep_timer")
	add_child(t)
	t.set_wait_time(wait_time)
	t.set_one_shot(true)
	t.connect("timeout", self, "timer_done__add_creep", [t, creep])
	t.start(wait_time)

func spawn(vertical):
	if vertical: return $SpawnLeft
	else: return $SpawnTop

func dest(vertical):
	if vertical: return $DestRight
	else: return $DestBot

var last_vertical = null
var last_horizontal = null

func spawn_timer_time(creep_kind):
	if creep_kind == C.CREEP_KIND.PACK:
		return 0.175
	else:
		return 0.3

func determine_creep_class(creep_kind, is_boss):
	var CreepClass = null

	match creep_kind:
		C.CREEP_KIND.NORMAL:
			if is_boss: CreepClass = NormalBoss
			else: CreepClass = Normal
		C.CREEP_KIND.THICK:
			if is_boss: CreepClass = ThickBoss
			else: CreepClass = Thick
		C.CREEP_KIND.QUICK:
			if is_boss: CreepClass = QuickBoss
			else: CreepClass = Quick
		C.CREEP_KIND.RESISTANT:
			if is_boss: CreepClass = ResistBoss
			else: CreepClass = Resist
		C.CREEP_KIND.PACK:
			if is_boss: CreepClass = PackBoss
			else: CreepClass = Pack
	return CreepClass

func pop_from_spawn_queue():
	var creep_info = spawn_queue.pop_front()
	var kind = creep_info[0]
	var is_boss = creep_info[1]
	var level = creep_info[2]
	spawn_timer.start(spawn_timer_time(kind))
	var CreepClass = determine_creep_class(kind, is_boss)

	for vertical in [true, false]:
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
		var creep = CreepClass.instance()
		creep.position = U.center(start)
		creep.init(level, end)
		creep.connect("selected", self, "creep_selected", [creep])
		add_creep_soon(creep)

func prop_damage_test_complete(damage_done, killed):
	emit_signal("damage_test_complete", damage_done, killed)

func send_damage_test():
	var dt = DamageTest.instance()

	var vertical = rng.randf() < 0.5
	var start_area = spawn(vertical)
	var end_area = dest(vertical)
	var points = start_area.starting_points
	var idx = rng.randi_range(0, len(points) - 1)
	var start = points[idx % len(points)] + U.snap_to_grid(start_area.position)
	var end = end_area.get_center_point() + U.snap_to_grid(end_area.position)
	dt.position = U.center(start)
	dt.init(1, end)
	dt.connect("selected", self, "creep_selected", [dt])
	dt.connect("damage_test_complete", self, "prop_damage_test_complete")
	add_child(dt)

func build_tower_for_mouse_event(event):
	if event is InputEventMouseButton:
		if current_build_location != null and event.pressed and event.button_index == BUTTON_LEFT:
			try_to_build_tower(event)

func handle_event__playing(event):
	build_tower_for_mouse_event(event)

func handle_event__not_started(event):
	build_tower_for_mouse_event(event)

func add_to_spawn_queue(creep, is_boss, count, level):
	for _i in range(count):
		spawn_queue.append([creep, is_boss, level])

func spawn_wave(kind, level, is_boss, number_of_creeps=null):
	if GlobalAudio.request_play_wave_release():
		audio.stream = WaveReleaseSound
		audio.volume_db = -10
		audio.play()

	if number_of_creeps == null:
		if kind == C.CREEP_KIND.PACK:
			if is_boss:
				number_of_creeps = 3
			else:
				number_of_creeps = 14
		else:
			number_of_creeps = 9
			if is_boss: number_of_creeps = 1

	add_to_spawn_queue(kind, is_boss, number_of_creeps, level)

func get_towers():
	return get_tree().get_nodes_in_group("tower")

func set_in_menu():
	state = S.IN_MENU

func set_playing():
	state = S.PLAYING

func no_more_creeps():
	var no_creeps = len(get_tree().get_nodes_in_group("creep")) == 0 
	var no_creep_timers = len(get_tree().get_nodes_in_group("creep_timer")) == 0
	var spawn_queue_empty = len(spawn_queue) == 0
	return no_creeps and no_creep_timers and spawn_queue_empty

func set_shape(shape):
	selected_shape = shape
	if selected_shape == null:
		indicator.begin_hiding()
	elif current_build_location != null:
		indicator.position = current_build_location
		indicator.begin_showing()

func _input(event):
	match state:
		S.PLAYING: handle_event__playing(event)
		S.IN_MENU: pass
		S.NOT_YET_STARTED: handle_event__not_started(event)
	
func _process(_delta):
	match state:
		S.PLAYING: 
			if len(spawn_queue) > 0 and spawn_timer.is_stopped():
				pop_from_spawn_queue()

		S.IN_MENU: pass

func reset():
	for child in get_tree().get_nodes_in_group("creep"):
		child.queue_free()
	for child in get_tree().get_nodes_in_group("tower"):
		child.queue_free()
	for child in get_tree().get_nodes_in_group("bullet"):
		child.queue_free()
	for child in get_tree().get_nodes_in_group("creep_timer"):
		child.queue_free()

	current_build_location = null
	selected_shape = null
	state = S.NOT_YET_STARTED
	selected_creep_or_tower = null
	grid.reset()
	spawn_queue = []

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
	indicator.begin_hiding()
