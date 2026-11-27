## Lecture / écriture JSON atomique : écrit dans <path>.tmp puis renomme sur <path>.
## Un crash pendant l'écriture laisse l'ancienne sauvegarde intacte.
extends RefCounted


static func write(path: String, data: Dictionary) -> Error:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	var ok := f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if not ok:
		return ERR_FILE_CANT_WRITE
	return DirAccess.rename_absolute(tmp, path)


## {ok, data, error} ; fichier absent = ok false, error "absent".
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": {}, "error": "absent"}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"ok": false, "data": {}, "error": "JSON invalide : %s" % json.get_error_message()}
	return {"ok": true, "data": json.data, "error": ""}
