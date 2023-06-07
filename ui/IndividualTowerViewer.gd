extends Node2D

signal tower_sold()

onready var header = $Header
onready var values = $HBoxContainer/Values
onready var level_up_button = $LevelUpButton
onready var sell_button = $SellButton
var tower = null

func init(tower_):
	tower = tower_

func set_text_for_tower():
	var stats = tower.my_stats
	var name = C.shape_name(tower.my_shape).capitalize()
	header.text = "%s Tower (level %s)\n" % [name, stats.LEVEL]
	values.text = "%.1f\n%s\n%s" % [ stats.attacks_per_second(), stats.DAMAGE, stats.RANGE_RADIUS]

	sell_button.text = " Sell (%s gold) " % tower.sell_value
	var upgrade_cost = Upgrades.upgrade_cost(tower.my_shape, tower.my_stats)
	level_up_button.text = " Level up (%s gold) " % upgrade_cost

func we_have_enough_gold_for_upgrade():
	return true

func on_level_up_button_pressed():
	if we_have_enough_gold_for_upgrade():
		tower.level_up()

func on_sell_button_pressed():
	emit_signal("tower_sold")
	tower.sell()

func _ready():
	assert(tower != null, "tower must be set before adding to scene!")
	level_up_button.connect("pressed", self, "on_level_up_button_pressed")
	sell_button.connect("pressed", self, "on_sell_button_pressed")
	tower.connect("leveled_up", self, "set_text_for_tower")
	set_text_for_tower()
