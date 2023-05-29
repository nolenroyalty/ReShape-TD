extends KinematicBody2D

signal blocked
signal died

enum S { SPAWNED, MOVING, BLOCKED, AT_DESTINATION, DYING }

var HEALTH = 50
var SPEED = 50

var state = S.SPAWNED
var current_path : Array
var destination : Vector2

func is_alive():
	return state != S.DYING

func damage(amount):
	HEALTH -= amount
	if HEALTH <= 0:
		state = S.DYING

func determine_new_path():
	var my_position = U.snap_to_grid(position)
	var points = U.GRID.compute_path(my_position, destination)
	if points[0] == my_position:
		points.pop_front()
	
	var new_path = []
	for point in points:
		new_path.append(U.center(point))
	
	return new_path

func update_current_path():
	var new_path = determine_new_path()

	if current_path and len(new_path) > 1 and new_path[1] == current_path[0]:
		new_path.pop_front()
	current_path = new_path

func become_blocked():
	state = S.BLOCKED
	emit_signal("blocked")
	print("Creep blocked! : %s / %s" % [self, position])

func update_rotation(target):
	# We default to facing DOWN, which is 90 degrees.
	# If we get back 0 degrees, we want to rotate -90 degrees
	rotation_degrees = rad2deg(position.angle_to_point(target)) - 90


func handle_move():
	if not current_path:
		update_current_path()
		if not current_path:
			become_blocked()
			return
	
	if position.distance_to(current_path[0]) <= 1:
		current_path.pop_front()
	
	if current_path.size() == 0:
		state = S.AT_DESTINATION
		return
	
	var direction = (current_path[0] - position).normalized()
	update_rotation(current_path[0])
	var _collision = move_and_slide(direction * SPEED)

var began_to_die = false

func begin_dying():
	if began_to_die:
		return
	began_to_die = true
	emit_signal("died")
	call_deferred("queue_free")

func _physics_process(_delta):
	match state:
		S.SPAWNED:
			state = S.MOVING
		S.MOVING:
			handle_move()
		S.BLOCKED:
			pass
		S.AT_DESTINATION:
			pass
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
