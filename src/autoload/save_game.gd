## Autoload SaveGame : un emplacement, chargé au démarrage, sauvé à chaque nouveau jour
## et quand Android met l'app en arrière-plan ou la ferme.
extends Node

const Store := preload("res://src/core/save_store.gd")
const VERSION := 1

var path := "user://save_0.json"


func _ready() -> void:
	load_game()
	Clock.sim.ticked.connect(_on_tick)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		save_game()


func _on_tick(half_day: int) -> void:
	if half_day % 2 == 0: # nouveau jour
		save_game()


func save_game() -> void:
	var err := Store.write(path, {"version": VERSION, "clock": Clock.sim.to_dict()})
	if err != OK:
		push_error("Sauvegarde impossible : %s" % error_string(err))


func load_game() -> void:
	var r := Store.read(path)
	if r.ok:
		Clock.sim.from_dict(r.data.get("clock", {}))
	elif r.error != "absent":
		push_error("Sauvegarde illisible : " + r.error)
