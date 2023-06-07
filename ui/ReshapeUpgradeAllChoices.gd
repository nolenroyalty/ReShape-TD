extends CanvasLayer

signal upgrade_purchased()
signal cancelled()

onready var cont = $VBoxContainer

var shape = null

func handle_button_pressed(upgrade):
	var cost = Upgrades.reshape_cost(shape)
	if State.try_to_buy(cost):
		Upgrades.upgrade(shape, upgrade)
		print("Purchased upgrade %s" % [Upgrades.title(upgrade)])
		emit_signal("upgrade_purchased")
	else:
		print("POTENTIAL BUG: Not enough money to buy an upgrade from the upgrade picker")
		emit_signal("cancelled")

func handle_cancel():
	emit_signal("cancelled")

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
	
	var button = Button.new()
	button.text = "Cancel"
	button.connect("pressed", self, "handle_cancel")
	cont.add_child(button)

func _ready():
	assert(shape != null, "shape must be set before adding to scene")
	render()
