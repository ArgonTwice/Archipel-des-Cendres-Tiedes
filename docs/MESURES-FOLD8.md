# Mesures Fold 8 — jalon 6

- Date : 2026-10-23
- Modèle : SM-F971B (`ro.product.model`)
- Android : 17 (`ro.build.version.release`)
- Godot : 4.7.2.stable.official.ed1daf0bf
- APK : 0.6.0 (code 1), debug, arm64-v8a, sans build Gradle (min SDK 24, target SDK 36)
- Source : lignes `[MESURE]` de `scripts/main.gd` (`adb logcat -s godot`), `adb shell wm size` / `wm density`, `dumpsys display`.

Deux écrans physiques : externe 1248 × 1972 (portrait natif), interne 2448 × 1848 (paysage natif, installOrientation 270), soit 1848 × 2448 en portrait.

## Mesures

| | Plié (écran externe) | Déplié (écran interne) |
|---|---|---|
| `wm size` | 1248 × 1972 | 2448 × 1848 (sens natif) |
| `wm density` | 420 | 420 |
| window | 1248 × 1972 | 1848 × 2448 |
| screen | 1248 × 1972 | 1848 × 2448 |
| échelle entière (`integer_scale`) | 6 | 7 |
| visible (viewport) | 202 × 320 | 241 × 320 |
| zone sûre [x, y, w, h] | [0, 104, 1248, 1868] (caméra frontale, 104 px en haut) | [0, 0, 1848, 2448] |
| dpi | 420 | 420 |
| screen_scale | 1,56 | 2,0 |
| rafraîchissement | 120 Hz | 120 Hz |
| ratio hauteur / largeur | 1,580 | 1,325 |
| `FoldMode.is_folded` (seuil 1,5) | vrai ✅ | faux ✅ |
| pixels physiques par pixel de jeu (monde) | 6 × 1 = **6** (entier) | 7 × 0,5 = **3,5** (non entier) |
| pixels physiques par pixel d'UI (CanvasLayer) | 6 | 7 |
| image affichée / bandes noires | 1212 × 1920, bandes 18 px (côtés) et 26 px (haut, bas) | 1687 × 2240, bandes ≈ 80 px (côtés) et 104 px (haut, bas) |

## Comparaison avec le calcul Fold 7 (CLAUDE.md)

| | Fold 7 (calcul) | Fold 8 (mesuré) |
|---|---|---|
| Plié | 180 × 420, échelle 6 | 202 × 320, échelle 6 |
| Déplié | 328 × 364, échelle 6 | 241 × 320, échelle 7 |

Sur le Fold 7, la largeur limitait l'échelle (expand en hauteur). Sur le Fold 8, la hauteur la limite sur les deux écrans (1972 / 320 = 6,16 ; 2448 / 320 = 7,65) : expand élargit, la hauteur visible reste 320. Godot calcule l'expand avec le facteur fractionnaire, puis affiche à l'échelle entière : il reste des bandes noires.

## Résultats T1 à T7

| Test | Résultat | Preuve |
|---|---|---|
| T1 plié, lancement | OK | « Nouvelle partie : Clair-Foyer. », Silkscreen nette, grille visible, texte sous la caméra frontale ; `[MESURE] ready` folded true ; `save_a.dat` 12:31:48 ; build/jalon6-T1.png |
| T2 dépliage | OK | `[MESURE] size_changed` folded false à 12:32:43 ; Crédits visible, grille 2× plus dense ; `save_b.dat` 12:32:43 ; jalon6-T2.png |
| T3 repliage | OK | le jeu continue sur l'écran externe (focus GodotAppLauncher) ; `[MESURE] size_changed` folded true ; écritures `save_b.dat` 12:34:34.123 et `save_a.dat` 12:34:34.147 ; jalon6-T3.png |
| T4 déplié, paysage | OK | l'image reste en portrait (observé par Antho) ; aucun `size_changed` à la rotation ; capture 1848 × 2448 portrait ; jalon6-T4.png |
| T5 Crédits | OK | ouverture, texte OFL défile jusqu'au Disclaimer, Fermer referme ; jalon6-T5a.png, jalon6-T5b.png |
| T6 Accueil puis retour | OK | `save_a.dat` 12:41:07 (pause), `save_b.dat` 12:41:09 (reprise) ; affichage identique ; jalon6-T6.png |
| T7 arrêt forcé puis relance | OK | « Absence comptée : 0 h 10 », « Or : +0 », « Fiches de rupture : 3 », Or : 0 ; `save_a.dat` 12:41:31 ; jalon6-T7.png |

