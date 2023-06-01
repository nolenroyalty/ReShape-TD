extends Node2D

signal upgrade_tower(tower)
signal sell_tower(tower)

onready var label = $Label
onready var upgrade_button = $UpgradeButton
onready var sell_button = $SellButton
var tower = null

func init(tower_):
	tower = tower_
	var stats = tower.my_stats
	var name = C.shape_name(tower.my_shape).capitalize()
	var header = "Level %s %s Tower\n" % [stats.LEVEL, name]
	var aps = "Attacks per second: %.1f" % stats.attacks_per_second()
	var damage = "Damage: %s" % stats.DAMAGE
	var range_ = "Range: %s" % stats.RANGE_RADIUS

	$Label.text = "%s\n%s\n%s\n%s" % [header, aps, damage, range_]

func on_upgrade_button_pressed():
	emit_signal("upgrade_tower", tower)

func on_sell_button_pressed():
	emit_signal("sell_tower", tower)

func _ready():
	assert(tower != null, "tower must be set before adding to scene!")
	upgrade_button.connect("pressed", self, "on_upgrade_button_pressed")
	sell_button.connect("pressed", self, "on_sell_button_pressed")
