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
