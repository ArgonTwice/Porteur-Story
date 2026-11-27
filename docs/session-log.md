# Journal des sessions Porter Story

À recopier dans docs/session-log.md du dépôt (pas de commit automatique).

## Sessions

```json
{"date":"2026-11-27","jalon":"M0 validé sur Z Fold 8","fait":["APK installé et lancé via adb, logcat sans erreur","Interface en dp réels, plié 1248x1972 et déplié 2448x1848 validés sans redémarrage","Reprise de partie vérifiée (jour et vitesse restaurés après arrêt forcé)","Claude Code + MCP Godot sur le PC (.mcp.json)"],"reste":["Icône du projet","Durée de la demi-journée à régler en M1 (30 s [P])"],"decisions":["Tailles UI en dp (boutons 56, texte 22, bloc 300) [P]","GODOT_PATH par variable avec défaut local"],"prochain":"PR M0 vers main, puis M1"}
```

```json
{"date":"2026-11-27","jalon":"M0 Fondations","fait":["Autoloads Clock, DataDB, I18n, SaveGame (project.godot), scène main = horloge + boutons pause/vitesse","src/sim/game_clock.gd : demi-journées matin/soir, pause, vitesses x1/x2/x4, plusieurs ticks par frame, to_dict/from_dict","src/core/save_store.gd : JSON atomique (.tmp puis rename) ; SaveGame sauve à chaque nouveau jour, mise en arrière-plan Android et fermeture","i18n JSON fr/en chargé au runtime (sans import), locale système sinon fr","tests/run_all.gd : runner unique, base test_base.gd, 121/121 OK sous Godot 4.7.2 [V]","export_presets.cfg Android arm64, APK debug 28 Mo construit et signé (apksigner verify OK) [V]"],"reste":["Installer l APK sur le Z Fold 8 et vérifier démarrage, plié/déplié, reprise après arrière-plan","Commit de la branche m0-fondations (en attente d accord)","Brancher wait_days / deadline_days des fils sur l horloge"],"decisions":["Demi-journée = 30 s réelles à x1 [P]","Vitesses x1/x2/x4, pause séparée de la vitesse","i18n en JSON plutôt que CSV pour tester sans import","Viewport 1080x1080, stretch canvas_items + expand, orientation capteur pour plié/déplié [P]","Package com.argontwice.porterstory, nom affiché Porter Story [P]","Clé debug générée localement, hors dépôt"],"prochain":"Test APK sur le Fold, commit M0, puis M1"}
```

## Archive

2026-11-27: Fils de vie — catalogue (ids, requires_threads, fils ouvrables) et fil tutoriel de Gus, 32 + 56 vérifications OK.
2026-11-27: Fils de vie — chargeur JSON validé et progression des colis (choix, échec non bloquant), 56 vérifications OK.
2026-11-27: Positionnement — vision Dungeon Village 2 × Death Stranding, maquettes V1-V4, Bible §14 et schéma des Fils de vie validés.
