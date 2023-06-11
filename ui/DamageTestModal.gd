extends CanvasLayer

signal play_again()

onready var title = $NinePatchRect/Title
onready var damage_done = $NinePatchRect/DamageDone
onready var play_again = $NinePatchRect/PlayAgain

func init(damage, killed):
	if killed:
		title.text = "You Killed the Damage Test????"
	else:
		title.text = "Damage Test Complete!"
	
	damage_done.text = "Damage Dealt: %d" % int(damage)
	
func on_play_again_pressed():
	emit_signal("play_again")

func _ready():
	play_again.connect("pressed", self, "on_play_again_pressed")
