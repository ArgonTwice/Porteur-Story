extends "res://tests/test_base.gd"

const Loader := preload("res://src/core/i18n_loader.gd")
const DIR := "res://i18n"


func test_load() -> void:
	var locales := Loader.load_dir(DIR)
	check("fr" in locales and "en" in locales, "fr et en chargés : %s" % [locales])
	TranslationServer.set_locale("en")
	check(TranslationServer.translate("clock.morning") == "Morning", "traduction en")
	TranslationServer.set_locale("fr")
	check(TranslationServer.translate("clock.morning") == "Matin", "traduction fr")
	check(TranslationServer.translate("cle.inconnue") == "cle.inconnue", "clé absente -> clé")


func test_same_keys() -> void:
	var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join("fr.json")))
	for f in DirAccess.get_files_at(DIR):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join(f)))
		check(d.keys() == ref.keys(), "%s : mêmes clés que fr.json" % f)
