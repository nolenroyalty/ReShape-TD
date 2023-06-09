extends Node2D

var ReshapeUpgradeAll = preload("res://ui/ReshapeUpgradeAllChoices.tscn")
var ReshapeUpgradePicker = preload("res://ui/ReshapeUpgrade3Choice.tscn")
var PauseModal = preload("res://ui/PauseModal.tscn")
var ResetModal = preload("res://ui/ResetModal.tscn")
var EndModal = preload("res://ui/EndModal.tscn")

onready var battlefield = $Battlefield
# onready var upgrade_selector = $ReshapeUpgradeSelector
# onready var individual_viewer = $IndividualViewer
onready var sidebar = $FullSidebar
onready var wave_display = $WaveDisplay
onready var shade = $ShaderDisplay/Shader

enum S { RUNNING, IN_MENU, WON_GAME, LOST_GAME }

var individual_selection = null
var state = S.RUNNING
var final_wave_sent = false

func pause_for_modal():
	get_tree().paused = true
	shade.show()
	battlefield.set_in_menu()

func unpause_modal_gone():
	get_tree().paused = false
	shade.hide()
	battlefield.set_playing()

func hide_reshape_upgrade_picker(picker):
	picker.queue_free()
	unpause_modal_gone()
 
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
	pause_for_modal()

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

func handle_sidebar_cleared_shape():
	battlefield.set_shape(null)

func handle_tower_built():
	if Input.is_action_pressed("continue_building"):
		pass
	else:
		set_shape(null)

var started = false
func start_or_send_next_wave():
	if not started:
		wave_display.start()
		battlefield.set_playing()
		started = true
	else:
		wave_display.advance_immediately()

func handle_keypress__running(_delta):
	if Input.is_action_just_pressed("select_tower_1"):
		set_shape(C.SHAPE.CROSS)
	if Input.is_action_just_pressed("select_tower_2"):
		set_shape(C.SHAPE.CRESCENT)
	if Input.is_action_just_pressed("select_tower_3"):
		set_shape(C.SHAPE.DIAMOND)
	if Input.is_action_just_pressed("send_wave"):
		start_or_send_next_wave()
	if State.debug and Input.is_action_just_pressed("DEBUG_GIVE_GOLD"):
		State.add_gold(1000)

func _process(delta):
	match state:
		S.RUNNING: 
			handle_keypress__running(delta)
			if final_wave_sent and battlefield.no_more_creeps():
				state = S.WON_GAME
				won_game()
		S.IN_MENU: pass
	
func handle_wave_started(number, kind, is_boss):
	battlefield.spawn_wave(kind, number + 1, is_boss)
	number += 1
	$WaveAndScore/Wave.text = "Wave: %d" % [number]
	sidebar.update_for_sent_wave(number, final_wave_sent)
 
func handle_final_wave_sent():
	print("Final wave sent!")
	final_wave_sent = true
	sidebar.update_for_sent_wave(0, true)

func handle_timer_updated(_time):
	pass

func end_game(won):
	pause_for_modal()
	var modal = EndModal.instance()
	add_child(modal)
	modal.set_text(won, wave_display.bonus_from_wave_skipping)
	modal.connect("play_again", self, "actually_reset", [modal])

func won_game():
	end_game(true)

func lost_game():
	state = S.LOST_GAME
	end_game(false)
	
func resume_pressed(modal):
	modal.queue_free()
	unpause_modal_gone()

func pause_pressed():
	pause_for_modal()
	var modal = PauseModal.instance()
	add_child(modal)
	modal.connect("resumed", self, "resume_pressed", [modal])

func actually_reset(modal):
	battlefield.reset()
	sidebar.reset()
	wave_display.reset()
	Upgrades.reset()
	State.reset()
	started = false
	$WaveAndScore/Wave.text = "Wave: 1"
	final_wave_sent = false

	modal.queue_free()
	unpause_modal_gone()
	state = S.RUNNING

func cancel_reset(modal):
	modal.queue_free()
	unpause_modal_gone()

func reset_pressed():
	pause_for_modal()
	var modal = ResetModal.instance()
	add_child(modal)
	modal.connect("actually_reset", self, "actually_reset", [modal])
	modal.connect("cancel_reset", self, "cancel_reset", [modal])

# Called when the node enters the scene tree for the first time.
func _ready():
	# set_shape(C.SHAPE.CROSS)
	sidebar.connect("reshape", self, "show_reshape_upgrade_picker")
	sidebar.connect("selected", self, "set_shape")
	sidebar.connect("send_wave", self, "start_or_send_next_wave")
	sidebar.connect("shape_cleared", self, "handle_sidebar_cleared_shape")
	sidebar.connect("pause", self, "pause_pressed")
	sidebar.connect("reset", self, "reset_pressed")

	battlefield.connect("selected_tower", self, "show_individual_tower")
	battlefield.connect("selected_creep", self, "show_individual_creep")
	battlefield.connect("tower_built", self, "handle_tower_built")

	wave_display.connect("wave_started", self, "handle_wave_started")
	wave_display.connect("final_wave_sent", self, "handle_final_wave_sent")
	wave_display.connect("timer_updated", self, "handle_timer_updated")

	var _ignore = State.connect("game_over", self, "lost_game")
	VisualServer.set_default_clear_color(C.BLACK)
