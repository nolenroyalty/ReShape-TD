extends KinematicBody2D

enum S { NO_TARGET, MOVING_TO_TARGET, MOVING_IN_LAST_DIRECTION, EXPLODING, HIT_SOMETHING, FADING } 

const EXPLOSION_SPEED = 0.35
const EXPLOSION_SIZE = 5.0

var crescent_bullet = preload("res://towers/sprites/crescentbullet.png")
var diamond_bullet = preload("res://towers/sprites/diamondbullet.png")
var cross_bullet = preload("res://towers/sprites/crossbullet.png")

var my_shape = null
var my_stats = null
var target = null
var direction = null
var state = S.NO_TARGET
var returns = false
var pierces = 0
var chains = 0
var explodes = false
var explosion_scale_left = 4.0
var already_hit = {}

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
	$ChainRange/CollisionShape2D.shape.radius = my_stats.RANGE_RADIUS

	match my_shape:
		C.SHAPE.CROSS: $Sprite.texture = cross_bullet
		C.SHAPE.CRESCENT: $Sprite.texture = crescent_bullet
		C.SHAPE.DIAMOND: $Sprite.texture = diamond_bullet

func my_damage():
	return my_stats.DAMAGE * Upgrades.damage_mult(my_shape)

func apply_status_effects(creep):
	if Upgrades.has_chill(my_shape):
		creep.apply_chilled()
	if Upgrades.has_poison(my_shape):
		creep.apply_poison(my_damage() / 2.0)
	if Upgrades.has_stun(my_shape):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		if rng.randi_range(1, 100) < creep.STUN_CHANCE:
			creep.apply_stun()

func can_chain():
	if chains <= 0: return false
	var center = U.center(U.snap_to_grid(position))
	var closest = U.get_closest_creep(center, $ChainRange, already_hit)
	return closest


func explode():
	var t = Tween.new()
	var start_scale = $Sprite.scale
	var final_scale = start_scale * EXPLOSION_SIZE
	t.interpolate_property($Sprite, "scale", null, final_scale, EXPLOSION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	var current_radius = $Hitbox/Shape.shape.radius
	var final_radius = current_radius * EXPLOSION_SIZE
	t.interpolate_property($Hitbox/Shape, "shape:radius", null, final_radius, EXPLOSION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	add_child(t)
	t.start()
	yield(t, "tween_all_completed")
	state = S.FADING

func hit_something(area):
	var creep = area.get_parent()
	if creep.is_in_group("creep") and not (creep in already_hit):
		apply_status_effects(creep)
		creep.damage(my_damage())
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
			state = S.HIT_SOMETHING
		
func exited_battlefield():
	if state != S.HIT_SOMETHING:
		if returns:
			returns = false
			state = S.MOVING_IN_LAST_DIRECTION
			direction = direction * -1
		else:	
			state = S.FADING

func move_in_direction(delta):
	if direction == null:
		print("BUG: move_in_direction called with null direction %s" % [self])
		clear_target_and_free()
	var velocity = my_stats.PROJECTILE_SPEED
	var _ignore = move_and_collide(direction * velocity * delta)

	

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
		S.HIT_SOMETHING:
			clear_target_and_free()
		S.EXPLODING:
			pass
		S.FADING:
			clear_target_and_free()

func clear_target_and_free():
	target = null
	state = S.NO_TARGET
	call_deferred("queue_free")

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	var _ignore = $Hitbox.connect("area_entered", self, "hit_something")
