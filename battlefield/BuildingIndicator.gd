extends Node2D

onready var bounds := $Bounds

var intersecting_areas = {}

var should_hide = true

func begin_hiding():
	should_hide = true
	$Sprite.visible = false

func begin_showing():
	should_hide = false
	visible()

func visible():
	$Sprite.visible = true
	if unblocked(): $Sprite.modulate = C.DARK_GREEN
	else: $Sprite.modulate = C.RED

func area_entered(area):
	intersecting_areas[area] = true

func area_exited(area):
	if not intersecting_areas.erase(area):
		print("area exited cursor but we weren't tracking it? %s parent %s" % [area, area.get_parent()])

func unblocked():
	return intersecting_areas.empty()

func _process(_delta):
	if should_hide == false:
		visible()

func _ready():
	var _ignore = bounds.connect("area_entered", self, "area_entered")
	_ignore = bounds.connect("area_exited", self, "area_exited")
	begin_hiding()
