extends Node2D

signal tower_sold()

onready var label = $Label
onready var level_up_button = $LevelUpButton
onready var sell_button = $SellButton
var tower = null

func init(tower_):
	tower = tower_

func set_text_for_tower():
	var stats = tower.my_stats
	var name = C.shape_name(tower.my_shape).capitalize()
	var header = "Level %s %s Tower\n" % [stats.LEVEL, name]
	var aps = "Attacks per second: %.1f" % stats.attacks_per_second()
	var damage = "Damage: %s" % stats.DAMAGE
	var range_ = "Range: %s" % stats.RANGE_RADIUS

	$Label.text = "%s\n%s\n%s\n%s" % [header, aps, damage, range_]

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
