extends Node2D

signal reshape(shape)
signal selected(shape)

onready var cross = $CrossButton
onready var crescent = $CrescentButton
onready var diamond = $DiamondButton
onready var selected = $SelectedLabel
onready var reshape_button = $ReshapeButton

var current = null

func update_selected_text():
	var t = "Selected: "
	match current:
		null: selected.text = "%s None" % t
		C.SHAPE.CROSS: selected.text = "%s Cross" % t
		C.SHAPE.CRESCENT: selected.text = "%s Crescent" % t
		C.SHAPE.DIAMOND: selected.text = "%s Diamond" % t

func set_shape(kind):
	current = kind
	update_selected_text()

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