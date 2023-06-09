extends KinematicBody2D

class_name Creep

signal blocked
signal selected
signal died
signal reached_destination
signal freed_for_whatever_reason
signal state_changed

var NavigationTarget = preload("res://creeps/NavigationTarget.tscn")

enum S { SPAWNED, MOVING, BLOCKED, IN_GOAL_AREA, AT_DESTINATION, DYING }

var KIND = "Normal"
var BASE_HEALTH = 50
var SPEED = 48
var STUN_CHANCE = 10
var RESIST_CHANCE = 0.0
var STATUS_REDUCTION = 1.0
var is_boss = false
var level = 1

onready var spriteButton = $SpriteButton

var state = S.SPAWNED
var current_path : Array
var destination : Vector2
var navigation_targets = []
var display_navigation_targets = false
var chilled = false setget set_chilled
var stunned = false setget set_stunned
var poisoned = false setget set_poisoned
var max_health = 0
var health = 0
var rng

func gold_value():
	var base = 2
	if is_boss: base = 10
	var mult = 1.0 + (0.2 * level)
	return base * mult

func get_texture():
	return spriteButton.texture_normal

func get_status_effects():
	var effects = []
	if chilled:
		effects.append("Chilled")
	if stunned:
		effects.append("Stunned")
	if poisoned:
		effects.append("Poisoned")
	return effects

func determine_speed():
	var base = SPEED
	if chilled:
		var penalty = 0.5
		base -= (base * penalty * STATUS_REDUCTION)
	if stunned:
		base = 0
	return base

func status_effect_hit(hit_chance=100):
	var roll = rng.randi_range(1, 100)
	return (hit_chance * (1.0 - RESIST_CHANCE)) > roll
	
func set_chilled(value):
	chilled = value
	$SpriteButton.get_material().set_shader_param("is_chilled", value)
	emit_signal("state_changed")

func set_stunned(value):
	stunned = value
	$SpriteButton.get_material().set_shader_param("is_stunned", value)
	emit_signal("state_changed")

func set_poisoned(value):
	poisoned = value
	$SpriteButton.get_material().set_shader_param("is_poisoned", value)
	emit_signal("state_changed")

func maybe_apply_chilled():
	if status_effect_hit(100):
		set_chilled(true)
		var duration = 1.0
		$ChillTimer.start(duration)

func _on_chilltimer_timeout():
	set_chilled(false)

func maybe_apply_stun(stun_chance):
	if status_effect_hit(stun_chance):
		set_stunned(true)
		var duration = 1.0 * STATUS_REDUCTION
		$StunTimer.start(duration)

func _on_stuntimer_timeout():
	set_stunned(false)

func tick_poison(timer, damage, bonus_gold, ticks_remaining):
	if ticks_remaining == 0:
		timer.call_deferred("queue_free")
		return
	
	if timer.is_connected("timeout", self, "tick_poison"):
		timer.disconnect("timeout", self, "tick_poison")

	damage(damage, bonus_gold)
	ticks_remaining -= 1
	timer.connect("timeout", self, "tick_poison", [timer, damage, bonus_gold, ticks_remaining])
	timer.start(0.5)

func maybe_apply_poison(amount, bonus_gold):
	if status_effect_hit(100):
		set_poisoned(true)
		$IsPoisonedTimer.start(1.5)
		var timer = Timer.new()
		timer.one_shot = true
		add_child(timer)
		var d = (amount / 3.0) * STATUS_REDUCTION
		tick_poison(timer, d, bonus_gold, 3)
		
		# for _i in range(3):
		# 	var d = (amount / 3.0) * STATUS_REDUCTION
		# 	yield(get_tree().create_timer(0.5), "timeout")
		# 	damage(d, bonus_gold)

func _on_ispoisonedtimer_timeout():
	set_poisoned(false)
	
func is_alive():
	return state != S.DYING and state != S.AT_DESTINATION and state != S.IN_GOAL_AREA

func damage(amount, bonus_gold):
	health -= amount
	$HealthBarFull.rect_scale.x = max(float(health), 0.0) / float(max_health)
	emit_signal("state_changed")
	if health <= 0:
		state = S.DYING
		State.add_gold(gold_value() * (1 + bonus_gold))
		return true
	return false

func determine_new_path():
	var my_position = U.snap_to_grid(position)
	var points = U.GRID.compute_path(my_position, destination)
	if points and points[0] == my_position:
		points.remove(0)
	
	var new_path = []
	for point in points:
		new_path.append(U.center(point))
	
	return new_path

