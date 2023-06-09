extends CanvasLayer

signal play_again()

onready var title = $NinePatchRect/Title
onready var score_label = $NinePatchRect/ScoreLabel
onready var button = $NinePatchRect/Button

func set_text(won_game, wave_bonus):
	if won_game:
		title.text = "You won!!"
	else:
		title.text = "You lost :("
	
	var score = State.score
	var life_penalty = State.life_penalty
	var killscore = "Kill score: %d" % (score - wave_bonus + life_penalty)
	var wavebonus = "Bonus from sending waves early: %d" % wave_bonus
	var lifepenalty = "Penalty from lives lost: -%d" % life_penalty
	var total = "Total score: %d" % score
	score_label.text = killscore + "\n" + wavebonus + "\n" + lifepenalty + "\n" + total

func on_button_pressed():
	emit_signal("play_again")

func _ready():
	button.connect("pressed", self, "on_button_pressed")