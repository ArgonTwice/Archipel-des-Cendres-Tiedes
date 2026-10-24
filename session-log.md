# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 11 : segment de Brume a 3 noeuds, Cendre Vive et saturation","fait":["balance_a.gd : bloc n26 n27 (segment, profils SIM, arene) ; docs/Volet-E-valide.md","player_motion.gd : bounds ; segment_gen.gd (cartes, passages, Brasero), expedition.gd (Cendre, Eclats, saturation), mist_node.gd/.tscn (tuile dungeon 56)","lisiere.gd = controleur de noeud (recolte, dissipate, vitrify, reset, killed/gathered) ; mob.gd bounds ; segment.gd (3 noeuds, un actif, expedition, logs [EXPEDITION])","player.gd : fondu commun mort / passage (travel, in_fade, teleported), soins en zone sure ; village.gd sol et arbres des noeuds, Brasero ; main.gd limites camera par lieu ; compteur Cendre / Eclats","run_all.gd : 569 PASS (6 tests existants adaptes), references du jumeau et des jalons 10 et 10 bis OK","E1 a E6 OK sur PC (sonde)","APK 0.11.0 code 7 : H1 expedition complete 3 min 30 s, H2 saturation a Cendre 80 (8 kills, 8 noeuds, 3 Eclats, XP 744), 0 ERROR ; H3 H4 non rapportes","Commit et push du jalon 11"],"reste_a_faire":["Valider les constantes PROPOSEES du jalon 11 (cartes, Brasero, recolte, soins au Brasero)","Retour d Antho sur H3 et H4"],"fichiers_modifies":["balance/balance_a.gd","docs/Volet-E-valide.md","docs/MESURES-FOLD8.md","CLAUDE.md","CHANGELOG.md","ASSETS.md","export_presets.cfg","data/village/village.json","scenes/village/village.tscn","scenes/ui/ui_folded.tscn","scenes/ui/ui_unfolded.tscn","scenes/segment/mist_node.tscn","scripts/segment/","scripts/combat/combat.gd","scripts/combat/lisiere.gd","scripts/combat/mob.gd","scripts/player/player.gd","scripts/player/player_motion.gd","scripts/village/village.gd","scripts/ui/ui_layer.gd","scripts/main.gd","tests/headless/run_all.gd","session-log.md"],"prochaine_action":"Elite + aptitudes, jalon 12"}
```

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 10 bis : rythme des monstres dans BalanceA, deplie en temps reel, fondu d evacuation","fait":["balance_a.gd : bloc n25 (rythme des monstres, SegmentNodeType, arene, UNFOLDED_*) ; Volet-A-valide.md 4","combat.gd : constantes de monstre supprimees (lues dans BalanceA), mob_attack_period, evac_alpha, evac_duration, EVAC_*","player.gd : evacuation (signal, fondu, retour sous le noir) ; lisiere.gd : target_ok hors evacuation, MOB_CAN_CRIT, set_active supprime","main.tscn Fondu/Noir ; main.gd camera_target statique, noir plie et deplie, stick reset a la mort ; set_combat_active supprime","run_all.gd : 527 PASS (2 tests remplaces, 26 nouveaux), references du jalon 10 inchangees","D1 a D5 OK sur PC (reserve D2 : la vue depliee couvre presque tout le sol)","APK 0.10.1 code 6, G1 a G4 OK sur Fold 8, 0 ERROR ; CLAUDE.md ligne Combat","Constantes EVAC_* validees par Antho (G4) ; commit et push du jalon 10 bis"],"reste_a_faire":["Contenu du segment et arene (attendent le n26)","Valider l arme de depart"],"fichiers_modifies":["balance/balance_a.gd","docs/Volet-A-valide.md","docs/MESURES-FOLD8.md","CLAUDE.md","CHANGELOG.md","export_presets.cfg","scenes/main.tscn","scripts/main.gd","scripts/combat/combat.gd","scripts/combat/lisiere.gd","scripts/combat/mob.gd","scripts/player/player.gd","scripts/village/village.gd","tests/headless/run_all.gd","session-log.md"],"prochaine_action":"n26 pour Argon (contenu du segment, reserve D2 sur la camera depliee)"}
```

## Archive

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
