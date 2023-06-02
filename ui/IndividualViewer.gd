extends Node2D

var IndividualTowerViewer = preload("res://ui/IndividualTowerViewer.tscn")
var IndividualCreepViewer = preload("res://ui/IndividualCreepViewer.tscn")
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

func show_creep(creep):
	free_current()
	current = IndividualCreepViewer.instance()
	current.init(creep)
	add_child(current)
	current.connect("creep_freed", self, "handle_creep_freed", [current])

func handle_tower_sold(who):
	if who == current:
		free_current()

func handle_creep_freed(who):
	if who == current:
		free_current()

func _ready():
	$WhatThisIsLabel.hide()