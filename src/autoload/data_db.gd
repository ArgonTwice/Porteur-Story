## Autoload DataDB : données de jeu chargées une fois au démarrage (lecture seule).
extends Node

const Catalog := preload("res://src/sim/lifethread_catalog.gd")

var lifethreads := Catalog.new()


func _ready() -> void:
	if not lifethreads.load_dir("res://data/lifethreads"):
		push_error("DataDB fils de vie :\n" + "\n".join(lifethreads.errors))
