extends Node2D

signal creep_freed

# onready var label = $Label
onready var title = $Title
onready var health = $GridContainer/Health
onready var speed = $GridContainer/Speed
onready var level = $GridContainer/Level

onready var resist_title = $GridContainer/ResistTitle
onready var resist_text = $GridContainer/Resist
onready var status_title = $GridContainer/StatusTitle
onready var status_text = $GridContainer/StatusChance

onready var chilled = $GridContainer/Statuses/Chilled
onready var poisoned = $GridContainer/Statuses/Poisoned
onready var stunned = $GridContainer/Statuses/Stunned


var creep = null

func init(creep_):
	creep = creep_

func set_text_for_creep():
	var suffix = " (Boss)" if creep.is_boss else ""
	title.text = "%s Creep%s" % [creep.KIND, suffix]
	level.text = "%s" % int(creep.level)
	health.text = "%s" % int(creep.health)
	speed.text = "%s" % int(creep.determine_speed())

	var resist_chance = creep.RESIST_CHANCE
	var status_reduction = creep.STATUS_REDUCTION

	$Sprite.texture = creep.get_texture()

	if resist_chance == 0.0:
		resist_title.hide()
		resist_text.hide()
	else:
		resist_title.show()
		resist_text.show()
		resist_text.text = "%s%%" % int(resist_chance * 100)

	if status_reduction == 1.0:
		status_title.hide()
		status_text.hide()
	else:
		status_title.show()
		status_text.show()
		status_text.text = "%s%%" % int((1 - status_reduction) * 100)

	if creep.chilled: chilled.show()
	else: chilled.hide()

	if creep.poisoned: poisoned.show()
	else: poisoned.hide()
	
	if creep.stunned: stunned.show()
	else: stunned.hide()

func creep_freed():
	emit_signal("creep_freed")

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(creep != null, "creep must be set before adding to scene!")
	set_text_for_creep()
	creep.connect("state_changed", self, "set_text_for_creep")
	creep.connect("freed_for_whatever_reason", self, "creep_freed")
