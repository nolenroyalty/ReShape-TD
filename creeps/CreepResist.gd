extends Creep

func init(level, dest):
	KIND = "Resistant"
	RESIST_CHANCE = 0.5
	STATUS_REDUCTION = 0.5
	.init(level, dest)