extends Node

signal game_over
signal gold_updated(amount)
signal lives_updated(amount)
signal score_updated(amount)

var gold = 200
var lives = 20
var debug = true
var score = 0

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
	lives -= 1
	add_score(-20)
	if lives <= 0:
		emit_signal("game_over")
	else:
		emit_signal("lives_updated", lives)