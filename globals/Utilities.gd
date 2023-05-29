extends Node

func v (x, y): return Vector2(x, y)

func center(pos):
	return pos + v(1, 1) * (C.CELL_SIZE / 2)

func snap_to_grid(pos):
	return (pos / C.CELL_SIZE) * C.CELL_SIZE

func mouse_position():
	return get_viewport().get_mouse_position()