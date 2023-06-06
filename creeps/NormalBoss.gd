extends Creep

func init(level, dest):
	is_boss = true
	RESIST_CHANCE = 0.35
	STATUS_REDUCTION = 0.5
	.init(level, dest)