# CLAUDE.md — Archipel des Cendres Tièdes (AmicusSoft)

Fichier lu par Claude Code à chaque session. Langue : français uniquement. Ton direct, zéro politesse.

## Projet
Action RPG 2D top-down + gestion de village en temps réel. Godot 4 (GDScript typé), Android, cible Samsung Z Fold 8, portrait verrouillé. Solo, hors-ligne, aucun achat intégré.
- Plié (écran cover) = agir à un pouce. Déplié (écran intérieur) = gérer. Pas de mode Flex.
- Design verrouillé : `docs/SOCLE-v2.pdf`. Il fait foi. Journal des décisions : `docs/Journal.md`.
- Co-conception : Claude (audit, prompts) × Argon (Gemini, propositions et formules). Antho relaie. Claude Code n'invente aucune valeur d'équilibrage : elles viennent de `balance_a.gd` / `balance_b.gd` validés.

## Règles de travail
- Aucun commit ni push sans demande explicite d'Antho. Avant tout commit : `git status` + résumé du diff, puis attendre le feu vert.
- Messages de commit : `feat:`, `fix:`, `docs:`, `assets:`, `chore:`, en français, une ligne.
- À chaque commit validé : une ligne dans `CHANGELOG.md`.
- YAGNI. Code minimal et complet. Commentaires uniquement pour la logique non triviale.
- Avant d'écrire du code : « Plus court et robuste ? »
- Doc Godot ambiguë : chercher sur le web avant de coder, ne pas deviner l'API.
- Fin de session : ajouter un objet JSON de récap dans `session-log.md`.

## Structure
```
res://
  autoload/        Clock.gd, Rng.gd, SaveManager.gd, Balance (constantes)
  scenes/          main.tscn, ui/ui_folded.tscn, ui/ui_unfolded.tscn, village/, brume/
  scripts/         logique de jeu
  data/            données (affixes, matériaux, PNJ, fiches) en .tres ou .json
  balance/         balance_a.gd, balance_b.gd (class_name BalanceA / BalanceB, constantes uniquement)
  assets/          sprites, audio, polices (chaque fichier tracé dans ASSETS.md)
  tests/headless/  simulateur headless (XP, loot, DAG hors-ligne, graines)
docs/              SOCLE-v2.pdf, Journal.md, Volet-A-valide.md
build/             APK (ignoré par git)
```

## Contraintes techniques déjà tranchées
- Horloge : `Time.get_unix_time_from_system()` (Epoch UTC), marge de 60 s, gel doux sans perte si l'horloge recule.
- Aléatoire : jamais le `randi()` global. FNV-1a 64 bits + PCG32 maison, un RNG par système (carte, loot, PNJ…), initialisé par `hash(world_seed + node_id)`.
- Sauvegarde : graine + delta du joueur, double fichier tournant `save_a.dat` / `save_b.dat`, export/import Base64, écriture à chaque pliage/dépliage.
- Hors-ligne : calcul O(1) en DAG à 3 strates (Extraction → Transformation → Vente). Aucune simulation par agent hors-ligne.
- UI : `UI_Folded` et `UI_Unfolded` (CanvasLayer) instanciés au lancement. Le changement d'état ne fait que basculer `visible` et `process_mode`, plus un Tween de zoom Camera2D ≤ 0,2 s. Ne jamais reconstruire une UI lourde sur `size_changed`.
- Pixel art : tuiles 16×16, sprites personnages 16×24, fiches d'armes en haute résolution côté déplié.
- Accents et genre grammatical : jetons grammaticaux FR dès le premier jalon.

## Assets
- Uniquement gratuits et open source. Licences acceptées : CC0, CC-BY, MIT, OFL pour les polices. Pas de « non commercial » ni de licence floue sans accord d'Antho.
- Chaque asset ajouté : une ligne dans `ASSETS.md` (nom, auteur, licence, URL source, fichier, usage), dans le même commit.
- Les attributions CC-BY sont reprises dans un écran Crédits.

## Build Android (APK)
- Prérequis : Godot 4.x stable avec modèles d'export Android, JDK 17, Android SDK (command-line tools, build-tools, platform), éditeur configuré avec ces chemins.
- Preset d'export `Android` : portrait, `min_sdk` raisonnable, architectures arm64-v8a.
- Debug : `godot --headless --export-debug "Android" build/archipel-debug.apk`.
- Release : keystore hors du dépôt. Aucun mot de passe, aucune clé dans git. `.gitignore` doit exclure `*.keystore`, `*.jks`, `export_credentials.cfg`, `.godot/`, `build/`.
- Après chaque APK : noter version et date dans `CHANGELOG.md`.

## Tests
- Le simulateur headless doit passer avant toute demande de commit : `godot --headless --script res://tests/headless/run_all.gd`.
- Il vérifie au minimum : courbe d'XP (cumul 715 400 XP au niveau 50), invariants de loot, déterminisme des graines, DAG hors-ligne.

## État
Voir `session-log.md` et `CHANGELOG.md`.
