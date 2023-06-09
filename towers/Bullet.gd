extends KinematicBody2D

signal killed_creep

enum S { NO_TARGET, MOVING_TO_TARGET, MOVING_IN_LAST_DIRECTION, EXPLODING, HIT_SOMETHING, BEGIN_FADING, FADING } 

const EXPLOSION_SPEED = 0.35
const EXPLOSION_SIZE = 5.0
# 40 (max diagonal across the buildable grid) * 16 (cell size)
const MAX_DISTANCE_TRAVELED = 640.0

var my_shape = null
var my_stats = null
var target = null
var direction = null
var state = S.NO_TARGET
var returns = false
var pierces = 0
var chains = 0
var explodes = false
var farshot_return_bonus = 0
var explosion_scale_left = 4.0
var already_hit = {}
var starting_position = null

func init(shape, stats, target_, initial_direction):
	my_shape = shape
	my_stats = stats
	target = target_
	direction = initial_direction
	state = S.MOVING_TO_TARGET
	returns = Upgrades.has_return(my_shape)
	pierces = Upgrades.pierces(my_shape)
	chains = Upgrades.chains(my_shape)
	explodes = Upgrades.explodes(my_shape)
	var size_mult = Upgrades.projectile_size_mult(my_shape)
	
	$ChainRange/CollisionShape2D.shape.radius = (my_stats.RANGE_RADIUS / 2) * size_mult
	$Sprite.scale *= size_mult
	$Hitbox/Shape.shape.radius *= size_mult

	match my_shape:
		C.SHAPE.CROSS: 
			$Sprite.modulate = C.YELLOW
		C.SHAPE.CRESCENT:
			$Sprite.modulate = C.LIGHT_GREEN
		C.SHAPE.DIAMOND:
			$Sprite.modulate = C.LIGHT_BLUE

func farshot_mult():
	if Upgrades.farshot(my_shape):
		return 1.0 + farshot_return_bonus
	else:
		var distance_traveled = starting_position.distance_to(position)
		distance_traveled += farshot_return_bonus
		var mult = min(1.0, distance_traveled / MAX_DISTANCE_TRAVELED)
		return 1.0 + mult

func my_damage():
	var mult = Upgrades.damage_mult(my_shape)
	mult *= farshot_mult()
	return my_stats.DAMAGE * mult

func apply_status_effects(creep):
	if Upgrades.has_chill(my_shape):
		creep.maybe_apply_chilled()
	if Upgrades.has_poison(my_shape):
		var bonus_gold = Upgrades.bonus_gold(my_shape)
		creep.maybe_apply_poison(my_damage() / 2.0, bonus_gold)
	if Upgrades.has_stun(my_shape):
		var stun_chance = 10
		creep.maybe_apply_stun(stun_chance)

func can_chain():
	if chains <= 0: return false
	var center = U.center(U.snap_to_grid(position))
	var closest = U.get_closest_creep(center, $ChainRange, already_hit)
	return closest


func explode():
	var t = Tween.new()
	var start_scale = $Sprite.scale
	var final_scale = start_scale * EXPLOSION_SIZE
	t.interpolate_property($Sprite, "modulate:a", null, 0.6, EXPLOSION_SPEED, Tween.TRANS_QUAD, Tween.EASE_OUT)
	t.interpolate_property($Sprite, "scale", null, final_scale, EXPLOSION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	var current_radius = $Hitbox/Shape.shape.radius
	var final_radius = current_radius * EXPLOSION_SIZE
	t.interpolate_property($Hitbox/Shape, "shape:radius", null, final_radius, EXPLOSION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	add_child(t)
	t.start()
	yield(t, "tween_all_completed")
	state = S.BEGIN_FADING

func hit_something(area):
	if state == S.FADING:
		return

	var creep = area.get_parent()
	if creep.is_in_group("creep") and not (creep in already_hit):
		apply_status_effects(creep)
		var bonus_gold = Upgrades.bonus_gold(my_shape)
		
		if creep.damage(my_damage(), bonus_gold):
			emit_signal("killed_creep")

		already_hit[creep] = true
		var chain_target = can_chain()
		if chain_target:
			chains -= 1
			state = S.MOVING_TO_TARGET
			target = chain_target
		elif pierces > 0:
			pierces -= 1
			state = S.MOVING_IN_LAST_DIRECTION
		elif explodes:
			explodes = false
			explode()
			chains = 0
			pierces = 0
			state = S.EXPLODING
		elif state == S.EXPLODING:
			pass
		else:
			state = S.BEGIN_FADING
		
func exited_battlefield():
	if state != S.BEGIN_FADING and state != S.FADING:
		if returns:
			
			if Upgrades.farshot(my_shape):
				farshot_return_bonus = starting_position.distance_to(position)
				starting_position = position

			returns = false
			state = S.MOVING_IN_LAST_DIRECTION
			direction = direction * -1
		else:	
			state = S.BEGIN_FADING

func move_in_direction(delta):
	if direction == null:
		print("BUG: move_in_direction called with null direction %s" % [self])
		clear_target_and_free()
	var velocity = my_stats.PROJECTILE_SPEED
	var _ignore = move_and_collide(direction * velocity * delta)

func begin_fading():
	var t = Tween.new()
	t.interpolate_property($Sprite, "modulate:a", null, 0.0, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN)
	var scale = $Sprite.scale
	t.interpolate_property($Sprite, "scale", scale, scale / 4.0, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN)
	add_child(t)
	t.start()
	target = null
	state = S.FADING
	yield(t, "tween_all_completed")
	call_deferred("queue_free")

func _physics_process(delta):
	match state:
		S.NO_TARGET:
			pass
		S.MOVING_TO_TARGET:
			if target != null and is_instance_valid(target):
				direction = position.direction_to(target.position)
			else:
				state = S.MOVING_IN_LAST_DIRECTION
				target = null
			move_in_direction(delta)
		S.MOVING_IN_LAST_DIRECTION:
			move_in_direction(delta)
		# S.HIT_SOMETHING:
		# 	clear_target_and_free()
		S.EXPLODING:
			pass
		S.BEGIN_FADING:
			begin_fading()
		S.FADING:
			pass

func clear_target_and_free():
	target = null
	state = S.NO_TARGET
	call_deferred("queue_free")

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	var _ignore = $Hitbox.connect("area_entered", self, "hit_something")
	starting_position = position