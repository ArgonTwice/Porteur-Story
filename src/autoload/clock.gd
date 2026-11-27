## Autoload Clock : fait tourner l'horloge de la sim avec le temps réel.
extends Node

const GameClock := preload("res://src/sim/game_clock.gd")

var sim := GameClock.new()


func _process(delta: float) -> void:
	sim.advance(delta)
