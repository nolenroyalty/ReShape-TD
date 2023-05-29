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