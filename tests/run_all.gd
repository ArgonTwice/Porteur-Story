## Lance tous les tests : godot --headless --path . -s tests/run_all.gd   (code retour 1 si échec)
extends SceneTree

const DIR := "res://tests"


func _init() -> void:
	var fails := 0
	var checks := 0
	for f in DirAccess.get_files_at(DIR):
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_base.gd":
			continue
		var t: RefCounted = load(DIR.path_join(f)).new()
		t.run()
		print("%-32s %3d vérifs, %d échec(s)" % [f, t.checks, t.fails])
		checks += t.checks
		fails += t.fails
	print("TOTAL %d vérifications, %d échec(s)" % [checks, fails])
	quit(1 if fails else 0)
