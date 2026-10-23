# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-23","outil":"Claude Code","statut":"termine","objectif":"Jalon 8 : village de Clair-Foyer affiche, tuiles Kenney et Grand Atre","fait":["village.gd, village_layout.gd, npc.gd, cendre_grise.gdshader, village.json, village.tscn, npc.tscn ; debug_grid.gd retire","Ecarts 1 a 5 valides : torche Dungeon 29, dallage sur Chemins, tri -8 de la pousse, champignons retires, toits rouge et gris","build/* + !build/.gdignore dans .gitignore, build/.gdignore (import et export), preset inchange","Palette Cendre Grise finale (mockup v2b) en commentaire du shader","Sautillement des PNJ : BOB_PX 1, BOB_PERIOD_SEC 0,3, bob_offset(t, moving) ; sonde PC 32 images en marche dont 16 en haut, 0 au repos","run_all.gd : 370 tests PASS","APK 0.8.0 code 3 installe, V1 a V5 OK a l oeil (Antho)","Commit et push du jalon 8"],"reste_a_faire":["reste : logcat, screencap, 48 px et V3 bis au prochain branchement","Icone du projet (ERROR a l export), defaut 6"],"fichiers_modifies":[".gitignore","build/.gdignore",".gitattributes","ASSETS.md","CLAUDE.md","CHANGELOG.md","export_presets.cfg","scenes/main.tscn","scenes/ui/credits.tscn","scenes/village/","scripts/main.gd","scripts/village/","scripts/ui/debug_grid.gd (supprime)","data/village/village.json","assets/tiles/","tests/headless/run_all.gd","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Au prochain branchement : re-export APK 0.8.0 avec sautillement, V3 bis, logcat, screencap, mesure 48 px"}
```

```json
{"date":"2026-10-23","outil":"Claude Code","statut":"termine","objectif":"Jalon 7 : echelle d interface 6 en plie et deplie, sans bandes noires, APK 0.7.0 reteste sur Z Fold 8","fait":["Jalon 6 commite et pousse (1195830)","fold_mode.gd : FOLDED_MIN_ASPECT 1,45, UNFOLDED_MIN_SIZE 240x360, ui_scale, content_size, safe_margins","main.gd : _apply_scale (content_scale_size = fenetre / echelle), affectation differee depuis size_changed (rendu x5,6 avec bandes sinon, mesure sur appareil)","ui_layer.gd : apply_safe_area(window, scale) via FoldMode.safe_margins ; credits.tscn : StyleBoxFlat opaque","run_all.gd : 316 tests PASS (2 tests de seuil modifies : 1000x1500 -> 1000x1450, 1000x1499 -> 1000x1449)","APK 0.7.0 code 2 : R1 a R5 OK, plie 208x328 et deplie 308x408 a x6, capitale 30 px dans les deux modes, 0 bande en deplie, 2+2 px en plie","docs/MESURES-FOLD8.md section jalon 7, defauts 1 a 5 corriges ; CLAUDE.md ligne echelle"],"reste_a_faire":["Defaut 6 (deux ecritures au repliage), palette d interface, icone du projet"],"fichiers_modifies":["scripts/ui/fold_mode.gd","scripts/ui/ui_layer.gd","scripts/main.gd","scenes/ui/credits.tscn","export_presets.cfg","tests/headless/run_all.gd","docs/MESURES-FOLD8.md","CLAUDE.md","CHANGELOG.md","session-log.md"],"prochaine_action":"Choisir le lot suivant : icone du projet, defaut 6, palette d interface ou controles plie"}
```

## Archive

- 2026-10-23: jalon 6, preset Android, premier APK debug 0.6.0 et correctif de main.gd, 298 tests PASS (commit 1195830).
- 2026-10-23: jalon 5, UI plie / deplie, Rapport de veillee et police Silkscreen, 269 tests PASS (commit 19aa0ea).
- 2026-10-23: jalon 4, nouvelle partie, graine et village de depart, 234 tests PASS (commit 22040df).
- 2026-10-23: jalon 3, SaveManager, frais fixes et usure des outils, 204 tests PASS (commit 8baac75).
- 2026-10-23: jalon 2, DAG hors-ligne a 3 strates et greve douce, 156 tests PASS (commit 40ff1fa).
- 2026-10-23: jalon 1c, Volet D (Lien, traits, Griffes, Lanterne, Atre) integre, 119 tests PASS (commit 6de082a).
- 2026-10-22: jalon 1b, Volet C (Ecoles de Forge, bonus 3/3) integre, 77 tests PASS (commit 0e90ef3).
- 2026-10-22: jalon 1, Volet B et invariant d'IC intégrés, 39 tests PASS (commit b5deb7c).
- 2026-10-22: dépôt initialisé, 9 fichiers de base publiés (commit 8e87c86).
- 2026-10-22: audit du Volet A et journal Claude × Argon n°1 à n°8 (Claude projet).
- 2026-10-22: jalon 0, socle technique Godot (Rng, Clock, balance_a, 23 tests PASS).
