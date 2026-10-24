# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 10 bis : rythme des monstres dans BalanceA, deplie en temps reel, fondu d evacuation","fait":["balance_a.gd : bloc n25 (rythme des monstres, SegmentNodeType, arene, UNFOLDED_*) ; Volet-A-valide.md 4","combat.gd : constantes de monstre supprimees (lues dans BalanceA), mob_attack_period, evac_alpha, evac_duration, EVAC_*","player.gd : evacuation (signal, fondu, retour sous le noir) ; lisiere.gd : target_ok hors evacuation, MOB_CAN_CRIT, set_active supprime","main.tscn Fondu/Noir ; main.gd camera_target statique, noir plie et deplie, stick reset a la mort ; set_combat_active supprime","run_all.gd : 527 PASS (2 tests remplaces, 26 nouveaux), references du jalon 10 inchangees","D1 a D5 OK sur PC (reserve D2 : la vue depliee couvre presque tout le sol)","APK 0.10.1 code 6, G1 a G4 OK sur Fold 8, 0 ERROR ; CLAUDE.md ligne Combat","Constantes EVAC_* validees par Antho (G4) ; commit et push du jalon 10 bis"],"reste_a_faire":["Contenu du segment et arene (attendent le n26)","Valider l arme de depart"],"fichiers_modifies":["balance/balance_a.gd","docs/Volet-A-valide.md","docs/MESURES-FOLD8.md","CLAUDE.md","CHANGELOG.md","export_presets.cfg","scenes/main.tscn","scripts/main.gd","scripts/combat/combat.gd","scripts/combat/lisiere.gd","scripts/combat/mob.gd","scripts/player/player.gd","scripts/village/village.gd","tests/headless/run_all.gd","session-log.md"],"prochaine_action":"n26 pour Argon (contenu du segment, reserve D2 sur la camera depliee)"}
```

```json
{"date":"2026-10-24","outil":"Claude Code","statut":"termine","objectif":"Jalon 10 : premier monstre et auto-attaque a l arret","fait":["Etape 0 : 9ce5d53 propre, 426 PASS ; (a) y-sort imbrique oui, (b) DISABLED coupe les enfants INHERIT oui, (c) Pcg32.next_float","Sprite monstre dungeon 121 (spectre) ; village.json monstre et lisiere ; ASSETS.md","combat.gd, mob.gd, mob.tscn, lisiere.gd, Lisiere dans village.tscn ; player.gd PV, frappe, mort, soins ; main.gd set_combat_active","run_all.gd : 503 PASS (77 nouveaux), valeurs de reference S1 S3 OK","C1 a C8 OK sur PC (sonde)","APK 0.10.0 code 5, F1 a F6 OK sur Fold 8, 0 ERROR ; CLAUDE.md ligne Combat","Commit et push du jalon 10"],"reste_a_faire":["Remarques design d Antho a trancher en co-conception : F3 mort trop rapide, F4 combat fige en deplie, F6 combat en instances / missions facon Brotato, plus d animation","Valider les constantes PROPOSEES (monstre, arme de depart, rendu)"],"fichiers_modifies":["ASSETS.md","CLAUDE.md","CHANGELOG.md","data/village/village.json","docs/MESURES-FOLD8.md","export_presets.cfg","scenes/combat/mob.tscn","scenes/village/village.tscn","scripts/combat/combat.gd","scripts/combat/lisiere.gd","scripts/combat/mob.gd","scripts/main.gd","scripts/player/player.gd","scripts/village/village.gd","tests/headless/run_all.gd","session-log.md"],"prochaine_action":"Arbitrage design des remarques F3 F4 F6 (instances / missions) avec Claude projet et Argon"}
```

## Archive

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
