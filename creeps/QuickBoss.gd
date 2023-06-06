extends Creep

func init(level, dest):
	KIND = "Quick"
	BASE_HEALTH = 40
	SPEED = 80
	RESIST_CHANCE = 0.35
	STATUS_REDUCTION = 0.5
	is_boss = true
	.init(level, dest)