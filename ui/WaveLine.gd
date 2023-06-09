extends Node2D

var WaveCard = preload("res://ui/WaveCard.tscn")

onready var cards = $Cards

onready var one = $Cards/WaveCard
onready var two = $Cards/WaveCard2
onready var three = $Cards/WaveCard3

# Called when the node enters the scene tree for the first time.
func _ready():
	one.init(C.CREEP_KIND.QUICK, 1, false)
	two.init(C.CREEP_KIND.THICK, 2, true)
	three.init(C.CREEP_KIND.NORMAL, 3, false)
	for z in [one, two, three]:
		z.queue_free()

func reset():
	for card in cards.get_children():
		card.queue_free()

func init(waves):
	var wave_number = 1
	for wave in waves:
		var kind = wave[0]
		var is_boss = wave[1]
		var card = WaveCard.instance()
		cards.add_child(card)
		card.init(kind, wave_number, is_boss)
		wave_number += 1
		
