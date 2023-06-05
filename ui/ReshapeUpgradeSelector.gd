extends Node2D

signal reshape(shape)
signal selected(shape)

onready var cross = $CrossButton
onready var crescent = $CrescentButton
onready var diamond = $DiamondButton
onready var reshape_button = $ReshapeButton
onready var info_label = $InfoLabel

var current = null

func button_(shape):
	match shape:
		C.SHAPE.CROSS: return cross
		C.SHAPE.CRESCENT: return crescent
		C.SHAPE.DIAMOND: return diamond

func update_selected():
	for shape in C.shapes:
		var b = button_(shape)
		if shape == current:
			b.modulate.a = 1.0
		else:
			b.modulate.a = 0.5

func update_info_text():
	var build_cost = "Build cost: %d gold" % [Upgrades.tower_cost(current)]
	var active_upgrades = Upgrades.active_upgrades(current)
	var l = [build_cost]
	for u in active_upgrades:
		l.append(Upgrades.title(u))
	info_label.text = "\n".join(l)

func update_reshape_button_cost():
	if current == null: return
	var cost = Upgrades.reshape_cost(current)
	reshape_button.text = "Reshape (%d gold)" % [cost]

func handle_reshaped(shape, _upgrade):
	if current != null and shape == current:
		update_info_text()
		update_reshape_button_cost()

func set_shape(kind):
	current = kind
	update_selected()
	update_info_text()
	update_reshape_button_cost()

func handle_pressed(kind):
	set_shape(kind)
	emit_signal("selected", kind)

func handle_reshape_pressed():
	var cost = Upgrades.reshape_cost(current)
	if current != null and State.can_buy(cost):
		emit_signal("reshape", current)

func _ready():
	cross.connect("pressed", self, "handle_pressed", [C.SHAPE.CROSS])
	crescent.connect("pressed", self, "handle_pressed", [C.SHAPE.CRESCENT])
	diamond.connect("pressed", self, "handle_pressed", [C.SHAPE.DIAMOND])
	reshape_button.connect("pressed", self, "handle_reshape_pressed")
	var _ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
