extends Node2D

signal final_wave_sent
signal wave_started(wave_number, kind, is_boss, creep_count)
signal timer_updated(amount)

const FULL_TIMER = 25
const CARD_SIZE = 80
const ORIGINAL_POSITION = 96

onready var wave_line = $WaveLine
onready var advance_tween = $AdvanceTween
onready var tick_tween := $TickTween
onready var wave_timer := $WaveTimer
var timer_amount = FULL_TIMER
var wave_number = 0
var waves = []
var bonus_from_wave_skipping = 0

func final_offset_for_this_wave():
	# Cards have 1 px of overlap
	return wave_number * (CARD_SIZE -1) * -1

func release_wave(number):
	var wave = waves[number]
	print("Wave %s started (kind: %s)" % [number, C.creep_name(wave[0])])
	State.wave__hack_for_tower_to_access_this = number

	var creep_count = null
	if len(wave) == 3: creep_count = wave[2]

	emit_signal("wave_started", number + 1, wave[0], wave[1], creep_count)
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
	if wave_number != 0 and wave_number < len(waves):
		var bonus = timer_amount * 3
		bonus_from_wave_skipping += bonus
		State.add_score(bonus)
	
	if advance_tween.is_active():
		advance_tween.stop_all()
	
	if tick_tween.is_active():
		tick_tween.stop_all()
	
	advance_tween.interpolate_property(wave_line, "position:x", null, final_offset_for_this_wave(), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	advance_tween.start()
	reset_timer()
	advance_wave()
	wave_timer.start(1)

func tween_one_tick(ensure_at_final=false):
	if advance_tween.is_active():
		return
	
	var amount_to_tick = float(CARD_SIZE - 1) / float(FULL_TIMER)
	if ensure_at_final:
		tick_tween.interpolate_property(wave_line, "position:x", null, final_offset_for_this_wave(), 1.0, Tween.TRANS_LINEAR)
	else:
		tick_tween.interpolate_property(wave_line, "position:x", null, wave_line.position.x - amount_to_tick, 1.0, Tween.TRANS_LINEAR)
	tick_tween.start()

func handle_tick():
	if timer_amount <= 0:
		reset_timer()
		tween_one_tick(true)
		advance_wave()
	else:
		timer_amount -= 1
		emit_signal("timer_updated", timer_amount)
		tween_one_tick()

func init(waves_):
	waves = waves_
	wave_line.init(waves)

func _process(_delta):
	if State.debug and Input.is_action_just_pressed("ui_accept"):
		start()
	if State.debug and Input.is_action_just_pressed("ui_right"):
		advance_immediately()

func start():
	advance_immediately()
	wave_timer.start(1)
	tween_one_tick()

func reset():
	wave_number = 0
	bonus_from_wave_skipping = 0
	wave_line.position.x = ORIGINAL_POSITION
	advance_tween.stop_all()
	tick_tween.stop_all()
	wave_timer.stop()
	timer_amount = FULL_TIMER
	wave_line.reset()
	init(all_waves)

var n = C.CREEP_KIND.NORMAL
var t = C.CREEP_KIND.THICK
var r = C.CREEP_KIND.RESISTANT
var q = C.CREEP_KIND.QUICK
var p = C.CREEP_KIND.PACK

# It's dumb that I put this in this file but whatever.

# var all_waves = [
# 	[ p, false],
# 	[ p, true],
# 	[ p, false]
# ]

var all_waves = [
	[ n, false],
	[ n, false],
	[ t, false],
	[ q, false],
	[ p, false],
	[ r, false],
	[ n, true], # 7, we've seen all the types and a boss

	[ q, false],
	[ t, false],
	[ r, false],
	[ p , false],
	[ n, false ],
	[ q, true], # 13 / 6, all the types and two bosses

	[ t, false],
	[ n, false],
	[ p, false, 15],
	[ q, false],
	[ r, true], # 18 / 5, all the types and three bosses

	[ n, false],
	[ r, false],
	[ q, false],
	[ t, false],
	[ p, true], # 23 / 5, first group of multiple bosses

	[ n, true, 2], # 24 / first multiple boss in a row
	[ t, true, 3], # 25

	[ q, false],
	[ r, false],
	[ p, false],
	[ n, false],
	[ t, false],
	[ p, false, 18], # 31 / 5, first huge group of creeps

	[ t, false, 12],
	[ q, false, 12],
	[ r, false, 12],
	[ n, false, 15],
	[ p, false, 20], # 36 / 5, huge groups of creeps and money infusion

	[ q, true, 3],
	[ r, true, 3],
	[ n, true, 5],
	[ p, true, 6],
	[ t, true, 5],
	[ n, false, 20] # 42 / 6, all the bosses in a row and then some normal creeps
]

# Called when the node enters the scene tree for the first time.
func _ready():
	init(all_waves)
	var _ignore = wave_timer.connect("timeout", self, "handle_tick")
