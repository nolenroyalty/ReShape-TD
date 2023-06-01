extends Node2D

var ReshapeUpgradePicker = preload("res://ui/ReshapeUpgradePicker.tscn")

onready var battlefield = $Battlefield
onready var upgrade_selector = $ReshapeUpgradeSelector

var individual_selection = null

func hide_reshape_upgrade_picker(picker):
	picker.queue_free()
	battlefield.set_playing()

func show_reshape_upgrade_picker(shape):
	var picker = ReshapeUpgradePicker.instance()
	picker.init(shape)
	battlefield.set_in_menu()
	add_child(picker)
	picker.connect("upgrade_purchased", self, "hide_reshape_upgrade_picker", [picker])

func clear_individual_selection():
	if individual_selection != null:
		if individual_selection.is_in_group("tower"):
			individual_selection.hide_range()
		
		if individual_selection.is_in_group("creep"):
			# Do something
			pass
	
		individual_selection = null

func show_individual_tower(tower):
	clear_individual_selection()
	individual_selection = tower
	tower.display_range()

# Called when the node enters the scene tree for the first time.
func _ready():
	upgrade_selector.connect("reshape", self, "show_reshape_upgrade_picker")
	battlefield.connect("selected_tower", self, "show_individual_tower")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
