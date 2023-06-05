extends Node2D

signal reshape(shape)
signal selected(shape)

onready var cross = $CrossButton
onready var crescent = $CrescentButton
onready var diamond = $DiamondButton
onready var reshape_button = $ReshapeButton
onready var upgrades_label = $UpgradesLabel
onready var base_cost = $BasecostLabel

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

func update_base_cost_text():
	if current == null: return
	var tower_cost = Upgrades.tower_cost(current)
	base_cost.text = "Base cost: %d gold" % [tower_cost]

func handle_reshaped(shape, _upgrade):
	if current != null and shape == current:
		update_base_cost_text()
	
func update_upgrades_text():
	var active_upgrades = Upgrades.active_upgrades(current)
	var l = []
	for u in active_upgrades:
		l.append(Upgrades.title(u))
		
	upgrades_label.text = "\n".join(l)

func set_shape(kind):
	current = kind
	update_selected()
	update_upgrades_text()

func handle_pressed(kind):
	set_shape(kind)
	emit_signal("selected", kind)

func handle_reshape():
	if current != null:
		print("reshape %s!" % [C.shape_name(current)])
		emit_signal("reshape", current)

func _ready():
	cross.connect("pressed", self, "handle_pressed", [C.SHAPE.CROSS])
	crescent.connect("pressed", self, "handle_pressed", [C.SHAPE.CRESCENT])
	diamond.connect("pressed", self, "handle_pressed", [C.SHAPE.DIAMOND])
	reshape_button.connect("pressed", self, "handle_reshape")
	var _ignore = Upgrades.connect("reshaped", self, "handle_reshaped")
