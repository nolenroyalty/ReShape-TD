extends Node2D

signal tower_sold()

onready var header = $Header
onready var values = $HBoxContainer/Values
onready var level_up_button = $LevelUpButton
onready var sell_button = $SellButton
var tower = null

func init(tower_):
	tower = tower_

func set_level_up_status():
	var upgrade_cost = tower.upgrade_cost()
	level_up_button.disabled = not State.can_buy(upgrade_cost)

func set_text_for_tower():
	var stats = tower.my_stats
	var name = C.shape_name(tower.my_shape).capitalize()
	header.text = "%s Tower (level %s)\n" % [name, stats.LEVEL]
	values.text = "%.1f\n%s\n%s" % [ stats.attacks_per_second(), stats.DAMAGE, stats.RANGE_RADIUS]

	sell_button.text = " Sell (%s gold) " % tower.sell_value
	level_up_button.text = " Level up (%s gold) " % tower.upgrade_cost()
	set_level_up_status()

func on_level_up_button_pressed():
	var cost = tower.upgrade_cost()
	if State.try_to_buy(cost):
		tower.level_up()

func on_sell_button_pressed():
	emit_signal("tower_sold")
	tower.sell()

func on_gold_changed(_gold):
	set_level_up_status()

func _ready():
	assert(tower != null, "tower must be set before adding to scene!")
	level_up_button.connect("pressed", self, "on_level_up_button_pressed")
	sell_button.connect("pressed", self, "on_sell_button_pressed")
	tower.connect("leveled_up", self, "set_text_for_tower")
	var _ignore = State.connect("gold_updated", self, "on_gold_changed")
	set_text_for_tower()
