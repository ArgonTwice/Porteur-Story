## Catalogue des Fils de vie : charge un dossier, vérifie les liens entre fils,
## dit quels fils peuvent s'ouvrir. Sim pure.
## Clés monde lues : "link.<node>" (étoiles, int), "thread_done.<id>", "endless" (bool).
extends RefCounted

const Loader := preload("res://src/sim/lifethread_loader.gd")
const MAX_OPEN := 2 ## Bible §14 : 2 fils ouverts au maximum

var threads := {} ## id -> définition
var errors := PackedStringArray()


## Charge tous les *.json du dossier (hors *.schema.json). ok = aucune erreur.
func load_dir(dir: String) -> bool:
	var files := DirAccess.get_files_at(dir)
	if files.is_empty():
		errors.append("aucun fil dans %s" % dir)
	for f in files:
		if f.get_extension() != "json" or f.ends_with(".schema.json"):
			continue
		var r := Loader.load_file(dir.path_join(f))
		for e in r.errors:
			errors.append("%s : %s" % [f, e])
		if r.ok:
			add(r.data, f)
	check_links()
	return errors.is_empty()


## Ajoute une définition déjà validée par le chargeur.
func add(data: Dictionary, source := "") -> void:
	if threads.has(data.id):
		errors.append("%s : id en double %s" % [source, data.id])
		return
	threads[data.id] = data


## Fils ouvrables maintenant, triés par id. open_ids = fils déjà en cours.
func available(world: Dictionary, open_ids: Array) -> Array[String]:
	var out: Array[String] = []
	if open_ids.size() >= MAX_OPEN:
		return out
	for id in threads:
		if not id in open_ids and can_open(id, world):
			out.append(id)
	out.sort()
	return out


func can_open(id: String, world: Dictionary) -> bool:
	var u: Dictionary = threads[id].unlock
	if world.get("thread_done." + id, false):
		return false
	if u.get("endless_only", false) and not world.get("endless", false):
		return false
	if int(world.get("link." + u.node, 0)) < u.min_stars:
		return false
	for req in u.get("requires_threads", []):
		if not world.get("thread_done." + req, false):
			return false
	return true


## requires_threads : fils connus, pas de boucle.
func check_links() -> void:
	for id in threads:
		for req in threads[id].unlock.get("requires_threads", []):
			if not threads.has(req):
				errors.append("%s : requires_threads '%s' inconnu" % [id, req])
	var state := {} # 1 = en cours de visite, 2 = fini
	for id in threads:
		_visit(id, state, [])


func _visit(id: String, state: Dictionary, path: Array) -> void:
	if state.get(id) == 2 or not threads.has(id):
		return
	if state.get(id) == 1:
		errors.append("boucle requires_threads : %s" % " -> ".join(path + [id]))
		return
	state[id] = 1
	for req in threads[id].unlock.get("requires_threads", []):
		_visit(req, state, path + [id])
	state[id] = 2
