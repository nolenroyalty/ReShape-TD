extends Node2D

var ReshapeUpgradePicker = preload("res://ui/ReshapeUpgradePicker.tscn")

onready var battlefield = $Battlefield
onready var upgrade_selector = $ReshapeUpgradeSelector
onready var individual_viewer = $IndividualViewer

enum S { RUNNING, IN_MENU }

var individual_selection = null
var state = S.RUNNING

func hide_reshape_upgrade_picker(picker):
	picker.queue_free()
	battlefield.set_playing()
	get_tree().paused = false

func show_reshape_upgrade_picker(shape):
	get_tree().paused = true
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
	individual_viewer.show_tower(tower)
	tower.display_range()

func set_shape(shape):
	upgrade_selector.set_shape(shape)
	battlefield.set_shape(shape)

func handle_keypress__running(_delta):
	if Input.is_action_just_pressed("select_tower_1"):
		set_shape(C.SHAPE.CROSS)
	if Input.is_action_just_pressed("select_tower_2"):
		set_shape(C.SHAPE.CRESCENT)
	if Input.is_action_just_pressed("select_tower_3"):
		set_shape(C.SHAPE.DIAMOND)

func _process(delta):
	match state:
		S.RUNNING: handle_keypress__running(delta)
		S.IN_MENU: pass

# Called when the node enters the scene tree for the first time.
func _ready():
	set_shape(C.SHAPE.CROSS)
	upgrade_selector.connect("reshape", self, "show_reshape_upgrade_picker")
	upgrade_selector.connect("selected", self, "set_shape")
	battlefield.connect("selected_tower", self, "show_individual_tower")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