Aucune ligne SCRIPT ERROR ni ERROR dans `adb logcat -s godot` sur toute la session.

## Anomalies (rien n'est corrigé dans ce jalon)

1. **Échelle différente entre plié et déplié** : 6 contre 7. L'UI est 17 % plus grosse en déplié.
2. **Zoom 0,5 non entier en déplié** : 3,5 pixels physiques par pixel de monde. Les pixels du monde n'ont pas tous la même taille (alternance 3 / 4 px).
3. **Bandes noires** : plié 36 × 52 px perdus, déplié ≈ 161 × 208 px perdus (expand calculé en fractionnaire, affichage en entier).
4. **Zone sûre comptée deux fois en plié** : la bande noire de 26 px s'ajoute à la marge de 18 px de jeu (108 px physiques) ; le texte commence vers y = 134 au lieu de 104.
5. **Deux écritures au repliage** (T3) au lieu d'une : pause Android au changement d'écran + bascule. Sans effet (écritures à l'ancre, `last_save_utc` inchangé).
6. **Panneau Crédits semi-transparent** : le style par défaut de PanelContainer laisse voir l'UI dessous.
7. **Signature** : certificat `CN=Android Debug` (keystore debug d'Android Studio configuré dans l'éditeur), pas `CN=Godot`.

## Corrections proposées (à valider par Antho, non appliquées)

- **Anomalies 1 à 3** : ajuster `content_scale_size` à chaque `size_changed` pour que la zone visible vaille exactement fenêtre / échelle entière (208 × 328 plié, 264 × 349 déplié) : plus de bandes, au plus 6 px perdus. Puis fixer la taille d'un pixel de monde en pixels physiques plutôt qu'un zoom fixe : zoom déplié = 4 / 7 ≈ 0,571 donne 4 px physiques par pixel de monde (entier, proche du 0,5 actuel). Alternative : 6 / 7 garde 6 px comme en plié.
- **Anomalie 4** : appliquer la zone sûre après déduction de la bande noire, ou la supprimer une fois les bandes retirées.
- **Anomalie 6** : un StyleBoxFlat opaque pour PanelContainer dans `theme.tres`.
- **Anomalie 7** : créer `%APPDATA%\Godot\keystores\debug.keystore` et le régler dans les paramètres de l'éditeur (manipulation d'Antho).

## Jalon 7 (APK 0.7.0, code 2)

Échelle choisie par le code : plié = échelle entière sur la base 180 × 320, déplié = échelle entière sur UNFOLDED_MIN_SIZE 240 × 360 ; `Window.content_scale_size` = fenêtre / échelle. Seuil plié 1,45. Mesures du 2026-10-23, même appareil (SM-F971B, Android 17), Godot 4.7.2.

| | Plié (écran externe) | Déplié (écran interne) |
|---|---|---|
| fenêtre | 1248 × 1972 | 1848 × 2448 |
| content (`content_scale_size`) | 208 × 328 | 308 × 408 |
| échelle d'interface | 6 | 6 |
| reste en px physiques (mesuré sur capture) | 0 × 4 (2 px en haut, 2 px en bas) | 0 × 0 |
| zone sûre brute [x, y, w, h] | [0, 104, 1248, 1868] | [0, 0, 1848, 2448] |
| marges calculées [g, h, d, b] (px de viewport) | [0, 17, 0, 0] | [0, 0, 0, 0] |
| px physiques par pixel de monde | 6 × 1 = 6 | 6 × 0,5 = 3 |
| hauteur d'une capitale (mesurée) | 30 px | 30 px |
| case de grille de 16 px (mesurée) | 96 px | 48 px |

