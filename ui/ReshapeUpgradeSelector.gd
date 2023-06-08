extends Node2D

signal reshape(shape)
signal selected(shape)

onready var cross = $Control/CrossButton
onready var crescent = $Control/CrescentButton
onready var diamond = $Control/DiamondButton

onready var cross_label = $Control/Labels/CrossTower
onready var crescent_label = $Control/Labels/CrescentTower
onready var diamond_label = $Control/Labels/DiamondTower

onready var reshape_button = $Control/ReshapeButton
onready var upgrades_label = $Control/Labels/UpgradesLabel
onready var cost_label = $Control/Labels/CostLabel

onready var cost_tween = $CostTween

var current = null

func button_(shape):
	match shape:
		C.SHAPE.CROSS: return cross
		C.SHAPE.CRESCENT: return crescent
		C.SHAPE.DIAMOND: return diamond

func shape_label(shape):
	match shape:
		C.SHAPE.CROSS: return cross_label
		C.SHAPE.CRESCENT: return crescent_label
		C.SHAPE.DIAMOND: return diamond_label

func update_selected():
	for shape in C.shapes:
		var b = button_(shape)
		var l = shape_label(shape)
		if shape == current:
			b.modulate.a = 1.0
			l.show()
		else:
			b.modulate.a = 0.35
			l.hide()

func set_cost_text(cost):
	cost_label.text = "Build cost: %d gold" % cost

var prior_cost = 0
func tween_up_cost():
	cost_tween.stop_all()
	cost_tween.interpolate_method(self, "set_cost_text", prior_cost, Upgrades.tower_cost(current), 1.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	cost_tween.start()
	prior_cost = Upgrades.tower_cost(current)

func update_info_text(tween_cost=false):
	if current == null:
		cost_label.text = ""
		upgrades_label.text = ""
		return
	
	if tween_cost:
		tween_up_cost()
	else:
		prior_cost = Upgrades.tower_cost(current)
		set_cost_text(Upgrades.tower_cost(current))
		#var build_cost = "Build Cost: %d gold" % [Upgrades.tower_cost(current)]
		# cost_label.text = build_cost

	var active_upgrades = Upgrades.active_upgrades(current)
	if len(active_upgrades) == 0: upgrades_label.text = "Upgrades:\nNone yet!"
	else:
		var l = []
		for u in active_upgrades:
			l.append("* " + Upgrades.title(u))
		upgrades_label.text = "Upgrades:\n" + "\n".join(l)

func update_reshape_button_cost():
	if current == null:
		reshape_button.hide()
		return

	reshape_button.show()
	var cost = Upgrades.reshape_cost(current)
	var remaining = Upgrades.possible_upgrades(current)
	
	if len(remaining) < 3:
		reshape_button.text = "No upgrades left"
	else:
		reshape_button.text = "ReShape: %d gold" % [cost]

func handle_reshaped(shape, _upgrade):
	if current != null and shape == current:
		update_info_text(true)
		update_reshape_button_cost()
		update_disabled_state()

func update_disabled_state():
	if current ==  null:
		return

	var cost = Upgrades.reshape_cost(current)
	var gold = State.gold
	var remaining = Upgrades.possible_upgrades(current)
	reshape_button.disabled = cost > gold or len(remaining) < 3

func configure_ui():
	update_selected()
	update_info_text()
	update_reshape_button_cost()
	update_disabled_state()

func clear_shape():
	current = null 
	configure_ui()

func set_shape(kind):
	current = kind
	configure_ui()

func handle_shape_pressed(kind):
	set_shape(kind)
	emit_signal("selected", kind)

func handle_reshape_pressed():
	if current == null: return
	var cost = Upgrades.reshape_cost(current)
	if State.can_buy(cost):
		emit_signal("reshape", current)

func gold_updated(_amount):
	update_disabled_state()

func _ready():
	cross.connect("pressed", self, "handle_shape_pressed", [C.SHAPE.CROSS])
	crescent.connect("pressed", self, "handle_shape_pressed", [C.SHAPE.CRESCENT])
	diamond.connect("pressed", self, "handle_shape_pressed", [C.SHAPE.DIAMOND])
	reshape_button.connect("pressed", self, "handle_reshape_pressed")
	var _ignore = State.connect("gold_updated", self, "gold_updated")
	_ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
	configure_ui()
