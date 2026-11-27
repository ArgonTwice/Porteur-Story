## Autoload I18n : charge les traductions, locale du système si traduite, sinon fr.
extends Node

const Loader := preload("res://src/core/i18n_loader.gd")
const FALLBACK := "fr"


func _ready() -> void:
	var locales := Loader.load_dir("res://i18n")
	var sys := OS.get_locale_language()
	TranslationServer.set_locale(sys if sys in locales else FALLBACK)
