extends KinematicBody2D

signal blocked
signal selected
signal died
signal reached_destination
signal freed_for_whatever_reason
signal state_changed

var NavigationTarget = preload("res://creeps/NavigationTarget.tscn")

enum S { SPAWNED, MOVING, BLOCKED, AT_DESTINATION, DYING }

var KIND = "Normal"
var LEVEL = 1
var HEALTH = 50
var SPEED = 50

onready var spriteButton = $SpriteButton

var state = S.SPAWNED
var current_path : Array
var destination : Vector2
var navigation_targets = []
var display_navigation_targets = true
var chilled = false
var stunned = false
var poisoned = false

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
		base *= 0.5
	if stunned:
		base = 0
	return base

func apply_chilled():
	chilled = true
	emit_signal("state_changed")
	$ChillTimer.start()

func _on_chilltimer_timeout():
	emit_signal("state_changed")
	chilled = false

func apply_stun():
	stunned = true
	emit_signal("state_changed")
	$StunTimer.start()

func _on_stuntimer_timeout():
	emit_signal("state_changed")
	stunned = false

func apply_poison(amount):
	poisoned = true
	emit_signal("state_changed")
	$IsPoisonedTimer.start(1.5)
	for _i in range(3):
		yield(get_tree().create_timer(0.5), "timeout")
		damage(amount)

func _on_ispoisonedtimer_timeout():
	emit_signal("state_changed")
	poisoned = false
	
func is_alive():
	return state != S.DYING

func damage(amount):
	HEALTH -= amount
	emit_signal("state_changed")
	if HEALTH <= 0:
		state = S.DYING

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

func become_blocked():
	state = S.BLOCKED
	emit_signal("blocked")
	print("Creep blocked! : %s / %s" % [self, position])

func update_rotation(target):
	# We default to facing DOWN, which is 90 degrees.
	# If we get back 0 degrees, we want to rotate -90 degrees
	rotation_degrees = rad2deg(position.angle_to_point(target)) + 90

func handle_move():
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
	
	var direction = (current_path[0] - position).normalized()
	update_rotation(current_path[0])
	var _remaining_velocity = move_and_slide(direction * determine_speed())

var began_to_die = false

func begin_dying():
	if began_to_die:
		return

	for target in navigation_targets:
		target.queue_free()

	began_to_die = true
	emit_signal("died")
	emit_signal("freed_for_whatever_reason")
	call_deferred("queue_free")

var just_reached = false
func handle_reached_destination():
	# Eventually we'll want to stick around for a second and play an animation here
	if just_reached:
		return
	just_reached = true

	for target in navigation_targets:
		target.queue_free()

	emit_signal("reached_destination")
	emit_signal("freed_for_whatever_reason")
	call_deferred("queue_free")

func notify_reached_destination():
	state = S.AT_DESTINATION

func _physics_process(_delta):
	match state:
		S.SPAWNED:
			state = S.MOVING
		S.MOVING:
			handle_move()
		S.BLOCKED:
			pass
		S.AT_DESTINATION:
			handle_reached_destination()
		S.DYING:
			begin_dying()
			call_deferred("queue_free")

func handle_points_changed(_points):
	match state:
		S.SPAWNED, S.AT_DESTINATION, S.DYING:
			pass
		S.MOVING:
			update_current_path()
		S.BLOCKED:
			update_current_path()
			state = S.MOVING

func init(dest):
	destination = dest

func selected():
	emit_signal("selected")

func _ready():
	spriteButton.connect("pressed", self, "selected")