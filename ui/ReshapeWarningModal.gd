extends CanvasLayer

signal dismissed

func button_pressed():
	emit_signal("dismissed")

func _ready():
	var _ignore = $NinePatchRect/Button.connect("pressed", self, "button_pressed")