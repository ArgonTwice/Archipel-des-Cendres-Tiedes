# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-26","outil":"Claude Code","statut":"fin de session, jalon 15 non commite","objectif":"Jalons 12 bis a 15","fait":["Commits pousses : f1ff1a9 (12 bis), a0fe915 (12 ter), 3ee6f02 (13), f4219c1 (14)","Jalon 15 code dans l arbre de travail : 649 PASS, Q1 a Q3 OK, APK 0.15.0 installe sur Fold, V1 OK"],"reste_a_faire":["V2 a V4 et lisibilite du panneau Equipement sur Fold","Commit feat: purification des Eclats et equipement porte (jalon 15) + CHANGELOG apres feu vert","Valider : Eclats d Elite d abord, ancienne piece perdue a l Equiper, glyphe & de Silkscreen, soin partiel, LEVEL_UP_TOAST_SEC","Argon : Lanterne pleine en 2 expeditions, n34"],"fichiers_modifies":["voir bloc jalon 15 ci-dessous (non commites)"],"prochaine_action":"Demain : V2 a V4 sur le Fold (APK 0.15.0 deja installe), puis commit du jalon 15"}
```

```json
{"date":"2026-10-26","outil":"Claude Code","statut":"en attente (V2 a V4 sur Fold)","objectif":"Jalon 15 : purification des Eclats en pieces et equipement porte (Volet F), APK 0.15.0","fait":["Jalon 14 commite et pousse (f4219c1)","balance_f.gd pose tel quel dans balance/","Arrondis floor (kill_xp, on_gather, gain) ; test existant kill_xp(ELITE, 1) 220 -> 219","scripts/loot/equipment.gd (roll, shares, units_of, player_stats, validation) et purification.gd (apercu, commit)","Etat : equipment, shards_elite, purify_n (cles optionnelles) ; Expedition : Sacoche sur la somme, Elite dans shards_elite, brazier_purified","Joueur : set_equipment (copie), period, crit_rate, crit_mult ; Combat.is_crit et damage parametres","UI depliee : panneau Equipement, apercu Equiper / Jeter, Lanterne (Elite n) ; Segment.purify_place","run_all : 19 tests jalon 15, 3 tests du jalon 14 adaptes au partage normaux / Elite, 649 PASS / 0 FAIL","Q1 a Q3 OK sur PC ; APK 0.15.0 code 14 installe, V1 OK"],"reste_a_faire":["V2 a V4 et lisibilite sur Fold","Feu vert pour le commit + CHANGELOG","Valider : Eclats d Elite d abord, ancienne piece perdue a l Equiper, glyphe & de Silkscreen"],"fichiers_modifies":["balance/balance_f.gd","scripts/loot/equipment.gd","scripts/loot/purification.gd","scripts/ui/equipment_text.gd","scripts/combat/combat.gd","scripts/combat/lisiere.gd","scripts/progression.gd","autoload/SaveManager.gd","scripts/segment/expedition.gd","scripts/segment/segment.gd","scripts/player/player.gd","scripts/main.gd","scripts/ui/ui_layer.gd","scenes/ui/ui_unfolded.tscn","tests/headless/run_all.gd","export_presets.cfg","CLAUDE.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"V2 (purifier les 6 Eclats au village), V3 (2 expeditions equipe), V4 (Brasero), puis commit"}
```

## Archive

- 2026-10-26: jalon 14, Lanterne niveau 1 sauvegardee (Cendre 150, Sacoche 6), gardee a la mort, APK 0.14.0 valide sur Fold 8, 626 tests PASS (commit f4219c1).
- 2026-10-26: jalon 13, XP de vocation (Combattant, Mineur, Forgeron) et niveaux sauvegardes, APK 0.13.0 valide sur Fold 8, 618 tests PASS (commit 3ee6f02).
- 2026-10-26: jalon 12 ter, icone du projet (joueur + torche Tiny Dungeon, adaptative et monochrome), APK 0.12.2 valide sur Fold 8, 601 tests PASS (commit a0fe915).
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
