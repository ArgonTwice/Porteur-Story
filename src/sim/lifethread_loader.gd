## Charge et valide un Fil de vie (data/lifethreads/*.json).
## Sim pure : aucune dépendance au SceneTree.
## Valide les règles utiles à la sim (pas tout le JSON Schema) + règles Bible §14.
extends RefCounted

const STATION := "station"
const OPS := ["add", "set", "unlock"]
const MIN_STEPS := 3
const MAX_STEPS := 6

static var _id_re: RegEx


## Retourne { "ok": bool, "data": Dictionary, "errors": PackedStringArray }.
static func load_file(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return _result({}, ["lecture impossible : %s (%s)" % [path, error_string(FileAccess.get_open_error())]])
	return parse(text)


static func parse(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return _result({}, ["JSON ligne %d : %s" % [json.get_error_line(), json.get_error_message()]])
	if typeof(json.data) != TYPE_DICTIONARY:
		return _result({}, ["racine : objet attendu"])
	var errors := PackedStringArray()
	# Godot lit tous les nombres en float : le schéma n'a que des entiers.
	var data: Dictionary = _ints(json.data, "", errors)
	if errors.is_empty():
		_validate(data, errors)
	return _result(data, errors)


static func _result(data: Dictionary, errors: Array) -> Dictionary:
	return {"ok": errors.is_empty(), "data": data, "errors": PackedStringArray(errors)}


## Convertit récursivement les float entiers en int ; un float non entier est une erreur.
static func _ints(v: Variant, path: String, errors: PackedStringArray) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			if v != floorf(v):
				errors.append("%s : entier attendu, reçu %s" % [path, v])
				return v
			return int(v)
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = _ints(v[k], k if path.is_empty() else "%s.%s" % [path, k], errors)
			return d
		TYPE_ARRAY:
			var a := []
			for i in v.size():
				a.append(_ints(v[i], "%s[%d]" % [path, i], errors))
			return a
	return v


static func _validate(d: Dictionary, e: PackedStringArray) -> void:
	for k in ["id", "version", "title", "region", "unlock", "cast", "steps", "ending"]:
		if not d.has(k):
			e.append("champ manquant : %s" % k)
	if not e.is_empty():
		return
	_id(d.id, "id", e)
	_id(d.region, "region", e)
	_int_min(d.version, 1, "version", e)

	var u: Dictionary = d.unlock
	_id(u.get("node"), "unlock.node", e)
	var stars = u.get("min_stars")
	if typeof(stars) != TYPE_INT or stars < 1 or stars > 5:
		e.append("unlock.min_stars : entier 1-5 attendu")

	var cast_ids := {}
	for i in d.cast.size():
		var c: Dictionary = d.cast[i]
		_id(c.get("id"), "cast[%d].id" % i, e)
		_id(c.get("node"), "cast[%d].node" % i, e)
		if cast_ids.has(c.get("id")):
			e.append("cast[%d].id en double : %s" % [i, c.id])
		cast_ids[c.get("id")] = true
	if cast_ids.is_empty():
		e.append("cast : au moins 1 personnage")

	var steps: Array = d.steps
	if steps.size() < MIN_STEPS or steps.size() > MAX_STEPS:
		e.append("steps : %d à %d colis, reçu %d" % [MIN_STEPS, MAX_STEPS, steps.size()])
	var step_ids := {}
	var option_ids := {}
	var choices := 0
	for i in steps.size():
		var s: Dictionary = steps[i]
		var p := "steps[%d]" % i
		for k in ["id", "from", "to", "cargo", "deadline_days", "teaser", "note"]:
			if not s.has(k):
				e.append("%s : champ manquant %s" % [p, k])
		if step_ids.has(s.get("id")):
			e.append("%s.id en double : %s" % [p, s.id])
		step_ids[s.get("id")] = true
		for k in ["from", "to"]:
			var who = s.get(k)
			if who != STATION and not cast_ids.has(who):
				e.append("%s.%s : '%s' ni 'station' ni dans cast" % [p, k, who])
		var cargo: Dictionary = s.get("cargo", {})
		_id(cargo.get("item"), p + ".cargo.item", e)
		_int_min(cargo.get("kg"), 1, p + ".cargo.kg", e)
		_int_min(s.get("deadline_days"), 1, p + ".deadline_days", e)
		_effects(s.get("effects", []), p + ".effects", e)
		if s.has("choice"):
			choices += 1
			var opts: Array = s.choice.get("options", [])
			if opts.size() < 2 or opts.size() > 3:
				e.append("%s.choice : 2 à 3 options" % p)
			for j in opts.size():
				var oid = opts[j].get("id")
				_id(oid, "%s.choice.options[%d].id" % [p, j], e)
				if option_ids.has(oid):
					e.append("%s.choice : option en double %s" % [p, oid])
				option_ids[oid] = true
				_effects(opts[j].get("effects", []), "%s.choice.options[%d].effects" % [p, j], e)
		if s.has("on_fail"):
			_int_min(s.on_fail.get("delay_days"), 0, p + ".on_fail.delay_days", e)
			_effects(s.on_fail.get("effects", []), p + ".on_fail.effects", e)
	if choices > 1:
		e.append("Bible §14 : 1 choix max par fil, reçu %d" % choices)

	var end: Dictionary = d.ending
	if not end.has("default"):
		e.append("ending.default manquant")
		return
	_ending(end.default, "ending.default", cast_ids, e)
	for oid in end.get("by_choice", {}):
		if not option_ids.has(oid):
			e.append("ending.by_choice.%s : aucune option de ce nom" % oid)
		_ending(end.by_choice[oid], "ending.by_choice." + oid, cast_ids, e)


static func _ending(v: Dictionary, p: String, cast_ids: Dictionary, e: PackedStringArray) -> void:
	if v.has("resident") and not cast_ids.has(v.resident):
		e.append("%s.resident : '%s' absent du cast" % [p, v.resident])
	if v.has("facility"):
		_id(v.facility.get("id"), p + ".facility.id", e)
		_effects(v.facility.get("effects", []), p + ".facility.effects", e)
	_effects(v.get("effects", []), p + ".effects", e)


static func _effects(list: Array, p: String, e: PackedStringArray) -> void:
	for i in list.size():
		var fx: Dictionary = list[i]
		var op = fx.get("op")
		if not op in OPS:
			e.append("%s[%d].op : '%s' inconnu" % [p, i, op])
		if typeof(fx.get("key")) != TYPE_STRING or fx.key.is_empty():
			e.append("%s[%d].key : texte attendu" % [p, i])
		var t := typeof(fx.get("value"))
		if not t in [TYPE_INT, TYPE_BOOL, TYPE_STRING]:
			e.append("%s[%d].value : entier, booléen ou texte attendu" % [p, i])
		elif op == "add" and t != TYPE_INT:
			e.append("%s[%d] : 'add' exige un entier" % [p, i])


static func _id(v: Variant, p: String, e: PackedStringArray) -> void:
	if _id_re == null:
		_id_re = RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	if typeof(v) != TYPE_STRING or _id_re.search(v) == null:
		e.append("%s : id invalide '%s'" % [p, v])


static func _int_min(v: Variant, lo: int, p: String, e: PackedStringArray) -> void:
	if typeof(v) != TYPE_INT or v < lo:
		e.append("%s : entier >= %d attendu" % [p, lo])
