extends "res://tests/test_base.gd"

const Loader := preload("res://src/sim/lifethread_loader.gd")
const Run := preload("res://src/sim/lifethread_run.gd")
const ODILE := "res://data/lifethreads/fil_odile.json"


func odile() -> Dictionary:
	var r := Loader.load_file(ODILE)
	check(r.ok, "fil_odile valide : %s" % ", ".join(r.errors))
	return r.data


func test_load_odile() -> void:
	var d := odile()
	check(d.steps.size() == 5, "5 colis")
	check(typeof(d.version) == TYPE_INT, "version en int")
	check(typeof(d.unlock.min_stars) == TYPE_INT, "min_stars en int")
	check(typeof(d.steps[0].cargo.kg) == TYPE_INT, "kg en int")
	check(typeof(d.steps[4].on_fail.delay_days) == TYPE_INT, "delay_days 0 en int")
	var fx: Dictionary = d.ending.default.facility.effects[0]
	check(typeof(fx.value) == TYPE_INT and fx.value == -15, "valeur négative en int")
	check(typeof(d.ending.default.effects[0].value) == TYPE_BOOL, "unlock reste booléen")


## Livre les 5 colis ; option au colis 3.
func play_all(option: String) -> Array:
	var run := Run.new(odile())
	var world := {}
	while not run.is_done():
		var s := run.current_step()
		check(run.deliver(world, option if s.has("choice") else ""), "livraison %s" % s.id)
	return [run, world]


func test_path_avec_mot() -> void:
	var r := play_all("avec_mot")
	var run: Run = r[0]
	var w: Dictionary = r[1]
	check(run.choice == "avec_mot", "choix mémorisé")
	check(w.get("likes") == 12 + 150, "likes avec_mot = 162, reçu %s" % w.get("likes"))
	check(w.get("trust.odile") == 1, "trust.odile +1")
	check(w.get("item.montre_odile_gravee") == true, "montre gravée débloquée")
	check(not w.has("item.montre_odile"), "by_choice remplace les effets de default")
	check(w.get("resident.odile") == true, "résident hérité de default")
	check(w.get("facility.horlogerie") == true, "atelier hérité de default")
	check(w.get("gear_wear_pct") == -15, "effet de l'atelier")
	check(w.get("thread_done.fil_odile") == true, "fil terminé")
	check(run.notes.size() == 6 and run.notes[-1].contains("Merci à la station"), "note de fin by_choice")


func test_path_sans_mot() -> void:
	var w: Dictionary = play_all("sans_mot")[1]
	check(w.get("likes") == 12 + 120, "likes sans_mot = 132")
	check(not w.has("trust.odile"), "pas de confiance sans mot")
	check(w.get("item.montre_odile") == true, "montre par défaut")


func test_failures_do_not_block() -> void:
	var run := Run.new(odile())
	var w := {}
	run.fail(w) # s1 perdu : pas de +12
	check(run.index == 1 and run.wait_days == 1, "après échec s1 : colis 2, délai 1 j")
	run.deliver(w)
	check(run.wait_days == 0, "livraison remet le délai à 0")
	run.fail(w) # s3 (le choix) perdu : pas de choix
	check(run.wait_days == 2 and run.choice == "", "échec du colis à choix : aucun choix, délai 2 j")
	run.deliver(w)
	run.fail(w) # s5 : délai 0, fil terminé quand même
	check(run.is_done(), "fil terminé malgré 3 échecs")
	check(w.get("likes") == 120, "fin par défaut seule : likes 120, reçu %s" % w.get("likes"))
	check(w.get("resident.odile") == true, "Odile s'installe quand même")
	check(run.notes.has("Encore une pendule arrêtée. Tant pis."), "note d'échec lue")
	run.fail(w)
	check(run.index == 5, "rien après la fin")


func test_bad_option_is_refused() -> void:
	var run := Run.new(odile())
	var w := {}
	run.deliver(w)
	run.deliver(w)
	check(not run.deliver(w, "inconnue"), "option inconnue refusée")
	check(run.index == 2, "colis à choix toujours en attente")


## Chaque cas casse une règle sur une copie d'Odile.
func test_loader_rejects() -> void:
	var base := FileAccess.get_file_as_string(ODILE)
	var cases := {
		"kg non entier": func(d): d.steps[0].cargo.kg = 2.5,
		"destinataire hors cast": func(d): d.steps[1].to = "inconnu",
		"2 choix": func(d): d.steps[0].choice = d.steps[2].choice.duplicate(true),
		"by_choice orphelin": func(d): d.ending.by_choice["xx"] = {},
		"2 colis": func(d): d.steps.resize(2),
		"op inconnue": func(d): d.steps[0].effects[0].op = "mul",
		"add texte": func(d): d.steps[0].effects[0].value = "12",
		"résident hors cast": func(d): d.ending.default.resident = "zoe",
		"id invalide": func(d): d.id = "Fil-Odile",
		"champ manquant": func(d): d.erase("ending"),
	}
	for name in cases:
		var d: Dictionary = JSON.parse_string(base)
		cases[name].call(d)
		var r := Loader.parse(JSON.stringify(d))
		check(not r.ok, "rejet attendu : " + name)
	check(not Loader.parse("{ pas du json").ok, "JSON cassé rejeté")
