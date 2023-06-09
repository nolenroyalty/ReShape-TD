extends Node2D

class_name TowerBase

signal selected
signal sold
signal leveled_up
signal killed

var TowerRange = preload("res://towers/TowerRange.tscn")

onready var shooting_range = $ShootingRange
onready var generous_range = $GenerousRange
onready var shot_timer = $ShotTimer

var WAIT_TIME = 1.0

var crescent_tower = preload("res://towers/sprites/crescenttower.png")
var diamond_tower = preload("res://towers/sprites/diamondtower.png")
var cross_tower = preload("res://towers/sprites/crosstower.png")
var Bullet = preload("res://towers/Bullet.tscn")

var target = null
var everything_in_range = {}
var towers_we_have_given_generous_to = {}
var my_shape = null
var my_stats = null
var tower_range = null
var kills = 0
var gold_spent = 0
var generous_stacks = 0

func acquire_target(target_):
	target = target_
	target.connect("freed_for_whatever_reason", self, "handle_target_died", [target])

func valid_target(target_):
	return target_ != null and is_instance_valid(target_) and target_.is_in_group("creep") and target_.is_alive()

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
	var closest = U.get_closest_creep(my_center(), shooting_range)
	if closest != null:
		acquire_target(closest)

func handle_creep_entered_range(area):
	var creep = area.get_parent()
	if valid_target(creep):
		everything_in_range[creep] = area
		if not valid_target(target):
			acquire_target(creep)

func handle_creep_left_range(area):
	var creep = area.get_parent()
	if creep.is_in_group("creep") and creep.is_alive():
		everything_in_range.erase(creep)
		
		if target == creep:
			target.disconnect("freed_for_whatever_reason", self, "handle_target_died")
			target = null
			target_closest_creep()

func handle_target_died(creep):
	if creep == target:
		target = null
		target_closest_creep()

func shooting_off_cooldown():
	return shot_timer.is_stopped()

func try_to_shoot():
	if valid_target(target) and shooting_off_cooldown():
		var projectile_count = Upgrades.projectiles(my_shape)
		var initial_position = my_center()
		var initial_direction = initial_position.direction_to(target.position)

		for i in range(projectile_count):
			var angle_offset
			
			if i == 0:
				angle_offset = 0.0
			elif i % 2 == 0:
				angle_offset = i * 15.0
			else:
				angle_offset = i * -15.0

			var bullet = Bullet.instance()

			var direction = initial_direction.rotated(deg2rad(angle_offset))
			bullet.position = initial_position + direction * C.CELL_SIZE
			var t = target if angle_offset == 0 else null
			bullet.init(my_shape, my_stats, t, direction)
			bullet.connect("killed_creep", self, "got_a_kill")
			get_parent().add_child(bullet)
			
		shot_timer.start(my_stats.ATTACK_SPEED)

func refresh_range():
	$ShootingRange/CollisionShape2D.shape.radius = my_stats.RANGE_RADIUS
	$GenerousRange/CollisionShape2D.shape.radius = my_stats.RANGE_RADIUS
	if tower_range != null:
		tower_range.update()

func _physics_process(_delta):
	try_to_shoot()

func rank_up_cost():
	return Upgrades.rank_up_cost(my_shape, my_stats)

func sell_value():
	return int(gold_spent / 2.0)

func level_up():
	gold_spent += rank_up_cost()
	my_stats.level_up()
	$Level.text = "%s" % [my_stats.LEVEL]
	$Level.visible = true
	refresh_range()
	emit_signal("leveled_up")
		
func sell():
	for tower in towers_we_have_given_generous_to.keys():
		if tower != null and is_instance_valid(tower):
			tower.remove_generous_bonus()

	hide_range()
	queue_free()
	State.add_gold(sell_value())
	emit_signal("sold")

func got_a_kill():
	kills += 1
	emit_signal("killed")

func pressed():
	# This automatically triggers from the mouseup event that fires when we
	# _build_ a tower. I can't think of a way to prevent this that doesn't
	# seem fragile - I don't want to risk that you can't select a tower at all!
	# It seems ~fine that towers are selected by default when you build them
	# so we can ignore this for now.
	emit_signal("selected")

func enable_generous():
	$GenerousRange/CollisionShape2D.disabled = false

func add_generous_bonus():
	generous_stacks += 1
	my_stats.set_generous_stacks(generous_stacks)

func remove_generous_bonus():
	if generous_stacks > 0:
		generous_stacks -= 1
	my_stats.set_generous_stacks(generous_stacks)

func give_tower_generous(area):
	var tower = area.get_parent()
	if tower.is_in_group("tower") and tower != self and not (tower in towers_we_have_given_generous_to):
		print("give generous bonus to tower")
		towers_we_have_given_generous_to[tower] = true
		tower.add_generous_bonus()

func init(shape):
	my_shape = shape
	my_stats = Upgrades.IndividualTower.new()
	gold_spent = Upgrades.tower_cost(my_shape)

	var texture = null

	match shape:
		C.SHAPE.CROSS: texture = cross_tower
		C.SHAPE.DIAMOND: texture = diamond_tower
		C.SHAPE.CRESCENT: texture = crescent_tower

	$Building.texture_normal = texture
	
	if Upgrades.generous(my_shape):
		enable_generous()

func handle_reshaped(shape, upgrade):
	if shape == my_shape and upgrade == Upgrades.T.GENEROUS:
		enable_generous()

func on_generous_range_area_entered(area):
	give_tower_generous(area)

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	shooting_range.connect("area_entered", self, "handle_creep_entered_range")
	shooting_range.connect("area_exited", self, "handle_creep_left_range")
	generous_range.connect("area_entered", self, "give_tower_generous")
	var _ignore = $Building.connect("pressed", self, "pressed")