### Résultats R1 à R5

| Test | Résultat | Preuve |
|---|---|---|
| R1 plié, lancement 0.7.0 | OK | `[MESURE] ready` content 208 × 328, scale 6 ; bandes 2 / 2 / 0 / 0 px ; texte sous la caméra frontale ; « Absence comptée : 0 h 14 », sauvegarde du jalon 6 reprise ; build/jalon7-R1.png |
| R2 dépliage | OK après correctif | 1er essai : rendu à l'échelle 5,6 avec bandes 60 / 76 px (affectation de `content_scale_size` réentrante dans `size_changed`). Correctif : affectation différée (`set_deferred`) depuis `size_changed`. 2e essai : content 308 × 408, scale 6, 0 bande, capitale 30 px, grille 48 px ; build/jalon7-R2.png |
| R3 repliage | OK | content 308 × 408 puis 208 × 328 (4 ms, affectation différée), scale 6 ; bandes 2 / 2 / 0 / 0, capitale 30 px, grille 96 px ; build/jalon7-R3.png |
| R4 Crédits | OK | panneau opaque, ni grille ni UI visibles dessous ; build/jalon7-R4.png |
| R5 Accueil, retour, arrêt forcé, relance | OK | écritures 13:42:04 (pause), 13:42:09 (reprise), 13:42:14 (relance) ; « Absence comptée : 0 h 43 », pas de nouvelle partie ; 0 bande ; build/jalon7-R5.png |

Aucune SCRIPT ERROR ni ERROR dans `adb logcat -s godot`. Aucune boucle de `size_changed` : deux événements par pliage (le second vient de l'affectation différée).

Observation : en R5, les Crédits ouverts en déplié disparaissent au pliage et reviennent au dépliage (l'écran Crédits n'existe que dans la couche dépliée). Comportement attendu.

### Défauts du jalon 6

1. Échelle différente plié / déplié : **corrigé** (6 et 6).
2. Zoom 0,5 non entier en déplié : **corrigé** (3 px physiques par pixel de monde).
3. Bandes noires : **corrigé** (reste de 4 px en hauteur en plié, 0 en déplié).
4. Zone sûre comptée deux fois : **corrigé** (marge haute 17 px de viewport = 102 px + 2 px de reste = 104 px, la hauteur de la caméra frontale).
5. Panneau Crédits semi-transparent : **corrigé** (StyleBoxFlat opaque, couleur provisoire).
6. Deux écritures au repliage : non traité (sans effet).

## Jalon 8 (APK 0.8.0, code 3) : village de Clair-Foyer

Installé le 23/10 sur SM-F971B. Premier lancement plié à 01 h (nuit) : une ligne `[VILLAGE]` setup, échelle 6, contenu 208 × 328, 0 ERROR.

V1 à V5 validés visuellement par Antho le 23/10 ; logcat, screencap et mesure des 48 px à faire au prochain branchement.

| Test | Résultat |
|---|---|
| V1 plié : Âtre, flamme, halo, Taverne, Forge, Matériaux, UI lisible | OK à l'œil |
| V2 déplié : rayon, lisière de Brume, maisons, Portes, route sud | OK à l'œil |
| V3 PNJ à leur ancre, flânerie, aucun tremblement au repos | OK à l'œil ; PNJ figés en marchant (sprites à une image) : sautillement ajouté, à revérifier (V3 bis) |
| V4 5 pliages / dépliages | OK à l'œil |
| V5 arrêt forcé puis relance | OK à l'œil |

À faire au prochain branchement : APK 0.8.0 ré-exporté avec le sautillement, V3 bis, logcat de V3 à V5, screencap de V1 et V2, mesure des 48 px par tuile en déplié.
