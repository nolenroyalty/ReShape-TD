extends Control
onready var label = $ClearPatch/Label
onready var background = $ClearPatch/Background

func set_color(kind):
	match kind:
		C.CREEP_KIND.NORMAL: background.modulate = Color("#86553b")
		C.CREEP_KIND.QUICK: background.modulate = Color("#8e3a47")
		C.CREEP_KIND.THICK: background.modulate = Color("#3f6050")
		C.CREEP_KIND.RESISTANT: background.modulate = Color("#ac82b2")

func set_text(kind, number, is_boss):
	var prefix = "%d. " % number
	if is_boss: 
		label.text = prefix + "Boss"
	else:
		match kind:
			C.CREEP_KIND.NORMAL: label.text = prefix + "Normal"
			C.CREEP_KIND.QUICK: label.text = prefix + "Quick"
			C.CREEP_KIND.THICK: label.text = prefix + "Thick"
			C.CREEP_KIND.RESISTANT: label.text = prefix + "Resistant"

func init(kind, number, is_boss):
	set_color(kind)
	set_text(kind, number, is_boss)

# func _ready():
# 	init(3, C.CREEP_KIND.QUICK, false)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
