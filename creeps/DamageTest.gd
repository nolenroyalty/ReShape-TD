extends Creep

signal damage_test_complete(damage_done, killed)
const STARTING_HEALTH = 50000000

func init(level, dest):
	KIND = "Mega"
	BASE_HEALTH = 1
	SPEED = 40
	RESIST_CHANCE = 0.40
	STATUS_REDUCTION = 0.40
	is_boss = true
	.init(level, dest)

func maybe_do_something_on_death():
	var damage_done = compute_damage_done()
	emit_signal("damage_test_complete", damage_done, true)

func compute_health():
	return STARTING_HEALTH

func compute_damage_done():
	return STARTING_HEALTH - health

func lose_life_unless_you_are_the_damage_test():
	var damage_done = compute_damage_done()
	var killed = health < 0
	emit_signal("damage_test_complete", damage_done, killed)

func score_amount():
	return 10000