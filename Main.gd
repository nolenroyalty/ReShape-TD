extends Node2D

var ReshapeUpgradeAll = preload("res://ui/ReshapeUpgradeAllChoices.tscn")
var ReshapeUpgradePicker = preload("res://ui/ReshapeUpgrade3Choice.tscn")

onready var battlefield = $Battlefield
# onready var upgrade_selector = $ReshapeUpgradeSelector
# onready var individual_viewer = $IndividualViewer
onready var sidebar = $FullSidebar
onready var wave_display = $WaveDisplay
onready var shade = $Shader

enum S { RUNNING, IN_MENU }

var individual_selection = null
var state = S.RUNNING

func hide_reshape_upgrade_picker(picker):
	picker.queue_free()
	get_tree().paused = false
	shade.hide()
	battlefield.set_playing()

func handle_upgrade_purchased(shape, upgrade, picker):
	var cost = Upgrades.reshape_cost(shape)
	if State.try_to_buy(cost):
		Upgrades.upgrade(shape, upgrade)
		print("Purchased upgrade %s for %s" % [Upgrades.title(upgrade), C.shape_name(shape)])
	else:
		print("POTENTIAL BUG: not enough gold to purchase upgrade!")
	hide_reshape_upgrade_picker(picker)
	# upgrade_selector.update_upgrades_text()

func show_reshape_upgrade_picker(shape):
	shade.show()
	get_tree().paused = true
	battlefield.set_in_menu()

	var picker = ReshapeUpgradePicker.instance()
	add_child(picker)
	picker.set_shape(shape)
	picker.connect("chosen", self, "handle_upgrade_purchased", [picker])
	picker.connect("cancelled", self, "hide_reshape_upgrade_picker", [picker])

func clear_individual_selection(only_if_this_one=null):
	if individual_selection != null and is_instance_valid(individual_selection):
		if only_if_this_one != null and only_if_this_one != individual_selection:
			return

		if individual_selection.is_in_group("tower"):
			individual_selection.hide_range()
			individual_selection.disconnect("sold", self, "clear_individual_selection")
		
		if individual_selection.is_in_group("creep"):
			individual_selection.disconnect("freed_for_whatever_reason", self, "clear_individual_selection")
			# Do something ?
			pass
	
		individual_selection = null

func show_individual_tower(tower):
	clear_individual_selection()
	individual_selection = tower
	sidebar.show_tower(tower)
	tower.connect("sold", self, "clear_individual_selection", [tower])
	tower.display_range()

func show_individual_creep(creep):
	clear_individual_selection()
	individual_selection = creep
	sidebar.show_creep(creep)
	creep.connect("freed_for_whatever_reason", self, "clear_individual_selection", [creep])

func set_shape(shape):
	sidebar.set_shape(shape)
	battlefield.set_shape(shape)

var started = false
func handle_keypress__running(_delta):
	if Input.is_action_just_pressed("select_tower_1"):
		set_shape(C.SHAPE.CROSS)
	if Input.is_action_just_pressed("select_tower_2"):
		set_shape(C.SHAPE.CRESCENT)
	if Input.is_action_just_pressed("select_tower_3"):
		set_shape(C.SHAPE.DIAMOND)
	if Input.is_action_just_pressed("send_wave"):
		if not started:
			wave_display.start()
			started = true
		else:
			wave_display.advance_immediately()
	if State.debug and Input.is_action_just_pressed("DEBUG_GIVE_GOLD"):
		State.add_gold(1000)

func _process(delta):
	match state:
		S.RUNNING: handle_keypress__running(delta)
		S.IN_MENU: pass
	
func handle_wave_started(number, kind, is_boss):
	var level = (number / 5) + 1
	battlefield.spawn_wave(kind, level, is_boss)
	$WaveAndScore/Wave.text = "Wave: %d" % [number + 1] 
 
func handle_final_wave_sent():
	assert(true == false, "TODO: handle final wave sent")

func handle_timer_updated(_time):
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	# set_shape(C.SHAPE.CROSS)
	sidebar.connect("reshape", self, "show_reshape_upgrade_picker")
	sidebar.connect("selected", self, "set_shape")
	battlefield.connect("selected_tower", self, "show_individual_tower")
	battlefield.connect("selected_creep", self, "show_individual_creep")
	wave_display.connect("wave_started", self, "handle_wave_started")
	wave_display.connect("final_wave_sent", self, "handle_final_wave_sent")
	wave_display.connect("timer_updated", self, "handle_timer_updated")

	VisualServer.set_default_clear_color(C.BLACK)
