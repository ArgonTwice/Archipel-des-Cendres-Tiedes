# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 12 : Elite, 2 aptitudes, portees du n29 et repere de portee","fait":["balance_c.gd : 5 range_px du n29 ; balance_a.gd : arene n29 (spawns, soin 0,25) ; Volet-E-valide.md 4 et 6","player.gd : anneau de portee, aptitudes (armement, recharges, -0,2 s par auto, oubli en fondu et a la mort)","lisiere.gd : role par monstre, Elite dormant (add_elite, wake_elite), aptitude au creneau de frappe, show_range ; mob.gd sleep / wake","segment.gd : Elite au noeud 2 en (0, 391), eveil a la saturation, cellule pleine tant qu il dort ; expedition.gd on_elite ; segment_gen.gd elite_cell","skill_buttons.gd + 2 Button dans UI_Folded (zone sure) ; tuile elite = dungeon 110","run_all.gd : 590 PASS (9 tests existants mis a jour, references du jumeau OK)","L1 a L4a OK sur PC","APK 0.12.0 code 9 : M1 2 min 52 s, 13 kills, 7 noeuds, Cendre 100, 1 Eclat, 0 mort, 16 aptitudes ; M2 3 aptitudes en marche ; M3 lisible ; M4 note","Commit et push du jalon 12"],"reste_a_faire":["Argon : Elite juge facile (M4) ; portee a revoir avec les armes","Valider les constantes PROPOSEES du jalon 12 (anneau, boutons, teinte de l Elite, ligne 91)"],"fichiers_modifies":["balance/balance_a.gd","balance/balance_c.gd","docs/Volet-E-valide.md","docs/MESURES-FOLD8.md","CLAUDE.md","CHANGELOG.md","export_presets.cfg","data/village/village.json","scenes/ui/ui_folded.tscn","scripts/ui/skill_buttons.gd","scripts/ui/ui_layer.gd","scripts/main.gd","scripts/player/player.gd","scripts/combat/lisiere.gd","scripts/combat/mob.gd","scripts/segment/segment.gd","scripts/segment/segment_gen.gd","scripts/segment/expedition.gd","scripts/village/village.gd","tests/headless/run_all.gd","session-log.md"],"prochaine_action":"Retour d Argon sur l Elite (jugee facile) et les armes, puis jalon 13"}
```

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 11 bis : auto-attaque en marche","fait":["Jalon 11 commite et pousse (5a8247a)","player.gd : can_strike hors fondu et hors esquive (plus d IDLE requis), sprite tourne vers la cible a l arret seulement","run_all.gd : 571 PASS (1 test remplace, K1 = 2 tests, references du jumeau OK)","K2 a K4 OK sur PC (sonde)","APK 0.11.1 code 8 : J1 expedition 3 min 06 s, 12 kills, 7 noeuds, Cendre 80, 0 mort, 0 ERROR ; J2 note tel quel","CLAUDE.md ligne Controles plie","Commit du jalon 11 bis (non pousse)"],"reste_a_faire":["Argon : chiffrage du combat en marche (malus eventuel), portee de l epee sans repere visuel","Design a trancher (Antho, J2) : run facon rogue-lite (armes du village + armes ephemeres trouvees, competences par XP de run, boss de fin, retour avec le butin sans les armes trouvees)","Push du jalon 11 bis sur demande"],"fichiers_modifies":["scripts/player/player.gd","tests/headless/run_all.gd","export_presets.cfg","CLAUDE.md","CHANGELOG.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Chiffrage d Argon sur le combat en marche, puis Elite + aptitudes, jalon 12"}
```

## Archive

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
