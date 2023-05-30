extends Node2D

class_name TowerBase

onready var shooting_range = $ShootingRange
onready var shot_timer = $ShotTimer

var WAIT_TIME = 1.0

var crescent_tower = preload("res://towers/sprites/crescenttower.png")
var diamond_tower = preload("res://towers/sprites/diamondtower.png")
var cross_tower = preload("res://towers/sprites/crosstower.png")
var Bullet = preload("res://towers/Bullet.tscn")

var target
var everything_in_range = {}
var my_shape = null

func acquire_target(target_):
	target = target_
	target.connect("died", self, "handle_target_died", [target])

func my_center():
	# towers are 2 x 2
	return position + Vector2(C.CELL_SIZE, C.CELL_SIZE)

func target_closest_creep():
	var distance = null
	var closest = null
	var center_position = my_center()

	for area in shooting_range.get_overlapping_areas():
		var creep = area.get_parent()

		if creep.is_in_group("creep") and creep.is_alive() and is_instance_valid(creep):
			var d = creep.position.distance_to(center_position)
			if distance == null or d < distance:
				distance = d
				closest = creep
		
	if closest != null:
		acquire_target(closest)

func handle_creep_entered_range(area):
	var creep = area.get_parent()
	if creep.is_in_group("creep") and creep.is_alive():
		everything_in_range[creep] = area
		if target == null:
			acquire_target(creep)

func handle_creep_left_range(area):
	var creep = area.get_parent()
	if creep.is_in_group("creep") and creep.is_alive():
		everything_in_range.erase(creep)
		
		if target == creep:
			target.disconnect("died", self, "handle_target_died")
			target = null
			target_closest_creep()

func handle_target_died(creep):
	if creep == target:
		target = null
		target_closest_creep()

func shooting_off_cooldown():
	return shot_timer.is_stopped()

func try_to_shoot():
	if target != null and shooting_off_cooldown():
		var bullet = Bullet.instance()
		var initial_position = my_center()
		var initial_direction = initial_position.direction_to(target.position)
		initial_position += initial_direction * C.CELL_SIZE
		bullet.position = initial_position
		bullet.init(my_shape, target, initial_direction)
		get_parent().add_child(bullet)
		shot_timer.start(WAIT_TIME)

func _physics_process(_delta):
	try_to_shoot()

func init(shape):
	my_shape = shape

	match shape:
		C.SHAPE.CROSS: $Building.texture = cross_tower
		C.SHAPE.DIAMOND: $Building.texture = diamond_tower
		C.SHAPE.CRESCENT: $Building.texture = crescent_tower

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	shooting_range.connect("area_entered", self, "handle_creep_entered_range")
	shooting_range.connect("area_exited", self, "handle_creep_left_range")
