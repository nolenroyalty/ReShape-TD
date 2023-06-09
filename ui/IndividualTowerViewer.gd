extends Node2D

signal tower_sold()

onready var title = $Title
onready var rank_up = $Grid/RankUp
onready var sell = $Grid/Sell
onready var damage = $Grid/Damage
onready var aps = $Grid/APS
onready var range_text = $Grid/Range
onready var kills = $Grid/Kills
var tower = null

onready var cross_sprite = $CrossSprite
onready var diamond_sprite = $DiamondSprite
onready var crescent_sprite = $CrescentSprite

func init(tower_):
	tower = tower_

func set_level_up_status():
	var upgrade_cost = tower.upgrade_cost()
	rank_up.disabled = not State.can_buy(upgrade_cost)

func set_sprite():
	var shape = tower.my_shape
	cross_sprite.visible = shape == C.SHAPE.CROSS
	diamond_sprite.visible = shape == C.SHAPE.DIAMOND
	crescent_sprite.visible = shape == C.SHAPE.CRESCENT

func set_text_for_tower():
	var stats = tower.my_stats
	var name = C.shape_name(tower.my_shape).capitalize()
	
	title.text = "%s Tower Rank %d" % [name, stats.LEVEL]

	rank_up.text = "Upgrade: %s gold" % tower.upgrade_cost()
	sell.text = "Sell: %s gold" % tower.sell_value()

	damage.text = "%d" % int(stats.DAMAGE * Upgrades.damage_mult(tower.my_shape))
	aps.text = "%.1f" % stats.attacks_per_second()
	range_text.text = "%d" % int(stats.RANGE_RADIUS)
	kills.text = "%d" % tower.kills

	set_sprite()
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

func handle_reshaped(shape, _upgrade):
	if tower and tower.my_shape == shape:
		set_text_for_tower()

func _process(_delta):
	if Input.is_action_just_pressed("sell_tower"):
		on_sell_button_pressed()
	if Input.is_action_just_pressed("upgrade_tower"):
		on_level_up_button_pressed()
	
func _ready():
	assert(tower != null, "tower must be set before adding to scene!")
	rank_up.connect("pressed", self, "on_level_up_button_pressed")
	sell.connect("pressed", self, "on_sell_button_pressed")
	tower.connect("leveled_up", self, "set_text_for_tower")
	tower.connect("killed", self, "set_text_for_tower")
	
	var _ignore = State.connect("gold_updated", self, "on_gold_changed")
	_ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
	set_text_for_tower()
