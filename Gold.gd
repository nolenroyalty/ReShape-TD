extends Label

func handle_gold_updated(amount):
	text = "Gold: " + str(amount)

func _ready():
	var _ignore = State.connect("gold_updated", self, "handle_gold_updated")
