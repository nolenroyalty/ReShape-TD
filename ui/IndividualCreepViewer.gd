extends Node2D

signal creep_freed

onready var label = $Label
var creep = null

func init(creep_):
	creep = creep_

func set_text_for_creep():
	var kind = "Kind: %s" % creep.KIND
	var level = "Level: %s" % creep.level
	var health = "Health: %s" % int(creep.health)
	var speed = "Speed: %s" % int(creep.SPEED)
	var status_effects = "\n".join(creep.get_status_effects())
	var t = "\n".join([kind, level, health, speed, status_effects])
	label.text = t

func creep_freed():
	emit_signal("creep_freed")

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(creep != null, "creep must be set before adding to scene!")
	set_text_for_creep()
	creep.connect("state_changed", self, "set_text_for_creep")
	creep.connect("freed_for_whatever_reason", self, "creep_freed")
