extends Button
signal reshape(shape)

var shape = null

func disable_or_enable_for_cost(_amount_ignore):
	if shape == null:
		hide()
		disabled = true
	elif there_are_upgrades_remaining(shape):
		var cost = Upgrades.reshape_cost(shape)
		disabled = not State.can_buy(cost)

func there_are_upgrades_remaining(shape_):
	return len(Upgrades.possible_upgrades(shape_)) > 0

func set_shape(shape_):
	shape = shape_
	if shape == null:
		hide()
		return
	show()
	
	var cost = Upgrades.reshape_cost(shape)

	if not there_are_upgrades_remaining(shape):
		text = "No upgrades left"
		disabled = true
	else:
		text = "Reshape: %d gold" % cost
		disable_or_enable_for_cost(0)

func pressed():
	if shape == null:
		return
	var cost = Upgrades.reshape_cost(shape)

	if there_are_upgrades_remaining(shape) and State.can_buy(cost):
		emit_signal("reshape", shape)

func reshaped(shape_, _upgrade):
	if shape_ == shape:
		set_shape(shape_)

func _ready():
	var _ignore = self.connect("pressed", self, "pressed")
	_ignore = State.connect("gold_updated", self, "disable_or_enable_for_cost")
	_ignore = Upgrades.connect("reshaped", self, "reshaped")
