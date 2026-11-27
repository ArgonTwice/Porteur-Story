## Charge res://i18n/<locale>.json ({"clé": "texte"}) dans le TranslationServer.
## JSON plutôt que CSV : pas d'étape d'import, donc testable en headless.
extends RefCounted


## Retourne les locales chargées.
static func load_dir(dir: String) -> PackedStringArray:
	var locales := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.get_extension() != "json":
			continue
		var msgs = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		if typeof(msgs) != TYPE_DICTIONARY:
			push_error("i18n : %s invalide" % f)
			continue
		var t := Translation.new()
		t.locale = f.get_basename()
		for k in msgs:
			t.add_message(k, msgs[k])
		TranslationServer.add_translation(t)
		locales.append(t.locale)
	return locales
