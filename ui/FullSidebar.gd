extends Node2D

signal reshape(shape)
signal selected(shape)
signal reset()
signal pause()

onready var individual_viewer = $Background/IndividualViewer
onready var tower_builder = $Background/ReshapeUpgradeSelector
onready var reset_button := $Background/ResetButton
onready var pause_button := $Background/PauseButton

func show_tower(tower): 
	individual_viewer.show_tower(tower)

func show_creep(creep): 
	individual_viewer.show_creep(creep)

func set_shape(shape):
	tower_builder.set_shape(shape)

func prop_reshape(shape):
	emit_signal("reshape", shape)

func prop_selected(shape):
	emit_signal("selected", shape)

func prop_reset():
	emit_signal("reset")

func prop_pause():
	emit_signal("pause")

func _ready():
	tower_builder.connect("reshape", self, "prop_reshape")
	tower_builder.connect("selected", self, "prop_selected")
	var _ignore = reset_button.connect("pressed", self, "prop_reset")
	_ignore = pause_button.connect("pressed", self, "prop_pause")
