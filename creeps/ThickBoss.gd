extends Creep

func init(level, dest):
	KIND = "Thick"
	BASE_HEALTH = 172.5
	SPEED = 32
	is_boss = true
	STATUS_REDUCTION = 0.5
	.init(level, dest)