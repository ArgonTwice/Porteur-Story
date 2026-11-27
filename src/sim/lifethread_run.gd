## Progression d'un Fil de vie sur un état monde (Dictionary clé -> valeur).
## Sim pure. Livraison ou échec font toujours avancer : un échec ne bloque jamais (Bible §14).
extends RefCounted

var def: Dictionary
var index := 0 ## colis courant
var choice := "" ## option retenue ("" si aucune ou colis du choix raté)
var wait_days := 0 ## délai avant le colis suivant (on_fail.delay_days)
var notes: Array[String] = [] ## notes lues, dans l'ordre


func _init(thread_def: Dictionary) -> void:
	def = thread_def


func is_done() -> bool:
	return index >= def.steps.size()


func current_step() -> Dictionary:
	return {} if is_done() else def.steps[index]


## Colis livré. option_id obligatoire si le colis porte un choix.
func deliver(world: Dictionary, option_id := "") -> bool:
	var s := current_step()
	if s.is_empty():
		return false
	if s.has("choice"):
		var opt := _option(s.choice, option_id)
		if opt.is_empty():
			push_error("fil %s, colis %s : option '%s' inconnue" % [def.id, s.id, option_id])
			return false
		choice = option_id
		apply_effects(world, opt.get("effects", []))
	apply_effects(world, s.get("effects", []))
	notes.append(s.note)
	wait_days = 0
	_advance(world)
	return true


## Colis perdu ou en retard : note d'échec, effets d'échec, délai, puis suite du fil.
func fail(world: Dictionary) -> void:
	var s := current_step()
	if s.is_empty():
		return
	var f: Dictionary = s.get("on_fail", {})
	apply_effects(world, f.get("effects", []))
	if f.has("note"):
		notes.append(f.note)
	wait_days = f.get("delay_days", 0)
	_advance(world)


## Fin = default, champs remplacés par by_choice[choice] si présent.
func ending() -> Dictionary:
	var e: Dictionary = def.ending.default.duplicate()
	e.merge(def.ending.get("by_choice", {}).get(choice, {}), true)
	return e


func _advance(world: Dictionary) -> void:
	index += 1
	if not is_done():
		return
	var e := ending()
	if e.has("resident"):
		world["resident." + e.resident] = true
	if e.has("facility"):
		world["facility." + e.facility.id] = true
		apply_effects(world, e.facility.get("effects", []))
	apply_effects(world, e.get("effects", []))
	if e.has("note"):
		notes.append(e.note)
	world["thread_done." + def.id] = true


static func apply_effects(world: Dictionary, effects: Array) -> void:
	for fx in effects:
		match fx.op:
			"add":
				world[fx.key] = int(world.get(fx.key, 0)) + int(fx.value)
			"set", "unlock":
				world[fx.key] = fx.value


static func _option(c: Dictionary, id: String) -> Dictionary:
	for o in c.options:
		if o.id == id:
			return o
	return {}
