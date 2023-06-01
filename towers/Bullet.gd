extends KinematicBody2D

enum S { NO_TARGET, MOVING_TO_TARGET, MOVING_IN_LAST_DIRECTION, HIT_SOMETHING, FADING } 

var crescent_bullet = preload("res://towers/sprites/crescentbullet.png")
var diamond_bullet = preload("res://towers/sprites/diamondbullet.png")
var cross_bullet = preload("res://towers/sprites/crossbullet.png")

var my_shape = null
var my_stats = null
var target = null
var direction = null
var state = S.NO_TARGET

func init(shape, stats, target_, initial_direction):
	my_shape = shape
	my_stats = stats
	target = target_
	direction = initial_direction
	state = S.MOVING_TO_TARGET

	match my_shape:
		C.SHAPE.CROSS: $Sprite.texture = cross_bullet
		C.SHAPE.CRESCENT: $Sprite.texture = crescent_bullet
		C.SHAPE.DIAMOND: $Sprite.texture = diamond_bullet

func my_damage():
	return my_stats.DAMAGE * Upgrades.damage_mult(my_shape)

func hit_something(area):
	var creep = area.get_parent()
	if creep.is_in_group("creep"):
		state = S.HIT_SOMETHING
		creep.damage(my_damage())
		
func exited_battlefield():
	if state != S.HIT_SOMETHING:
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
		S.FADING:
			clear_target_and_free()

func clear_target_and_free():
	target = null
	state = S.NO_TARGET
	call_deferred("queue_free")

func _ready():
	assert(my_shape != null, "Shape must be provided prior to adding to scene %s" % [self])
	var _ignore = $Hitbox.connect("area_entered", self, "hit_something")
