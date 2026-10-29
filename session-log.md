# session-log

Un objet JSON par session, ajouté en fin de fichier.

## Sessions

```json
{"date":"2026-10-29","outil":"Claude Code","statut":"fin de session ; jalon 20 bis (eb897ab) et mode debug commités et poussés ; APK 0.20.2 (code 25) validé sur Fold (Z11 et Z12 oui)","objectif":"Jalon 20 bis (Forge, carte d'Aperçu, Purifier, Crédits à la charte) puis mode debug dans Options (build debug seulement)","fait":["Commits poussés : d6d633b (jalon 20), a8fdd4c (kenney*.zip ignorés), 5379ee5 (Z7 (4) et Z8 (4) validés)","EqText : forge_cendre_row, forge_button, purify_button, preview_head, column_head, diff_parts ; forge_reserve et diff_line supprimées","ui_layer : _action / _style_action, _build_forge (Mode en _block), _build_preview (2 colonnes, 6 écarts) ; UiStyle : CREDITS, DIFF_COLORS","812 PASS (798 + 14), largeurs identiques au jumeau (201 / 117 / 257 px) ; captures AG1 à AG5 OK","Docs : docs/Audit-ecrans.md ajouté (statuts), MESURES-FOLD8 section 20 bis + Z10 à OUI, CLAUDE.md","Mode debug : scripts/debug/debug_tools.gd, build_debug / set_debug_state (ui_layer), _on_debug (main), player.debug_invincible ; double comptage vérifié (aucun)","Z11 : carte refaite en tableau « Si tu équipes », Purifier en bouton à droite des Éclats, geste Retour qui referme (choix B) ; Z11 1 à 5 oui, Retour OK","Z12 1 à 4 oui ; 823 PASS (815 sur l'état intermédiaire du 1er commit)"],"reste_a_faire":["Jalon 20 ter : Rapport de veillée créé une fois, toasts à icône, jauge pleine en BAD (docs/Audit-ecrans.md)"],"fichiers_modifies":["scripts/ui/equipment_text.gd","scripts/ui/ui_layer.gd","scripts/ui/ui_style.gd","scenes/ui/ui_unfolded.tscn","scripts/main.gd","tests/headless/run_all.gd","export_presets.cfg","docs/Audit-ecrans.md","docs/MESURES-FOLD8.md","CLAUDE.md","session-log.md","scripts/debug/debug_tools.gd","scripts/player/player.gd"],"prochaine_action":"Prompt du jalon 20 ter"}
```

```json
{"date":"2026-10-28","outil":"Claude Code","statut":"fin de session ; jalons 19 et 19 bis poussés (b4c1b1f, 2563e85, a3e4038) ; jalon 20 prêt non commité, APK 0.20.0 installé sur le Fold","objectif":"Jalons 19, 19 bis et 20 : postes des PNJ, pages façon Kairosoft, charte d'interface","fait":["Jalon 19 : aptitudes, saisir-déposer, auto-assignation, cadence NORMAL en Garde, page PNJ dépliable, défilement tactile ; Z8 oui","Jalon 19 bis : Moral coloré, onglet Village en lignes ; Z9 oui","Prompt de charte UI rédigé pour Claude projet","Jalon 20 : ui_style.gd, Perso et Sacoche en lignes, 5 icônes DB32 ; 797 PASS, AF1 à AF5 OK"],"reste_a_faire":["Z10 1 à 5 sur Fold","Valider la ligne d'Écoles colorée en entier et l'icône ECLAT 16 px","Feu vert du commit du jalon 20, CHANGELOG (commit + APK 0.20.0 code 23)","Remettre Audit-ecrans.md où Antho le veut (copie dans build/pieces-jointes-jalon20/)","Z7 (4) du jalon 18 si pas encore noté"],"fichiers_modifies":["voir le bloc du jalon 20"],"prochaine_action":"Z10 sur Fold, puis commit du jalon 20"}
```

## Archive

- 2026-10-28: jalon 20, charte d'interface (ui_style.gd), Perso et Sacoche en lignes, 5 icônes DB32, APK 0.20.0, Z10 oui (commit d6d633b le 29/10).
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
