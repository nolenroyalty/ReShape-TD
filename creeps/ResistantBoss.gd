extends Creep

func init(level, dest):
	is_boss = true
	KIND = "Resistant"
	RESIST_CHANCE = 0.85
	STATUS_REDUCTION = 0.75
	.init(level, dest)