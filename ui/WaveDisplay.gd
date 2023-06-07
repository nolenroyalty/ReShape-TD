extends Node2D

signal final_wave_sent
signal wave_started(kind, is_boss)
signal timer_updated(amount)

const FULL_TIMER = 25
const CARD_SIZE = 80

onready var wave_line = $WaveLine
onready var advance_tween = $AdvanceTween
onready var tick_tween := $TickTween
onready var wave_timer := $WaveTimer
var timer_amount = FULL_TIMER
var wave_number = 0
var waves = []

func final_offset_for_this_wave():
	# Cards have 1 px of overlap
	return wave_number * (CARD_SIZE -1) * -1

func release_wave(number):
	var wave = waves[number]
	print("Wave %s started (kind: %s)" % [number, C.creep_name(wave[0])])

	emit_signal("wave_started", wave[0], wave[1])
	if wave_number + 1 >= len(waves):
		emit_signal("final_wave_sent")

func advance_wave():
	if wave_number >= len(waves):
		return
	release_wave(wave_number)
	wave_number += 1

func reset_timer():
	timer_amount = FULL_TIMER
	emit_signal("timer_updated", timer_amount)

func advance_immediately():
	if advance_tween.is_active():
		advance_tween.stop_all()
	
	if tick_tween.is_active():
		tick_tween.stop_all()
	
	advance_tween.interpolate_property(wave_line, "position:x", null, final_offset_for_this_wave(), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	advance_tween.start()
	reset_timer()
	advance_wave()

func tween_one_tick():
	if advance_tween.is_active():
		return
	
	var amount_to_tick = float(CARD_SIZE) / float(FULL_TIMER)
	tick_tween.interpolate_property(wave_line, "position:x", null, wave_line.position.x - amount_to_tick, 1.0, Tween.TRANS_LINEAR)
	tick_tween.start()

func handle_tick():
	if timer_amount <= 0:
		reset_timer()
		tween_one_tick()
		advance_wave()
	else:
		timer_amount -= 1
		emit_signal("timer_updated", timer_amount)
		tween_one_tick()

func init(waves_):
	waves = waves_
	wave_line.init(waves)

func start():
	advance_immediately()
	wave_timer.start(1)

func _process(_delta):
	if Input.is_action_just_pressed("DEBUG_START"):
		start()
	if Input.is_action_just_pressed("DEBUG_ADVANCE"):
		advance_immediately()

# Called when the node enters the scene tree for the first time.
func _ready():
	var w = [ [ C.CREEP_KIND.NORMAL, false], [ C.CREEP_KIND.THICK, true], [C.CREEP_KIND.RESISTANT, false], [C.CREEP_KIND.QUICK, false]]
	init(w)
	var _ignore = wave_timer.connect("timeout", self, "handle_tick")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
