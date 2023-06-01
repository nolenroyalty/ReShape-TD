extends Node2D

signal upgrade_tower(tower)
signal sell_tower(tower)

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
	current.connect("upgrade_tower", self, "pass_upgrade_tower")
	current.connect("sell_tower", self, "pass_sell_tower")
	add_child(current)

func pass_upgrade_tower(tower):
	emit_signal("upgrade_tower", tower)

func pass_sell_tower(tower):
	emit_signal("sell_tower", tower)

func _ready():
	$WhatThisIsLabel.hide()