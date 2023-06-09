extends Node

enum SHAPE { CROSS, CRESCENT, DIAMOND }

var shapes = [ SHAPE.CROSS, SHAPE.CRESCENT, SHAPE.DIAMOND ]

const BASE_TOWER_COST = 5
const RANK_UP_COST_MULT = 2.0
const MAX_LEVEL = 5
const MAX_UPGRADES = 5

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
const BLACK = Color("#1b1b17")
const YELLOW = Color("#d8b47a")
const LIGHT_GREEN = Color("#6b7636")

enum CREEP_KIND { NORMAL, QUICK, THICK, RESISTANT }

func creep_name(creep):
	match creep:
		CREEP_KIND.NORMAL:
			return "normal"
		CREEP_KIND.QUICK:
			return "quick"
		CREEP_KIND.THICK:
			return "thick"
		CREEP_KIND.RESISTANT:
			return "resistant"