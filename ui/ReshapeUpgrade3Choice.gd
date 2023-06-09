extends CanvasLayer

signal chosen(shape, upgrade)
signal cancelled(shape)

var UpgradeButton = preload("res://ui/UpgradeButton.tscn")

onready var title = $Background/Title
onready var current = $Background/CurrentUpgrades
# onready var cancel = $Background/Cancel

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
		current.text = "Active Upgrades: None"
	else:
		var l = []
		for a in active: 
			l.append(Upgrades.title(a))
		current.text = "Active Upgrades:\n%s" % "\n".join(l)
	
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
	
	if len(chosen) < 1:
		# We've run out of choices
		cancelled(shape)
		return
	
	for choice in chosen:
		var button = UpgradeButton.instance()
		button.set_upgrade_text(choice)
		$Background/Choices.add_child(button)
		button.connect("pressed", self, "on_button_pressed", [shape, choice])
