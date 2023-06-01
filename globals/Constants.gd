extends Node

enum SHAPE { CROSS, CRESCENT, DIAMOND }

func shape_name(shape):
	match shape:
		SHAPE.CROSS:
			return "cross"
		SHAPE.CRESCENT:
			return "crescent"
		SHAPE.DIAMOND:
			return "diamond"

const CELL_SIZE = 16

const LIGHT_BLUE = Color("#5e8b9b")
const RED = Color("#8e3a47")
const DARK_GREEN = Color("#3f6050")
