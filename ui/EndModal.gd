extends CanvasLayer

signal play_again()
signal send_damage_test()

onready var title = $NinePatchRect/Title
onready var score_details = $NinePatchRect/ScoreDetails
onready var score_full = $NinePatchRect/ScoreFull
onready var play_again = $NinePatchRect/GridContainer/PlayAgain
onready var damage_test = $NinePatchRect/GridContainer/DamageTest

func set_text(won_game, wave_bonus):
	if won_game:
		title.text = "You won!!"
	else:
		damage_test.hide()
		title.text = "You lost :("
	
	var score = State.score
	var life_penalty = State.life_penalty
	var killscore = "Kill score: %d" % (score - wave_bonus + life_penalty)
	var wavebonus = "Bonus from sending waves early: %d" % wave_bonus
	if life_penalty != 0: life_penalty = "-%d" % life_penalty
	var lifepenalty = "Penalty from lives lost: %s" % life_penalty
	score_details.text = killscore + "\n" + wavebonus + "\n" + lifepenalty
	score_full.text = "Final score: %d" % score

func on_play_again_pressed():
	emit_signal("play_again")

func on_damage_test_pressed():
	emit_signal("send_damage_test")

func _ready():
	play_again.connect("pressed", self, "on_play_again_pressed")
	damage_test.connect("pressed", self, "on_damage_test_pressed")
