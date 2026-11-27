extends "res://tests/test_base.gd"

const Store := preload("res://src/core/save_store.gd")
const PATH := "user://test_save.json"


func test_roundtrip() -> void:
	DirAccess.remove_absolute(PATH)
	check(Store.read(PATH).error == "absent", "absent avant écriture")
	check(Store.write(PATH, {"version": 1, "clock": {"half_day": 7}}) == OK, "écriture")
	var r := Store.read(PATH)
	check(r.ok and int(r.data.clock.half_day) == 7, "relecture")
	check(not FileAccess.file_exists(PATH + ".tmp"), "pas de .tmp laissé")


func test_overwrite() -> void:
	Store.write(PATH, {"n": 1})
	check(Store.write(PATH, {"n": 2}) == OK, "réécriture sur fichier existant")
	check(int(Store.read(PATH).data.n) == 2, "nouvelle valeur lue")


func test_corrupt() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{pas du json")
	f.close()
	var r := Store.read(PATH)
	check(not r.ok and r.error.begins_with("JSON invalide"), "fichier corrompu signalé")
	f = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("[1, 2]")
	f.close()
	check(not Store.read(PATH).ok, "racine non objet refusée")


func test_stale_tmp_ignored() -> void:
	# Crash simulé : un .tmp à moitié écrit ne doit pas gêner la sauvegarde suivante.
	Store.write(PATH, {"n": 1})
	var f := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	f.store_string("{tronq")
	f.close()
	check(int(Store.read(PATH).data.n) == 1, "l'ancienne sauvegarde reste lisible")
	check(Store.write(PATH, {"n": 3}) == OK and int(Store.read(PATH).data.n) == 3, "écriture après crash")
	DirAccess.remove_absolute(PATH)
