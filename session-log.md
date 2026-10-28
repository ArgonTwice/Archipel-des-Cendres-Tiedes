# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"jalon 18 commité et poussé ; Z7 1, 2, 3, 5, 6 oui, (4) à vérifier le 29/10","objectif":"Jalon 18 : onglets PNJ et Village, cadence et posture réglables (effet au prochain jour), APK 0.18.0","fait":["Jalon 17 bis commité (2adcdd0) et poussé après Z6 OK","data/village/npcs.json (copie identique), scripts/ui/village_text.gd : npc_lines, griffe_text, cadence_help, posture_help, shop_lines, atre_lines","OfflineDag : set_next, étape g' (cadence_next / posture_next appliquées au tick) ; SaveManager.unpack efface les valeurs inconnues","6 onglets (PNJ TD 99, Village TT 104), cartes et blocs créés une fois ; show_village (textes et boutons) ; grisé avec raison hors village / sans sauvegarde","main.gd : _on_village_set, journal [VILLAGE] reglage, rafraîchissement à l'heure et à l'entrée / sortie du village ; village.gd : hour_at public","run_all : 720 PASS / 0 FAIL ; toutes les références du jumeau tombent ; AC1 à AC4 OK","APK 0.18.0 code 20 installé, sauvegarde du Fold dans build/backup-fold-jalon18/, 0 ERROR","Z7 : 1, 2, 3, 6 oui ; 5 non -> noms tirés de la graine (réservoir 30 M + 30 F, tirage sans remise, genre du nom), 722 PASS, APK réinstallé (b77cf62e)","Réservoir mêlé : 15 vrais prénoms + 15 noms fantasy inventés par genre, 722 PASS, APK réinstallé (df372fc7)","Correctif : genre par sprite (M / F / M, chevaliers libres), RNG npc/name/i à part (traits intacts sur 20 graines), 5 noms distincts (200 graines), bouton grisé sélectionné visible ; 724 PASS ; APK réinstallé (1a7414a8)"],"reste_a_faire":["Z7 (4) le 29/10 : cadence et posture changées","Si Z7 (4) passe : ligne « chore: APK debug 0.18.0 (code 20) testé sur Z Fold 8 » dans CHANGELOG.md","Valider : réglage différé, réservoir de noms, garde sans cadence (PROPOSÉ)","npcs.json à la racine (non suivi) part aussi dans l'APK : à supprimer par Antho"],"fichiers_modifies":["data/village/npcs.json","scripts/ui/village_text.gd","scripts/ui/ui_layer.gd","scenes/ui/ui_unfolded.tscn","scripts/main.gd","scripts/offline_dag.gd","autoload/SaveManager.gd","scripts/village/village.gd","tests/headless/run_all.gd","export_presets.cfg","CLAUDE.md","CHANGELOG.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Z7 (4) le 29/10 sur Fold"}
```

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"fin du jalon 17 bis, commité (2adcdd0) et poussé","objectif":"Jalon 17 bis : feu de camp animé dans le bandeau, APK 0.17.1","fait":["ui_layer.gd : FIRE_FRAMES 4, FIRE_FRAME_MS 125 (validé sur Fold), fire_region pure, _animate_fire au changement d'image seulement, _process sur Time.get_ticks_msec()","AnimatedTexture vérifiée dépréciée dans la doc 4.7, écartée","run_all : 703 PASS / 0 FAIL (+3)","AB1 et AB2 : 4 images distinctes en déplié et en plié ; FPS inchangés (≈236 animé comme fixe)","ASSETS.md : usage du feu (4 images, 125 ms)","APK 0.17.1 code 19 installé, sauvegarde du Fold copiée dans build/backup-fold-jalon17b/, 0 ERROR au lancement"],"reste_a_faire":[],"fichiers_modifies":["scripts/ui/ui_layer.gd","tests/headless/run_all.gd","ASSETS.md","export_presets.cfg","CHANGELOG.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Jalon 18"}
```

## Archive

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
