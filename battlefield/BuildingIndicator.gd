extends Node2D

func hidden():
	$Sprite.visible = false

func can_build():
	$Sprite.visible = true
	$Sprite.modulate = C.DARK_GREEN

func cannot_build():
	$Sprite.visible = true
	$Sprite.modulate = C.C.RED

func _ready():
	hidden()