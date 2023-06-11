extends Node2D

class_name TowerBase

signal selected
signal sold
signal leveled_up
signal killed

const SHOOT_SOUND = preload("res://towers/sounds/shoot1.wav")
var TowerRange = preload("res://towers/TowerRange.tscn")

onready var shooting_range = $ShootingRange
onready var generous_range = $GenerousRange
onready var shot_timer = $ShotTimer
onready var audio = $AudioStreamPlayer
onready var sprite_animator = $SpriteAnimationPlayer
onready var rect_animator = $ColorRectAnimationPlayer

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
var began_selling = false
var leveling_up = false

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

func can_shoot():
	return shooting_off_cooldown() and valid_target(target) and not began_selling and not leveling_up

func maybe_play_shoot_sound():
	if GlobalAudio.request_play_shoot():
		audio.stream = SHOOT_SOUND
		audio.volume_db = -30
		audio.play()

func try_to_shoot():
	if can_shoot():
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
		
		maybe_play_shoot_sound()
		sprite_animator.play("shoot")
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

func sell_value(full_value = false):
	var val = gold_spent
	if full_value: return int(val)
	else: return int(val / 2.0)

func actually_level_up():
	State.has_ranked_up_ever = true
	leveling_up = false
	my_stats.level_up()
	$Level.text = "%s" % [my_stats.LEVEL]
	$Level.visible = true
	refresh_range()
	emit_signal("leveled_up")

func handle_levelup_animation_finished(_rect, _key, tween):
	tween.call_deferred("queue_free")
	$Sprite.visible = true
	$RankUpRect.visible = false
	actually_level_up()	

func level_up():
	if my_stats.LEVEL < C.MAX_LEVEL and not leveling_up and not began_selling:
		if State.try_to_buy(rank_up_cost()):
			leveling_up = true
			gold_spent += rank_up_cost()
			if not State.begun:
				actually_level_up()
			else:
				var t = Tween.new()
				$RankUpRect.rect_scale = U.v(0, 1)
				$RankUpRect.visible = true
				$Sprite.visible = false
				match my_shape:
					C.SHAPE.CROSS: $RankUpRect.color = C.YELLOW
					C.SHAPE.DIAMOND: $RankUpRect.color = C.LIGHT_BLUE
					C.SHAPE.CRESCENT: $RankUpRect.color = C.DARK_GREEN
				add_child(t)
				var time = my_stats.upgrade_time()
				t.interpolate_property($RankUpRect, "rect_scale", null, U.v(1, 1), time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
				t.start()
				t.connect("tween_completed", self, "handle_levelup_animation_finished", [t])
			
func actually_sell(full_value = false):
	State.add_gold(sell_value(full_value))
	hide_range()
	emit_signal("sold")
	queue_free()

func sell_animation_finished(name, full_value=false):
	if name == "sold": actually_sell(full_value)

func sell():
	if began_selling or leveling_up:
		return
	
	began_selling = true
	for tower in towers_we_have_given_generous_to.keys():
		if tower != null and is_instance_valid(tower):
			tower.remove_generous_bonus()
	
	if State.begun:
		sprite_animator.play("sold")
		sprite_animator.connect("animation_finished", self, "sell_animation_finished", [false])
	else:
		actually_sell(true)

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

	match shape:
		C.SHAPE.CROSS: $Sprite.frame = 1
		C.SHAPE.DIAMOND: $Sprite.frame = 2
		C.SHAPE.CRESCENT: $Sprite.frame = 0

	if Upgrades.generous(my_shape):
		enable_generous()

func handle_reshaped(shape, upgrade):
	if shape == my_shape:
		rect_animator.play("reshaped")

		if upgrade == Upgrades.T.GENEROUS:
			enable_generous()

func on_generous_range_area_entered(area):
	give_tower_generous(area)

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	shooting_range.connect("area_entered", self, "handle_creep_entered_range")
	shooting_range.connect("area_exited", self, "handle_creep_left_range")
	generous_range.connect("area_entered", self, "give_tower_generous")
	
	var _ignore = $Building.connect("pressed", self, "pressed")
	_ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
