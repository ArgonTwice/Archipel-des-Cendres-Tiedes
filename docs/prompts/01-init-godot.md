# PROMPT CLAUDE CODE n°01 — Initialisation du projet

À coller dans Claude Code, lancé à la racine d'un clone vide de
https://github.com/ArgonTwice/Archipel-des-Cendres-Tiedes.git

Avant de lancer : copie dans le dossier `CLAUDE.md`, `README.md`, `ASSETS.md`, `CHANGELOG.md`, `session-log.md`, et dans `docs/` : `SOCLE-v2.pdf` et `Journal.md`.

```
Lis CLAUDE.md, puis docs/SOCLE-v2.pdf (sections A3, A4, A9). Objectif : poser le squelette Godot 4 du projet. Pas de gameplay, pas d'asset graphique. Aucun commit.

ÉTAPES
1. Vérifie l'environnement : version de Godot 4 installée, JDK 17, Android SDK, modèles d'export. Liste ce qui manque et dis-moi comment l'installer. Ne bloque pas le reste.
2. Crée project.godot : nom « Archipel des Cendres Tièdes », orientation portrait verrouillée, rendu mobile, stretch mode canvas_items. Crée l'arborescence décrite dans CLAUDE.md (dossiers vides avec .gitkeep).
3. Autoloads (scripts courts, typés) :
   - Clock.gd : temps Epoch UTC, marge 60 s, gel doux si l'horloge recule (LastValidTimestamp), fonction delta_offline(last_ts) -> float.
   - Rng.gd : FNV-1a 64 bits et PCG32 maison, un flux par système (create_stream(system: String, seed: int, node_id: int)). Aucun appel au randi() global.
   - SaveManager.gd : sauvegarde JSON graine + delta, fichiers tournants save_a.dat / save_b.dat, export/import Base64 (presse-papier).
4. Scène main.tscn avec deux CanvasLayer préchargés : UI_Folded et UI_Unfolded (un Label chacun suffit). Un script fold_controller.gd bascule visible et process_mode et lance un Tween de zoom Camera2D de 0,2 s. Sur PC, une touche F simule le pliage. Sur Android, détecte l'état via la taille de fenêtre (size_changed), sans reconstruire d'UI.
5. Simulateur headless : tests/headless/run_all.gd qui vérifie :
   - XP_req(L) = 15L² + 85L + 100, cumul exact au niveau 50 = 715 400 ;
   - déterminisme : même graine + même node_id = même séquence sur 10 000 tirages ;
   - Clock : recul d'horloge simulé = aucun gain, aucune perte.
   Sortie : PASS / FAIL par test, code retour non nul si échec.
6. Fichier balance/balance_a.gd vide (class_name BalanceA, uniquement les constantes de courbe d'XP ci-dessus). Les autres valeurs viendront d'Argon une fois le Volet A validé : ne rien inventer.
7. Preset d'export Android (export_presets.cfg sans secret) et .gitignore (Godot + keystores + build/).
8. Exporte un APK debug dans build/ et dis-moi où il est. Si l'export échoue, donne l'erreur exacte et la correction.

CRITÈRES DE VALIDATION
- run_all.gd : tous les tests PASS.
- L'APK démarre sur le Z Fold 8, l'écran affiche UI_Folded, le pliage/dépliage bascule UI_Unfolded sans freeze.
- git status propre de tout secret.

LIVRABLE
Résumé en 10 lignes max : ce qui est fait, ce qui manque, fichiers créés, puis `git status`. Termine par la liste des fichiers que tu proposes de commiter et attends mon feu vert. Ajoute le récap JSON dans session-log.md.
```
