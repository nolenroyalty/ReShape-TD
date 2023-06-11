extends Creep

func init(level, dest):
	KIND = "Pack"
	BASE_HEALTH = 26
	RESIST_CHANCE = 0.25
	STATUS_REDUCTION = 0.25
	is_boss = true
	.init(level, dest)