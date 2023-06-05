extends Label

func handle_lives_updated(amount):
	text = "Lives: " + str(amount)

func _ready():
	var _ignore = State.connect("lives_updated", self, "handle_lives_updated")
