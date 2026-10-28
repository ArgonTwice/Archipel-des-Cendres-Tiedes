# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"jalon 19 commité (b4c1b1f) et poussé ; Z8 1 à 6 oui, défilement tactile oui","objectif":"Jalon 19 : aptitudes des PNJ, changement de poste (saisir-déposer, boutons), auto-assignation (n°38), APK 0.19.0","fait":["balance_d.gd : delta n°38 ajouté tel quel après TRAIT_FAVORED_POSTS ; Volet-D-valide.md §8","scripts/village/assignment.gd : aptitudes (npc/apt/i), score, move (same / move / swap, verrou), auto_assign (plus grand gain d'abord)","OfflineDag étape g'' : post_next / stars_next au tick ; SaveManager.unpack efface les clés invalides","VL.site_at et SITE_POST ; village.gd npc_at / drag_npc / release_npc ; main.gd saisie (posé en _unhandled_input, glissé en _input), boutons, Libérer, auto-assignation au lancement et à chaque bascule","Cartes PNJ : aptitudes, 4 boutons de poste, Demain / verrou, Libérer, cadence selon le poste du jour ; Village : occupation des postes ; toasts","Passage en Garde au tick : cadence NORMAL, cadence_next effacée (n°38 Q7b) ; racine nettoyée (delta, jumeau, sortie)","Z8 5 et 6 non : page PNJ façon Kairosoft (liste sprite + nom, fiche dépliable, sections colorées, aptitude sur les boutons) ; graine posée avant le premier affichage","Défilement tactile : boutons et panneaux de la fenêtre en PASS (touch_scroll), glissé = défilement avec inertie, appui = appui","run_all : 767 PASS / 0 FAIL, toutes les références du jumeau tombent ; test du jalon 18 adapté (rangées de cadence visibles)","AD1 à AD5 OK (924 × 1224), sauvegarde PC restaurée ; APK 0.19.0 code 21, 0 ERROR, sha256 66db1e17 (réexport), installé sur le Fold, sauvegarde dans build/backup-fold-jalon19/"],"reste_a_faire":["Z7 (4) le 29/10","Valider les PROPOSÉ : verrou de l'occupant échangé, ordre au plus grand gain, NPC_PICK_RADIUS_PX 10, DRAG_MIN_PX 4","Z7 (4) et clôture du jalon 18 si pas encore fait"],"fichiers_modifies":["balance/balance_d.gd","scripts/village/assignment.gd","scripts/village/assignment.gd.uid","scripts/offline_dag.gd","autoload/SaveManager.gd","scripts/village/village_layout.gd","scripts/village/village.gd","scripts/village/npc.gd","scripts/main.gd","scripts/ui/ui_layer.gd","scripts/ui/village_text.gd","data/village/npcs.json","tests/headless/run_all.gd","export_presets.cfg","CLAUDE.md","docs/Volet-D-valide.md","docs/MESURES-FOLD8.md","CHANGELOG.md","session-log.md"],"prochaine_action":"Jalon 20"}
```

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"fin de session, jalons 17 (50f124e), 17 bis (2adcdd0) et 18 (77afef8) commités et poussés","objectif":"Jalons 17, 17 bis et 18 : HUD à icônes et onglets façon Kairosoft, feu animé, onglets PNJ et Village","fait":["Jalon 17 : bandeau à icônes OpenGameArt (sha256 vérifiés), jauge de saturation, fenêtre unique + onglets, APK 0.17.0, Z5 5 oui","Jalon 17 bis : feu de camp animé (4 images, 125 ms, validé), FPS inchangés, APK 0.17.1, Z6 OK","Jalon 18 : village_text.gd, onglets PNJ et Village, cadence et posture différées (clés _next appliquées au tick), grisé avec raison hors village","Noms procéduraux : RNG npc/name/i, 15 vrais prénoms + 15 fantasy par genre, genre par sprite (M / F / M, chevaliers libres), traits intacts","Bouton grisé : l'état sélectionné reste visible","724 PASS / 0 FAIL ; APK 0.18.0 code 20 installé (sauvegarde Fold dans build/backup-fold-jalon18/) ; Z7 1, 2, 3, 5, 6 oui","Copies périmées de la racine supprimées (npcs.json, prep_jalon_18.py, sortie)"],"reste_a_faire":["Z7 (4) le 29/10 : cadence de Eudes (Paisible) et posture changées après le tick","Si Z7 (4) passe : ligne « chore: APK debug 0.18.0 (code 20) testé sur Z Fold 8 » dans CHANGELOG.md et tableau Z7 de MESURES-FOLD8.md, puis feu vert du commit","Valider dans Journal.md les PROPOSÉ du jalon 18 (réglage différé, gardes sans cadence, réservoir de noms)","Argon : Élite niveau 7 tué en quelques aptitudes à Combattant 7"],"fichiers_modifies":["assets/icons/hud/*","assets/ui/theme.tres","scenes/ui/ui_folded.tscn","scenes/ui/ui_unfolded.tscn","scenes/ui/credits.tscn","scripts/ui/ui_layer.gd","scripts/ui/equipment_text.gd","scripts/ui/village_text.gd","data/village/npcs.json","scripts/segment/segment.gd","scripts/main.gd","scripts/offline_dag.gd","autoload/SaveManager.gd","scripts/village/village.gd","tests/headless/run_all.gd","export_presets.cfg","ASSETS.md","CLAUDE.md","CHANGELOG.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Z7 (4) sur Fold le 29/10"}
```

## Archive

- 2026-10-28: jalon 17 bis, feu de camp animé dans le bandeau, APK 0.17.1 validé sur Fold 8 (commit 2adcdd0).
- 2026-10-28: jalon 17, HUD à icônes, onglets et fenêtre unique façon Kairosoft, APK 0.17.0 validé sur Fold 8 (commit 50f124e).
- 2026-10-27: jalons 16 (09f2a79) et 16 bis (3f774e8) commités et poussés, APK 0.16.1 validé sur Fold 8.
- 2026-10-27: jalon 16, minerais, cargaison, coffre et Forge du village, APK 0.16.0 (commit 09f2a79).
- 2026-10-27: jalon 15 bis, niveau des monstres dans l'isolat et Éclats à ilvl, APK 0.15.1 validé sur Fold 8 (commit 98b6a76).
- 2026-10-26: bilan de session, jalons 12 bis à 14 commités, jalon 15 testé sur Fold (V1) en attente de V2 à V4.
- 2026-10-26: jalon 15, purification des Éclats et équipement porté, APK 0.15.0 validé sur Fold 8, toast de niveau corrigé, 649 tests PASS (commit 4aeb745).
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
