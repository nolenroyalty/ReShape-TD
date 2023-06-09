extends Node2D

signal reshape(shape)
signal selected(shape)
signal shape_cleared

onready var cross = $Control/CrossButton
onready var crescent = $Control/CrescentButton
onready var diamond = $Control/DiamondButton

onready var cross_label = $Control/Labels/CrossTower
onready var crescent_label = $Control/Labels/CrescentTower
onready var diamond_label = $Control/Labels/DiamondTower

onready var reshape_button = $Control/ReShapeButton
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

func set_cost_text_color():
	if cant_afford():
		cost_label.set("custom_colors/font_color", C.RED)
	else:
		cost_label.set("custom_colors/font_color", Color("#ac82b2"))

func set_cost_text(cost):
	cost_label.text = "Build cost: %d gold" % cost
	
func cant_afford():
	return current != null and not State.can_buy(Upgrades.tower_cost(current))

var prior_cost = 0
func tween_up_cost():
	set_cost_text_color()
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
		cost_tween.stop_all()
		prior_cost = Upgrades.tower_cost(current)
		set_cost_text(Upgrades.tower_cost(current))
		set_cost_text_color()

	var active_upgrades = Upgrades.active_upgrades(current)
	if len(active_upgrades) == 0: upgrades_label.text = "Upgrades:\nNone yet!"
	else:
		var l = []
		for u in active_upgrades:
			l.append("* " + Upgrades.title(u))
		upgrades_label.text = "Upgrades:\n" + "\n".join(l)

func handle_reshaped(shape, _upgrade):
	if current != null and shape == current:
		update_info_text(true)

func configure_ui():
	update_selected()
	update_info_text()
	reshape_button.set_shape(current)

func clear_shape():
	current = null 
	configure_ui()
	emit_signal("shape_cleared")

func set_shape(kind):
	current = kind
	configure_ui()

func handle_shape_pressed(kind):
	set_shape(kind)
	emit_signal("selected", kind)

func gold_updated(_amount):
	set_cost_text_color()

func handle_reshape_pressed(shape):
	if shape != current:
		print("BUG! reshape_pressed called with shape != current %s != %s" % [shape, current])
		return
	else:
		emit_signal("reshape", shape)

func _process(_delta):
	# if Input.is_action_just_pressed("reshape_tower") and current != null:
		# handle_reshape_pressed()
	if Input.is_action_just_pressed("cancel_build_tower") and current != null:
		clear_shape()

func _ready():
	cross.connect("pressed", self, "handle_shape_pressed", [C.SHAPE.CROSS])
	crescent.connect("pressed", self, "handle_shape_pressed", [C.SHAPE.CRESCENT])
	diamond.connect("pressed", self, "handle_shape_pressed", [C.SHAPE.DIAMOND])
	reshape_button.connect("reshape", self, "handle_reshape_pressed")
	var _ignore = State.connect("gold_updated", self, "gold_updated")
	_ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
	configure_ui()
