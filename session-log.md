# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"jalon 17 bis validé sur Fold (Z6 : « C'est parfait »), en attente du feu vert pour le commit","objectif":"Jalon 17 bis : feu de camp animé dans le bandeau, APK 0.17.1","fait":["ui_layer.gd : FIRE_FRAMES 4, FIRE_FRAME_MS 125 (validé sur Fold), fire_region pure, _animate_fire au changement d'image seulement, _process sur Time.get_ticks_msec()","AnimatedTexture vérifiée dépréciée dans la doc 4.7, écartée","run_all : 703 PASS / 0 FAIL (+3)","AB1 et AB2 : 4 images distinctes en déplié et en plié ; FPS inchangés (≈236 animé comme fixe)","ASSETS.md : usage du feu (4 images, 125 ms)","APK 0.17.1 code 19 installé, sauvegarde du Fold copiée dans build/backup-fold-jalon17b/, 0 ERROR au lancement"],"reste_a_faire":["Feu vert du commit","FIRE_FRAME_MS 125 validé sur Fold (jalon 17 bis)"],"fichiers_modifies":["scripts/ui/ui_layer.gd","tests/headless/run_all.gd","ASSETS.md","export_presets.cfg","CHANGELOG.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Commit du jalon 17 bis après feu vert"}
```

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"fin de session, jalon 17 commité (50f124e) et poussé","objectif":"Jalon 17 : HUD à icônes, onglets et fenêtre unique façon Kairosoft, APK 0.17.0","fait":["4 icônes HUD OpenGameArt (sha256 vérifiés), ASSETS.md, Crédits Kyrise CC BY 4.0 et remerciements CC0","Bandeau à icônes + jauge de saturation en Brume ; déplié : fenêtre unique 0,5 × zone + onglets Perso, Sacoche, Forge, Options ; Purifier grisé avec sa raison","700 PASS / 0 FAIL ; BB1 à BB7 OK sur PC ; jauge 40 / 80 confirmée (référence 40 / 120 du prompt fausse)","APK 0.17.0 code 18 installé, sauvegarde du Fold copiée dans build/backup-fold-jalon17/ ; Z5 : 5 oui","Valeurs du jalon 17 validé sur Fold ; commit 50f124e poussé sur origin/main"],"reste_a_faire":["Brief du jalon 18 (onglets PNJ, Boutiques, Tableau, Village hors périmètre du 17)","Cadres UI Pack Pixel Adventure : choix d'Antho","Animation du feu de camp (image 0 seule)","Argon : Élite niveau 7 tué en quelques aptitudes à Combattant 7"],"fichiers_modifies":["assets/icons/hud/*","assets/ui/theme.tres","scenes/ui/ui_folded.tscn","scenes/ui/ui_unfolded.tscn","scenes/ui/credits.tscn","scripts/ui/ui_layer.gd","scripts/ui/equipment_text.gd","scripts/segment/segment.gd","scripts/main.gd","tests/headless/run_all.gd","export_presets.cfg","ASSETS.md","CLAUDE.md","CHANGELOG.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Brief du jalon 18 avec Claude Projet"}
```

## Archive

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