func update_current_path():
	var new_path = determine_new_path()

	if current_path and len(new_path) > 1 and new_path[1] == current_path[0]:
		new_path.pop_front()
	
	if display_navigation_targets:
		for target in navigation_targets:
			target.queue_free()
		
		navigation_targets = []
		for point in new_path:
			var target = NavigationTarget.instance()
			target.position = point
			get_parent().add_child(target)
			navigation_targets.append(target)

	current_path = new_path
	maybe_unblock()

func maybe_unblock():
	if state == S.BLOCKED and current_path:
		state = S.MOVING

func become_blocked():
	state = S.BLOCKED
	emit_signal("blocked")
	print("Creep blocked! : %s / %s" % [self, position])

func update_rotation(target):
	# We default to facing DOWN, which is 90 degrees.
	# If we get back 0 degrees, we want to rotate -90 degrezzes
	var rot = rad2deg(position.angle_to_point(target)) + 180
	# var rot = rad2deg(position.angle_to_point(target)) + 90
	spriteButton.rect_rotation = rot
	$Hurtbox.rotation_degrees = rot

func handle_collides(planned_move, my_remainder):
	for i in get_slide_count():
		var them = get_slide_collision(i)
		if them != null and them.collider.is_in_group("creep") and is_instance_valid(them.collider):
			print("%s collided with: %s" % [self, them.collider.name])
			if my_remainder > them.remainder:
				var amount_moved = planned_move - my_remainder
				var t = -(amount_moved / 8)
				handle_move(t)
				# them.collider.handle_move(them.remainder)

func handle_move(forced_move=null):
	if not current_path:
		update_current_path()
		if not current_path:
			become_blocked()
			return
	
	if position.distance_to(current_path[0]) <= 1:
		current_path.pop_front()
		if navigation_targets:
			navigation_targets[0].queue_free()
			navigation_targets.pop_front()
	
	if current_path.size() == 0:
		state = S.AT_DESTINATION
		return
	
	if forced_move:
		var _ignore = move_and_slide(forced_move * determine_speed())
	else:
		var direction = (current_path[0] - position).normalized()
		update_rotation(current_path[0])
		var planned_move = direction * determine_speed()
		var _remaining_velocity = move_and_slide(planned_move)

		# handle_collides(planned_move, remaining_velocity)

func score_amount():
	if is_boss: return 80
	else: return 10

func fade_and_free(time):
	var tween = Tween.new()
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, time, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	add_child(tween)
	tween.start()
	yield(tween, "tween_completed")
	call_deferred("queue_free")

var began_to_die = false
func begin_dying():
	if began_to_die:
		return

	for target in navigation_targets:
		target.queue_free()

	began_to_die = true
	State.add_score(score_amount())
	emit_signal("died")
	emit_signal("freed_for_whatever_reason")
	$Hurtbox/CollisionShape2D.disabled = true
	$CollisionShape2D.disabled = true
	fade_and_free(0.2)

var just_reached = false
func handle_reached_goal():
	# Eventually we'll want to stick around for a second and play an animation here
	if just_reached or began_to_die:
		return
	just_reached = true
	State.lose_life()

	for target in navigation_targets:
		target.queue_free()

	emit_signal("reached_destination")
	emit_signal("freed_for_whatever_reason")
	fade_and_free(0.5)

func notify_reached_destination():
	state = S.IN_GOAL_AREA

func _physics_process(_delta):
	match state:
		S.SPAWNED:
			state = S.MOVING
		S.MOVING:
			handle_move()
		S.BLOCKED:
			pass
		S.IN_GOAL_AREA:
			handle_reached_goal()
			handle_move()
		S.AT_DESTINATION:
			handle_reached_goal()
		S.DYING:
			begin_dying()

func handle_points_changed(_points):
	match state:
		S.SPAWNED, S.AT_DESTINATION, S.DYING:
			pass
		S.MOVING:
			update_current_path()
		S.BLOCKED:
			update_current_path()
			state = S.MOVING

func compute_health():
	var base = 2.0
	var double_every_this_many_levels = 5
	var e = float(level) / double_every_this_many_levels
	var mult = pow(base, e)
	
	var h = BASE_HEALTH
	if is_boss: h *= 10
	return h * mult

func init(level_, dest):
	self.level = level_
	destination = dest
	health = compute_health()
	max_health = health

func selected():
	emit_signal("selected")

func _ready():
	spriteButton.connect("pressed", self, "selected")
	rng = RandomNumberGenerator.new()
