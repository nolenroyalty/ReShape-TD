extends Node2D

signal chosen(shape, upgrade)
signal cancelled(shape)

onready var left = $Background/Choices/Left
onready var right = $Background/Choices/Right
onready var center = $Background/Choices/Center
onready var title = $Background/Title
onready var current = $Background/CurrentUpgrades
onready var cancel = $Background/Cancel

func on_button_pressed(shape, upgrade):
	print("Chose %s for %s" % [Upgrades.title(upgrade), C.shape_name(shape)])
	emit_signal("chosen", shape, upgrade)

func cancelled(shape):
	print("Cancelled upgrade for %s" % C.shape_name(shape))
	emit_signal("cancelled", shape)

func set_shape(shape):
	var name = C.shape_name(shape).capitalize()
	title.text = "Choose an upgrade for all %s towers" % name
	var active = Upgrades.active_upgrades(shape)
	if active.size() == 0:
		current.text = "Already active upgrades: None"
	else:
		var l = []
		for a in active:
			l.append(C.title(a))
		current.text = "Already active upgrades: %s" % ", ".join(l)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var possible = Upgrades.possible_upgrades(shape)
	var chosen = []
	for _i in range(3):
		if len(possible) == 0:
			# We've run out of choices
			break
		var choice = rng.randi_range(0, possible.size() - 1)
		chosen.append(possible[choice])
		possible.remove(choice)
	
	if len(chosen) < 3:
		# We've run out of choices
		cancelled(shape)
		return
	
	left.set_upgrade_text(chosen[0])
	right.set_upgrade_text(chosen[1])
	center.set_upgrade_text(chosen[2])
	
	left.connect("pressed", self, "on_button_pressed", [shape, chosen[0]])
	right.connect("pressed", self, "on_button_pressed", [shape, chosen[1]])
	center.connect("pressed", self, "on_button_pressed", [shape, chosen[2]])
	cancel.connect("pressed", self, "cancelled", [shape])

func _ready():
	set_shape(C.SHAPE.CROSS)
