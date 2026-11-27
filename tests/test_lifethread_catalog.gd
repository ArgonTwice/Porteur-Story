## godot --headless --path . -s tests/test_lifethread_catalog.gd   (code retour 1 si échec)
extends SceneTree

const Catalog := preload("res://src/sim/lifethread_catalog.gd")
const Run := preload("res://src/sim/lifethread_run.gd")
const DIR := "res://data/lifethreads"

var _fails := 0
var _checks := 0


func _init() -> void:
	test_load_dir()
	test_available()
	test_gus_tutorial()
	test_cross_thread()
	test_link_errors()
	print("%d vérifications, %d échec(s)" % [_checks, _fails])
	quit(1 if _fails else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		printerr("ÉCHEC : " + what)


func catalog() -> Catalog:
	var c := Catalog.new()
	check(c.load_dir(DIR), "data/lifethreads valide : %s" % ", ".join(c.errors))
	return c


## Copie d'un fil réel avec un autre id et d'autres prérequis.
func variant(c: Catalog, id: String, requires: Array, endless := false) -> Dictionary:
	var d: Dictionary = c.threads.fil_odile.duplicate(true)
	d.id = id
	d.unlock.requires_threads = requires
	d.unlock.endless_only = endless
	return d


func test_load_dir() -> void:
	var c := catalog()
	check(c.threads.keys().size() == 2, "2 fils chargés (schéma ignoré), reçu %s" % [c.threads.keys()])
	check(c.threads.has("fil_gus") and c.threads.has("fil_odile"), "fil_gus et fil_odile présents")


func test_available() -> void:
	var c := catalog()
	var w := {}
	check(c.available(w, []).is_empty(), "rien sans liaison")
	w["link.relais_nord"] = 1
	check(c.available(w, []) == ["fil_gus"], "tutoriel ouvert dès 1★")
	w["link.abri_col"] = 1
	check(not c.can_open("fil_odile", w), "Odile fermé à 1★")
	w["link.abri_col"] = 2
	check(c.available(w, []) == ["fil_gus", "fil_odile"], "Odile ouvert à 2★, tri par id")
	check(c.available(w, ["fil_gus"]) == ["fil_odile"], "fil en cours exclu")
	check(c.available(w, ["fil_gus", "autre"]).is_empty(), "2 fils ouverts max")
	w["thread_done.fil_gus"] = true
	check(c.available(w, []) == ["fil_odile"], "fil terminé exclu")


func play(def: Dictionary, option: String, world: Dictionary) -> Run:
	var run := Run.new(def)
	while not run.is_done():
		run.deliver(world, option if run.current_step().has("choice") else "")
	return run


func test_gus_tutorial() -> void:
	var c := catalog()
	var w := {}
	var run := play(c.threads.fil_gus, "donner_lena", w)
	check(w.get("likes") == 5 + 50, "likes donner_lena = 55, reçu %s" % w.get("likes"))
	check(w.get("trust.lena") == 1 and w.get("item.bottes_gus") == true, "bottes données à Léna")
	check(w.get("resident.gus") == true and w.get("facility.cordonnerie") == true, "Gus s'installe, Cordonnerie")
	check(w.get("boots_wear_pct") == -10, "effet Cordonnerie")
	check(run.notes[-1].contains("Léna"), "note de fin by_choice")

	w = {}
	play(c.threads.fil_gus, "atelier", w)
	check(w.get("likes") == 45 and w.get("materials") == 5, "branche atelier : likes 45, matériaux +5")

	w = {}
	run = Run.new(c.threads.fil_gus)
	var delays := []
	while not run.is_done():
		run.fail(w)
		delays.append(run.wait_days)
	check(delays == [1, 1, 0], "délais d'échec 1, 1, 0 j, reçu %s" % [delays])
	check(w.get("likes") == 40 and w.get("resident.gus") == true, "3 échecs : fin par défaut")


func test_cross_thread() -> void:
	var c := catalog()
	c.add(variant(c, "fil_croise", ["fil_odile", "fil_gus"], true))
	c.check_links()
	check(c.errors.is_empty(), "fil croisé valide : %s" % ", ".join(c.errors))
	var w := {"link.abri_col": 5, "endless": true}
	check(not c.can_open("fil_croise", w), "fermé sans les fils requis")
	w["thread_done.fil_odile"] = true
	check(not c.can_open("fil_croise", w), "fermé avec 1 fil requis sur 2")
	w["thread_done.fil_gus"] = true
	check(c.can_open("fil_croise", w), "ouvert avec les 2 fils requis")
	w["endless"] = false
	check(not c.can_open("fil_croise", w), "endless_only fermé hors mode sans fin")


func test_link_errors() -> void:
	var c := catalog()
	c.add(variant(c, "fil_orphelin", ["fil_absent"]))
	c.check_links()
	check(c.errors.size() == 1 and c.errors[0].contains("fil_absent"), "prérequis inconnu : %s" % ", ".join(c.errors))

	c = catalog()
	c.add(variant(c, "fil_a", ["fil_b"]))
	c.add(variant(c, "fil_b", ["fil_a"]))
	c.check_links()
	check(c.errors.size() == 1 and c.errors[0].contains("boucle"), "boucle détectée une fois : %s" % ", ".join(c.errors))

	c = catalog()
	c.add(c.threads.fil_gus)
	check(c.errors.size() == 1 and c.errors[0].contains("double"), "id en double refusé")
