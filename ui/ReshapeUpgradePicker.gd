extends CanvasLayer

signal upgrade_purchased()

onready var cont = $VBoxContainer

var shape = null

func handle_button_pressed(upgrade):
	Upgrades.upgrade(shape, upgrade)
	print("Purchased upgrade %s" % [Upgrades.title(upgrade)])
	emit_signal("upgrade_purchased")

func init(shape_):
	shape = shape_

func render():
	cont.get_node("Example1").queue_free()
	cont.get_node("Example2").queue_free()

	var upgrades = Upgrades.possible_upgrades(shape)

	for upgrade in upgrades:
		var button = Button.new()
		button.text = Upgrades.title(upgrade)
		button.connect("pressed", self, "handle_button_pressed", [upgrade])
		cont.add_child(button)

func _ready():
	assert(shape != null, "shape must be set before adding to scene")
	render()
