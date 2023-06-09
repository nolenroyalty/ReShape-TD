extends CanvasLayer
signal actually_reset
signal cancel_reset

onready var mistake = $NinePatchRect/Mistake
onready var real = $NinePatchRect/Real

func real_pressed():
	emit_signal("actually_reset")

func mistake_pressed():
	emit_signal("cancel_reset")

func _ready():
	mistake.connect("pressed", self, "mistake_pressed")
	real.connect("pressed", self, "real_pressed")