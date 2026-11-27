## Base des tests : le runner appelle chaque méthode test_* dans l'ordre de déclaration.
extends RefCounted

var fails := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		printerr("ÉCHEC : " + what)


func run() -> void:
	for m in get_method_list():
		if m.name.begins_with("test_"):
			call(m.name)
