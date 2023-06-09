extends Node2D

signal reshape(shape)
signal selected(shape)
signal reset()
signal pause()
signal send_wave()
signal shape_cleared()

onready var individual_viewer = $Background/IndividualViewer
onready var tower_builder = $Background/ReshapeUpgradeSelector
onready var reset_button := $Background/ResetButton
onready var pause_button := $Background/PauseButton
onready var next_wave_button := $Background/NextWaveButton

func cant_afford():
	return tower_builder.cant_afford()

func maybe_clear_shape():
	if  tower_builder.cant_afford():
		tower_builder.clear_shape()

func show_tower(tower): 
	individual_viewer.show_tower(tower)
	maybe_clear_shape()

func show_creep(creep): 
	individual_viewer.show_creep(creep)
	maybe_clear_shape()

func set_shape(shape):
	tower_builder.set_shape(shape)

func prop_reshape(shape):
	emit_signal("reshape", shape)

func prop_selected(shape):
	emit_signal("selected", shape)

func update_for_sent_wave(number, final_wave_sent):
	if final_wave_sent:
		next_wave_button.text = "No more waves!"
		next_wave_button.disabled = true
	else:
		next_wave_button.text = "Send Creep Wave %d" % (number + 1)
		next_wave_button.disabled = false

func prop_reset():
	emit_signal("reset")

func prop_pause():
	emit_signal("pause")

func prop_send_wave():
	emit_signal("send_wave")

func prop_shape_cleared():
	emit_signal("shape_cleared")

func reset():
	set_shape(null)
	next_wave_button.text = "Start"
	next_wave_button.disabled = false
	individual_viewer.free_current()

func _ready():
	tower_builder.connect("reshape", self, "prop_reshape")
	tower_builder.connect("selected", self, "prop_selected")
	tower_builder.connect("shape_cleared", self, "prop_shape_cleared")
	var _ignore = reset_button.connect("pressed", self, "prop_reset")
	_ignore = pause_button.connect("pressed", self, "prop_pause")
	_ignore = next_wave_button.connect("pressed", self, "prop_send_wave")
