extends Node2D

# Stops us from playing an overwhelming number of sound effects
const explosion_frequency = 0.275
const shoot_frequency = 0.1
const lose_life_frequency = 0.2
const wave_release_frequency = 0.15

onready var explosion_timer = $ExplosionTimer
onready var shoot_timer = $ShootTimer
onready var lose_life_timer = $LoseLifeTimer
onready var wave_release_timer = $WaveReleaseTimer

func _request_play(timer, threshold):
	if timer.is_stopped():
		timer.start(threshold)
		return true
	else:
		return false

func request_play_explosion():
	return _request_play(explosion_timer, explosion_frequency)

func request_play_shoot():
	return _request_play(shoot_timer, shoot_frequency)

func request_play_lose_life():
	return _request_play(lose_life_timer, lose_life_frequency)

func request_play_wave_release():
	return _request_play(wave_release_timer, wave_release_frequency)