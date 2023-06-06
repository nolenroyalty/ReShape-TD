extends Creep

func init(level, dest):
	KIND = "Quick"
	BASE_HEALTH = 40
	SPEED = 80
	RESIST_CHANCE = 35
	is_boss = true
	.init(level, dest)