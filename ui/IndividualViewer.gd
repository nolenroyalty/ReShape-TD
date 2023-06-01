extends Node2D

var IndividualTowerViewer = preload("res://ui/IndividualTowerViewer.tscn")
var current = null

func free_current():
	if current != null:
		current.queue_free()
		current = null

func show_tower(tower):
	free_current()
	current = IndividualTowerViewer.instance()
	current.init(tower)
	add_child(current)
	current.connect("tower_sold", self, "handle_tower_sold", [current])

func handle_tower_sold(who):
	if who == current:
		free_current()

func _ready():
	$WhatThisIsLabel.hide()