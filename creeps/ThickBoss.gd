extends Creep

func init(level, dest):
	KIND = "Thick"
	BASE_HEALTH = 100
	SPEED = 28
	is_boss = true
	STATUS_REDUCTION = 0.5
	.init(level, dest)