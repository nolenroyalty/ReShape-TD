extends Node2D

var astar : AStar2D

func init(points):
	# it's a point set. heh heh he.
	var point_setta = {}
	
	for point in points:
		point_setta[point] = true
	
		var id = _id_of_point(point)
		astar.add_point(id, point)
	
	for point in points:
		for neighbor in _potential_neighbors(point):
			if point_setta.has(neighbor):
				var my_id = _id_of_point(point)
				var neighbor_id = _id_of_point(neighbor)
				astar.connect_points(my_id, neighbor_id, true)

func compute_path(start, end):
	# It might be nice to add some memoization here, partially for efficiency (maybe) but also
	# so that everyone takes the same path when it's ambiguous.
	return astar.get_point_path(_id_of_point(start), _id_of_point(end))

func disable_points(points):
	print("Disabling points: %s" % [points])
	for point in points:
		var id = _id_of_point(point)
		if astar.is_point_disabled(id):
			print("Asked to disable point %s but it was already disabled!" % [point])
		else:
			astar.set_point_disabled(id, true)

func enable_points(points):
	print("Enabling points: %s" %  [points])
	for point in points:
		var id = _id_of_point(point)
		if not astar.is_point_disabled(id):
			print("Asked to enable point %s but it was already enabled!" % [point])
		else:
			astar.set_point_disabled(id, false)

func _id_of_point(v):
	assert(v.x % C.CELL_SIZE == 0, "Pathable point must be a multiple of cell size: %s" % [v])
	assert(v.y % C.CELL_SIZE == 0, "Pathable point must be a multiple of cell size: %s" % [v])

	var x = int(v.x / C.CELL_SIZE)
	var y = int(v.y / C.CELL_SIZE)

	return (x << 8) | y

func _point_of_id(id):
	var x = (id >> 8) * C.CELL_SIZE
	var y = (id & 0xFF) * C.CELL_SIZE

	return U.v(x, y)

func _potential_neighbors(point):
	var neighbors = []
	for dx in [-C.CELL_SIZE, 0, C.CELL_SIZE]:
		for dy in [-C.CELL_SIZE, 0, C.CELL_SIZE]:
			if dx == 0 and dy == 0:
				continue # don't include self
			
			if dx != 0 and dy != 0:
				# We choose to skip diagonals because otherwise we need to handle some tricky cases.
				# With only UDLR movement, when we build a tower we just disable movement through the
				# cells belonging to that tower. With diagonals, we need to account for cases like this
				#
				# T1 XX
				# YY T2
				#
				# When we build T2, we need to disable movement from YY to XX even though there's no tower
				# on either square!
				# Maybe we'll come back and change this later.
				continue
			
			var neighbor = point + U.v(dx, dy)
			neighbors.append(neighbor)
	
	# A neat thing is that we don't need to do any bounds checking here because we're just gonna check if the
	# point is in our valid points set :)
	return neighbors
			