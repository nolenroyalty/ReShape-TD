extends CanvasLayer
signal resumed()

onready var button = $NinePatchRect/Button

func resumed():
	emit_signal("resumed")

func _ready():
	button.connect("pressed", self, "resumed")