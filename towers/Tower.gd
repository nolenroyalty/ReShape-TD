extends Node2D

class_name TowerBase

signal selected

var TowerRange = preload("res://towers/TowerRange.tscn")

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
var my_stats = null
var tower_range = null

func acquire_target(target_):
	target = target_
	target.connect("died", self, "handle_target_died", [target])

func my_center():
	# towers are 2 x 2
	return position + Vector2(C.CELL_SIZE, C.CELL_SIZE)

func hide_range():
	if tower_range != null:
		tower_range.queue_free()
		tower_range = null

func display_range():
	if tower_range != null:
		tower_range.queue_free()
		tower_range = null
	
	var tr = TowerRange.instance()
	tr.tower = self
	tr.position = Vector2(C.CELL_SIZE, C.CELL_SIZE)
	add_child(tr)
	tower_range = tr

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
	if target != null and is_instance_valid(target) and target.is_alive() and shooting_off_cooldown():
		var projectile_count = Upgrades.projectiles(my_shape)
		var angle_offset = 0
		var initial_position = my_center()
		var initial_direction = initial_position.direction_to(target.position)

		for _i in range(projectile_count):
			angle_offset = -angle_offset

			var bullet = Bullet.instance()

			var direction = initial_direction.rotated(deg2rad(angle_offset))
			bullet.position = initial_position + direction * C.CELL_SIZE
			var t = target if angle_offset == 0 else null
			bullet.init(my_shape, my_stats, t, direction)
			get_parent().add_child(bullet)

			if angle_offset < 0:
				angle_offset -= 30.0
			else:
				angle_offset += 30.0
			
		shot_timer.start(my_stats.ATTACK_SPEED)

func refresh_range():
	$ShootingRange/CollisionShape2D.shape.radius = my_stats.RANGE_RADIUS

func _physics_process(_delta):
	try_to_shoot()

func pressed():
	# This automatically triggers from the mouseup event that fires when we
	# _build_ a tower. I can't think of a way to prevent this that doesn't
	# seem fragile - I don't want to risk that you can't select a tower at all!
	# It seems ~fine that towers are selected by default when you build them
	# so we can ignore this for now.
	emit_signal("selected")

func init(shape):
	my_shape = shape
	my_stats = Upgrades.IndividualTower.new()

	var texture = null

	match shape:
		C.SHAPE.CROSS: texture = cross_tower
		C.SHAPE.DIAMOND: texture = diamond_tower
		C.SHAPE.CRESCENT: texture = crescent_tower

	$Building.texture_normal = texture

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	shooting_range.connect("area_entered", self, "handle_creep_entered_range")
	shooting_range.connect("area_exited", self, "handle_creep_left_range")
	var _ignore = $Building.connect("pressed", self, "pressed")
