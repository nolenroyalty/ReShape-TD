extends Node

const LIFE_PENALTY_AMOUNT = 20

signal game_over
signal gold_updated(amount)
signal lives_updated(amount)
signal score_updated(amount)

var gold : int
var lives : int
var debug = true
var score : int
var life_penalty : int

func reset():
	gold = 150
	emit_signal("gold_updated", gold)
	lives = 20
	emit_signal("lives_updated", lives)
	score = 0
	emit_signal("score_updated", score)
	life_penalty = 0

func add_gold(amount):
	gold += int(amount)
	emit_signal("gold_updated", gold)

func can_buy(amount):
	return gold >= amount

func try_to_buy(amount):
	if can_buy(amount):
		gold -= int(amount)
		emit_signal("gold_updated", gold)
		return true
	return false

func add_score(amount):
	score += int(amount)
	emit_signal("score_updated", score)

func lose_life():
	life_penalty += LIFE_PENALTY_AMOUNT
	lives -= 1
	add_score(-LIFE_PENALTY_AMOUNT)
	if lives <= 0:
		emit_signal("game_over")
	else:
		emit_signal("lives_updated", lives)

func _ready():
	reset()
