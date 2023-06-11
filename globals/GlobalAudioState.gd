extends Node2D

# Stops us from playing an overwhelming number of sound effects
const explosion_frequency = 0.3
const shoot_frequency = 0.15

onready var explosion_timer = $ExplosionTimer
onready var shoot_timer = $ShootTimer

func _request_play(timer, threshold):
	if timer.is_stopped():
		timer.start(threshold)
		return true
	else:
		print("disallow")
		return false

func request_play_explosion():
	return _request_play(explosion_timer, explosion_frequency)

func request_play_shoot():
	return _request_play(shoot_timer, shoot_frequency)