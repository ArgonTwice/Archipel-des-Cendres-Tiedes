# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 9 : controles du mode plie, joystick flottant et esquive","fait":["Etape 0 : c24bc72 propre, 370 PASS ; (a) a (d) verifies dans la source 4.7.2","Sprite joueur dungeon 112 (village.json joueur, player_sprite ; ASSETS.md usage)","player_motion.gd, player.gd, player.tscn, touch_stick.gd, Stick dans ui_folded.tscn, Joueur dans village.tscn, solid_cells et PLAYER_SPAWN_CELL","main.gd : signaux, limites camera -328/-424/328/424, suivi plie, Tween parallele zoom + position, Stick.reset a la bascule","project.godot : emulate_touch_from_mouse=true ; CLAUDE.md 2 lignes","run_all.gd : 425 PASS (55 nouveaux), aucune valeur de reference ratee","P1 a P6 OK sur PC par sonde (clics souris injectes, emulation tactile), captures build/captures/jalon9-*","APK 0.9.0 code 4 exporte (aapt2 OK), installe ; W2 W3 W5 OK, W1 KO (sprite qui vibre), W4 2 sur 5 sans esquive a confirmer, W6 note","Correctif W1 : flip_h seulement si |dir.x| >= 0,5 (FLIP_MIN_X), 426 PASS, APK re-exporte","Retest Fold 8 : W1 bis OK, W4 bis OK (0 balayage non reconnu, manques = recharge), V3 bis OK, 48 px mesures ; logcat build/captures/jalon9-W-logcat.txt","Commit et push du jalon 9"],"reste_a_faire":["Valider les constantes techniques proposees (joystick, HALF_PX, spawn, couleurs, FLIP_MIN_X)","Icone du projet (ERROR a l export), defaut 6"],"fichiers_modifies":["ASSETS.md","CLAUDE.md","data/village/village.json","project.godot","scenes/ui/ui_folded.tscn","scenes/village/village.tscn","scenes/player/player.tscn","scripts/main.gd","scripts/village/village.gd","scripts/village/village_layout.gd","scripts/player/player.gd","scripts/player/player_motion.gd","scripts/ui/touch_stick.gd","tests/headless/run_all.gd","session-log.md","export_presets.cfg","docs/MESURES-FOLD8.md"],"prochaine_action":"Choisir le lot suivant : icone, premier ennemi et auto-attaque, ou defaut 6"}
```

```json
{"date":"2026-10-23","outil":"Claude Code","statut":"termine","objectif":"Jalon 8 : village de Clair-Foyer affiche, tuiles Kenney et Grand Atre","fait":["village.gd, village_layout.gd, npc.gd, cendre_grise.gdshader, village.json, village.tscn, npc.tscn ; debug_grid.gd retire","Ecarts 1 a 5 valides : torche Dungeon 29, dallage sur Chemins, tri -8 de la pousse, champignons retires, toits rouge et gris","build/* + !build/.gdignore dans .gitignore, build/.gdignore (import et export), preset inchange","Palette Cendre Grise finale (mockup v2b) en commentaire du shader","Sautillement des PNJ : BOB_PX 1, BOB_PERIOD_SEC 0,3, bob_offset(t, moving) ; sonde PC 32 images en marche dont 16 en haut, 0 au repos","run_all.gd : 370 tests PASS","APK 0.8.0 code 3 installe, V1 a V5 OK a l oeil (Antho)","Commit et push du jalon 8"],"reste_a_faire":["reste : logcat, screencap, 48 px et V3 bis au prochain branchement","Icone du projet (ERROR a l export), defaut 6"],"fichiers_modifies":[".gitignore","build/.gdignore",".gitattributes","ASSETS.md","CLAUDE.md","CHANGELOG.md","export_presets.cfg","scenes/main.tscn","scenes/ui/credits.tscn","scenes/village/","scripts/main.gd","scripts/village/","scripts/ui/debug_grid.gd (supprime)","data/village/village.json","assets/tiles/","tests/headless/run_all.gd","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Au prochain branchement : re-export APK 0.8.0 avec sautillement, V3 bis, logcat, screencap, mesure 48 px"}
```

## Archive

- 2026-10-23: jalon 7, echelle d'interface 6 en plie et deplie sans bandes noires, APK 0.7.0, 316 tests PASS (commit c5fe95c).
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
