extends Node2D

signal reshape(shape)
signal selected(shape)
signal reset()
signal pause()
signal send_wave()

onready var individual_viewer = $Background/IndividualViewer
onready var tower_builder = $Background/ReshapeUpgradeSelector
onready var reset_button := $Background/ResetButton
onready var pause_button := $Background/PauseButton
onready var next_wave_button := $Background/NextWaveButton

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

func update_for_sent_wave(number):
	next_wave_button.text = "Send Creep Wave %d" % (number + 1)

func prop_reset():
	emit_signal("reset")

func prop_pause():
	emit_signal("pause")

func prop_send_wave():
	emit_signal("send_wave")

func _ready():
	tower_builder.connect("reshape", self, "prop_reshape")
	tower_builder.connect("selected", self, "prop_selected")
	var _ignore = reset_button.connect("pressed", self, "prop_reset")
	_ignore = pause_button.connect("pressed", self, "prop_pause")
	_ignore = next_wave_button.connect("pressed", self, "prop_send_wave")
