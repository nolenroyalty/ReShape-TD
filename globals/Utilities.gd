extends Node

var GRID

func v (x, y): return Vector2(x, y)

func center(pos):
	return pos + v(1, 1) * (C.CELL_SIZE / 2)

func snap_to_grid(pos):
	var x = int(pos.x / C.CELL_SIZE) * C.CELL_SIZE
	var y = int(pos.y / C.CELL_SIZE) * C.CELL_SIZE
	return v(x, y)

func mouse_position():
	return get_viewport().get_mouse_position()

func get_closest_creep(center, radius, ignore_if_present=null):
	var distance = null
	var closest = null
	if ignore_if_present == null:
		ignore_if_present = {}

	for area in radius.get_overlapping_areas():
		var creep = area.get_parent()
		if creep.is_in_group("creep") and creep.is_alive() and is_instance_valid(creep):
			if creep in ignore_if_present:
				continue
			var d = center.distance_to(creep.position)
			if distance == null or d < distance:
				distance = d
				closest = creep
	
	return closest