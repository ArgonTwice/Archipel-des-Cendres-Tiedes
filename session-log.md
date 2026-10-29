# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"fin de session ; jalons 19 et 19 bis poussés (b4c1b1f, 2563e85, a3e4038) ; jalon 20 prêt non commité, APK 0.20.0 installé sur le Fold","objectif":"Jalons 19, 19 bis et 20 : postes des PNJ, pages façon Kairosoft, charte d'interface","fait":["Jalon 19 : aptitudes, saisir-déposer, auto-assignation, cadence NORMAL en Garde, page PNJ dépliable, défilement tactile ; Z8 oui","Jalon 19 bis : Moral coloré, onglet Village en lignes ; Z9 oui","Prompt de charte UI rédigé pour Claude projet","Jalon 20 : ui_style.gd, Perso et Sacoche en lignes, 5 icônes DB32 ; 797 PASS, AF1 à AF5 OK"],"reste_a_faire":["Z10 1 à 5 sur Fold","Valider la ligne d'Écoles colorée en entier et l'icône ECLAT 16 px","Feu vert du commit du jalon 20, CHANGELOG (commit + APK 0.20.0 code 23)","Remettre Audit-ecrans.md où Antho le veut (copie dans build/pieces-jointes-jalon20/)","Z7 (4) du jalon 18 si pas encore noté"],"fichiers_modifies":["voir le bloc du jalon 20"],"prochaine_action":"Z10 sur Fold, puis commit du jalon 20"}
```

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"jalon 20 prêt, non commité ; APK 0.20.0 installé sur le Fold, Z10 à faire","objectif":"Jalon 20 : charte d'interface (ui_style.gd), onglets Perso et Sacoche en lignes, 5 icônes DB32, APK 0.20.0","fait":["docs/Charte-UI.md ; scripts/ui/ui_style.gd : couleurs par rôle (mêmes valeurs), MORAL / VERDICT sur les rôles, school_color (BalanceC), ICONS (bandeau, onglets, Âtre, boutiques, vocations, emplacements), atlas / icon / tile_region","ui_layer : plus aucune couleur en dur, _card rend une étiquette (Moral PNJ), _line, pages Perso (Vocations, Stats, Équipement) et Sacoche (Cendre, Éclats par ilvl, coffre)","EqText : num (U+00A0), voc_head / voc_tag, piece_head / piece_tag / piece_detail / empty_detail, cendre_row / shards_row / shards_detail / ore_row ; sacoche_lines supprimée","5 icônes DB32 CC0 dans assets/icons/items/ (sha256 vérifiés), 5 lignes dans ASSETS.md","run_all : 797 PASS / 0 FAIL, références du jumeau toutes tombées ; largeurs 197 / 212 px comme le jumeau","AF1 à AF5 OK (PNJ et Village identiques au jalon 19 bis), sauvegarde PC restaurée","APK 0.20.0 code 23, 0 ERROR, sha256 a0b20618, installé (sauvegarde Fold dans build/backup-fold-jalon20/)","Racine nettoyée (jumeau, sortie, maquette, icones/, Charte copiée dans docs/, Audit-ecrans.md retiré)"],"reste_a_faire":["Z10 1 à 5 par Antho","Valider : ligne d'Écoles de l'arme colorée en entier (« Enclume 3/3, ATK d'arme … »), icône ECLAT en 16 px pour la tête de carte","Feu vert du commit « feat: charte d'interface, onglets Perso et Sacoche en lignes (jalon 20) »","Jalon 20 bis : Forge, carte d'Aperçu, Options"],"fichiers_modifies":["scripts/ui/ui_style.gd","scripts/ui/ui_layer.gd","scripts/ui/equipment_text.gd","scenes/ui/ui_unfolded.tscn","assets/icons/items/*","tests/headless/run_all.gd","ASSETS.md","export_presets.cfg","CLAUDE.md","docs/Charte-UI.md","docs/MESURES-FOLD8.md","session-log.md"],"prochaine_action":"Z10 sur Fold, puis feu vert du commit"}
```
## Archive

- 2026-10-28: jalon 19 bis, Moral coloré et onglet Village en lignes dépliables, APK 0.19.1 validé sur Fold 8 (commit a3e4038).
- 2026-10-28: jalon 19, aptitudes des PNJ, changement de poste et auto-assignation, page PNJ façon Kairosoft, APK 0.19.0 validé sur Fold 8 (commits b4c1b1f, 2563e85).
- 2026-10-28: jalons 17, 17 bis et 18 commités et poussés (50f124e, 2adcdd0, 77afef8), Z7 (4) restait à vérifier le 29/10.
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
