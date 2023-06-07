extends Label

func score_updated(amount):
	text = "Score: %s" % amount

func _ready():
	var _ignore = State.connect("score_updated", self, "score_updated")