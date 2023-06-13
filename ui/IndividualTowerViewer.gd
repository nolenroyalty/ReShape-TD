extends Node2D

signal tower_sold()
signal reshape(shape)
signal clear_tower_viewer()

onready var title = $Title
onready var rank_up = $Grid/RankUp
onready var sell = $Grid/Sell
onready var damage = $Grid/Damage
onready var aps = $Grid/APS
onready var range_text = $Grid/Range
onready var kills = $Grid/Kills
onready var status_text = $Grid/Status
onready var anim = $AnimationPlayer

var tower = null

onready var cross_sprite = $CrossSprite
onready var diamond_sprite = $DiamondSprite
onready var crescent_sprite = $CrescentSprite

func init(tower_):
	tower = tower_

func set_level_up_status():
	var rank_up_cost = tower.rank_up_cost()
	if rank_up_cost == null:
		rank_up.disabled = true
	else:
		rank_up.disabled = not State.can_buy(rank_up_cost)

func set_sprite():
	var shape = tower.my_shape
	cross_sprite.visible = shape == C.SHAPE.CROSS
	diamond_sprite.visible = shape == C.SHAPE.DIAMOND
	crescent_sprite.visible = shape == C.SHAPE.CRESCENT

func set_text_for_tower():
	var stats = tower.my_stats
	var name = C.shape_name(tower.my_shape).capitalize()
	
	title.text = "%s Tower Rank %d" % [name, stats.LEVEL]

	var cost = tower.rank_up_cost()
	if cost == null:
		rank_up.text = "Max Rank"
	else:
		rank_up.text = "Rank Up: %s gold" % cost
		
	sell.text = "Sell: %s gold" % tower.sell_value()

	damage.text = "%d" % int(stats.DAMAGE * Upgrades.damage_mult(tower.my_shape))
	aps.text = "%.1f" % stats.attacks_per_second()
	range_text.text = "%d" % int(stats.RANGE_RADIUS)
	kills.text = "%d" % tower.kills
	status_text.text = "%.1f" % stats.STATUS_MULTIPLIER

	set_sprite()
	set_level_up_status()

func on_level_up_button_pressed():
	if rank_up.disabled:
		return
	var cost = tower.rank_up_cost()
	if cost == null:
		return
	tower.level_up()

func on_sell_button_pressed():
	emit_signal("tower_sold")
	tower.sell()

func on_gold_changed(_gold):
	set_level_up_status()

func handle_reshaped(shape, _upgrade):
	if tower and tower.my_shape == shape:
		set_text_for_tower()

func reshape_button_pressed(shape):
	if shape != tower.my_shape:
		print("BUG: reshape button pressed but it sent a shape other than mine (%s / %s)" % [shape, tower.my_shape])
	else:
		emit_signal("reshape", tower.my_shape)

func handle_tower_leveled():
	anim.stop()
	set_text_for_tower()

func handle_tower_sold():
	tower = null
	emit_signal("clear_tower_viewer")

func _process(_delta):
	if Input.is_action_just_pressed("sell_tower"):
		on_sell_button_pressed()
	if Input.is_action_just_pressed("upgrade_tower"):
		on_level_up_button_pressed()
	
func _ready():
	assert(tower != null, "tower must be set before adding to scene!")
	rank_up.connect("pressed", self, "on_level_up_button_pressed")
	sell.connect("pressed", self, "on_sell_button_pressed")
	tower.connect("leveled_up", self, "handle_tower_leveled")
	tower.connect("killed", self, "set_text_for_tower")
	tower.connect("sold", self, "handle_tower_sold")
	# reshape_button.connect("reshape", self, "reshape_button_pressed")
	
	var _ignore = State.connect("gold_updated", self, "on_gold_changed")
	_ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
	set_text_for_tower()
	if not State.has_ranked_up_ever and State.wave__hack_for_tower_to_access_this > 3:
		# Pulse the rankup thing a bit if it hasn't been used a few waves in so that folks realize it's there.
		anim.play("pulse_rankup")
