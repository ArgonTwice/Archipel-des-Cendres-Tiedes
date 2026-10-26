# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-26","outil":"Claude Code","statut":"termine (commit pousse)","objectif":"Jalon 13 : XP de vocation (Combattant, Mineur, Forgeron) et niveaux sauvegardes, APK 0.13.0","fait":["scripts/progression.gd (new_player, level_of, combat_level, gain avec rattrapage)","SaveManager : cle player optionnelle, validee si presente, ajoutee au chargement (format 1)","Expedition par Callable player_ref, signal leveled ; Segment : log niveau, set_level, toast, expedition_ended -> sync","player.set_level (soin du seul gain de PV max, PROPOSE) ; UI Vocations + toast 2,5 s (PROPOSE)","Constantes des jalons 10 a 12 bis passees en valide sur Fold","run_all : 16 tests jalon 13, fixture S des tests de sauvegarde avec player, 618 PASS / 0 FAIL","Q1 a Q3 OK sur PC ; APK 0.13.0 code 12 : R1 a R4 OK sur Fold (R3 via am force-stop, la fermeture depuis les recents ne tuait pas le processus), ressenti : progression sensible, Elite digne d un Dark Souls"],"reste_a_faire":["Valider soin partiel a la montee de niveau et LEVEL_UP_TOAST_SEC (PROPOSE)","Argon : ecart normaux / Elite"],"fichiers_modifies":["scripts/progression.gd","autoload/SaveManager.gd","scripts/segment/expedition.gd","scripts/segment/segment.gd","scripts/main.gd","scripts/village/village.gd","scripts/player/player.gd","scripts/ui/ui_layer.gd","scenes/ui/ui_folded.tscn","scenes/ui/ui_unfolded.tscn","scripts/combat/combat.gd","scripts/combat/mob.gd","scripts/segment/mist_node.gd","scripts/segment/segment_gen.gd","scripts/ui/skill_buttons.gd","tests/headless/run_all.gd","export_presets.cfg","CLAUDE.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Jalon 14 (Lanterne sauvegardee)"}
```

```json
{"date":"2026-10-26","outil":"Claude Code","statut":"termine (commit pousse)","objectif":"Jalon 12 ter : icone du projet (joueur 112 + torche 29, fond Color8(34,30,30)), APK 0.12.2","fait":["assets/icon : icon.png 192, icon_foreground.png 432 (echelle 7, 224 x 112, zone sure 264 px), icon_background.png 432, generes par script headless hors depot","project.godot : application/config/icon seule ligne ajoutee","export_presets : launcher_icons/main_192x192, adaptive_foreground_432x432, adaptive_background_432x432, adaptive_monochrome_432x432 = icon_foreground (cles lues dans la source 4.7.2), version 11 / 0.12.2","ASSETS.md : 1 ligne pour les 3 PNG","run_all : 5 tests icone, 601 PASS / 0 FAIL","Export : plus aucune ERROR, aapt2 application-icon OK, APK installe sur Fold 8, icone OK plie et deplie"],"reste_a_faire":["Valider les constantes PROPOSE (couleurs du disque, composition de l icone)","Argon : Elite desormais tres dur"],"fichiers_modifies":["assets/icon/*","project.godot","export_presets.cfg","ASSETS.md","tests/headless/run_all.gd","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Jalon 13"}
```

## Archive

- 2026-10-26: jalon 12 bis, Fauchage de Braise de l'Elite (telegraphe 36 px, zone 40 px), APK 0.12.1 valide sur Fold 8, 596 tests PASS (commit f1ff1a9).
- 2026-10-25: bilan de la session du 24/10 (jalons 8 a 12 commites, APK 0.8.0 a 0.12.0 testes), sujets pour Argon : Elite facile, portee des armes, rogue-lite.
- 2026-10-24: jalon 12, Elite, 2 aptitudes, portees du n29 et repere de portee, APK 0.12.0, 590 tests PASS (commit fd58483).
- 2026-10-24: jalon 11 bis, auto-attaque en marche, APK 0.11.1, 571 tests PASS (commit d9aa857).
- 2026-10-24: jalon 11, segment de Brume a 3 noeuds, Cendre Vive et saturation, APK 0.11.0, 569 tests PASS (commit 5a8247a).
- 2026-10-24: jalon 10 bis, rythme des monstres dans BalanceA, deplie en temps reel, fondu d evacuation, APK 0.10.1, 527 tests PASS (commit 279c5a1).
- 2026-10-24: jalon 10, premier monstre et auto-attaque a l'arret, APK 0.10.0, 503 tests PASS (commit ec7f8f9).
- 2026-10-24: jalon 9, controles du mode plie, joystick flottant et esquive, APK 0.9.0, 426 tests PASS (commit 9ce5d53).
- 2026-10-23: jalon 8, village de Clair-Foyer affiche, tuiles Kenney et Grand Atre, APK 0.8.0, 370 tests PASS (commit c24bc72).
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
