extends Node2D

const WIDTH = 32
const HEIGHT = 24

# Maybe this should keep track of whether we can build a tower at a given position? But it's possible
# that it's easier to do that by just checking a potential tower's position and seeing if it collides
# with any entities. Not sure yet.

signal mouse_buildable_grid_position(pos)
signal mouse_left_buildable_grid()

onready var bounds = $Bounds
var mouse_present = false
var last_mouse_pos = null

func overlay_lines():
	pass

func pathable_points():
	var points = []
	for x in range(WIDTH):
		for y in range(HEIGHT):
			points.append(U.v(x, y) * C.CELL_SIZE)
	return points

func mouse_entered():
	mouse_present = true

func mouse_exited():
	# Work around the case that we get a "mouse exited" signal when the mouse hovers over a creep or tower :/
	var mouse_grid_pos = determine_mouse_coordinates()

	if mouse_grid_pos.x < 0 or mouse_grid_pos.x >= WIDTH * C.CELL_SIZE \
		or mouse_grid_pos.y < 0 or mouse_grid_pos.y >= HEIGHT * C.CELL_SIZE:

		mouse_present = false
		last_mouse_pos = null
		emit_signal("mouse_left_buildable_grid")
	elif last_mouse_pos == null or last_mouse_pos != mouse_grid_pos:
			last_mouse_pos = mouse_grid_pos
			emit_signal("mouse_buildable_grid_position", mouse_grid_pos)

func determine_mouse_coordinates():
	# If we're at 16, 16 and the mouse is at 32, 32, the mouse's position relative to our
	# position is 16, 16
	# Maybe there's just a way to get this directly? I don't know.

	# Also I'm a little worried that it's expensive to check this on every frame. Oh well.
	var relative_mouse_pos = U.mouse_position() - global_position
	var mouse_grid_pos = U.snap_to_grid(relative_mouse_pos)

	# We can't build a tower that starts in the last row or column, so bump the mouse over.
	if mouse_grid_pos.x == (WIDTH - 1) * C.CELL_SIZE:
		mouse_grid_pos.x -= C.CELL_SIZE
	if mouse_grid_pos.y == (HEIGHT - 1) * C.CELL_SIZE:
		mouse_grid_pos.y -= C.CELL_SIZE
	
	return mouse_grid_pos

func emit_mouse_coordinates():
	var mouse_grid_pos = determine_mouse_coordinates()
	if last_mouse_pos == null or last_mouse_pos != mouse_grid_pos:
		last_mouse_pos = mouse_grid_pos
		emit_signal("mouse_buildable_grid_position", mouse_grid_pos)

func _process(_delta):
	if mouse_present:
		emit_mouse_coordinates()

func _ready():
	var _ignore = bounds.connect("mouse_entered", self, "mouse_entered")
	_ignore = bounds.connect("mouse_exited", self, "mouse_exited")