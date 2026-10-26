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

## Jalon 9 (APK 0.9.0, code 4) : contrôles du mode plié

Export debug le 24/10 : `aapt2` donne versionCode 4, versionName 0.9.0 ; SHA-256 3CA252FAC80CF2E17BCE07D3A2FCCB30AD6839A242B1F727AA756D272E6F726B. Installé sur SM-F971B, lancé plié à 14 h : `[MESURE] ready` contenu 208 × 328, échelle 6, 120 Hz, 0 ERROR.

Résultats rapportés par Antho le 24/10 ; téléphone débranché avant la lecture du logcat, aucune ligne `[JOUEUR]` relevée.

| Test | Résultat | Retour d'Antho |
|---|---|---|
| W1 pouce droit | KO (rendu) | déplacement correct, mais l'animation « fait vibrant, pas net » |
| W2 pouce gauche | OK | « impec » |
| W3 collisions | OK | bloqué partout ; traverse les PNJ (conforme : collisions PNJ ↔ joueur hors périmètre) |
| W4 esquive | à confirmer | 5 sur 5 en balayages espacés ; série suivante : 2 sur 5 sans esquive (refus de recharge ou balayage non reconnu : logcat nécessaire) |
| W5 pliage | OK | « impeccable » |
| W6 ressenti | noté | « pas mal pour l'instant, à voir en gameplay réel et en combat » |
| V3 bis | non rapporté | |
| 48 px en déplié | non fait | téléphone débranché |

W1, cause probable (le personnage vibre, pas le décor) : `flip_h` suivait le signe de `dir.x` ; sur un glisser presque vertical, le pouce oscille de 1 à 2 px et retournait le sprite à chaque glissé. Correctif : miroir seulement si |dir.x| ≥ FLIP_MIN_X = 0,5 (30° de la verticale), à valider. APK 0.9.0 ré-exporté (SHA-256 03770C0583AAE9ABC07620C66DE4499FEBCF3077B2F95FECEFC5F8CB2373484A), à retester (W1 bis) au prochain branchement, avec W4 (logcat), V3 bis et la mesure des 48 px.

### Retest du 24/10 (APK 0.9.0 ré-exporté, logcat enregistré en continu : build/captures/jalon9-W-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| W1 bis | OK | Antho : personnage net (correctif FLIP_MIN_X) |
| W4 bis | OK | balayages espacés de 2 s : 5 sur 5 (`esquive` à 16:43:16,7 / 18,7 / 20,9 / 22,8 / 24,8, dist 48,0) ; série la plus rapide (environ 1 balayage / 0,35 s, ≈ 30 balayages) : 6 esquives, tous les autres en `esquive_refusee` ; aucun balayage non reconnu, les manqués sont des refus de recharge (une esquive toutes les 2,0 à 2,1 s, recharge 1,80 s) |
| V3 bis | OK | Antho : « c'est bon » |
| 48 px en déplié | OK | dallage de l'Âtre (3 tuiles) de x 852 à 995 sur la ligne y 1260 : 144 px, soit 48 px par tuile ; build/captures/jalon9-W-deplie.png |

Totaux du logcat : 24 `esquive` (dist 48,0 sauf une à 41,32, arrêtée par un obstacle), 62 `esquive_refusee`, 9 `reset`, 0 SCRIPT ERROR. Une ERROR moteur `VK_ERROR_SURFACE_LOST_KHR` à 16:43:39,5, juste après un `reset` (perte de focus, appli mise en arrière-plan 20 s) : surface Vulkan perdue pendant la pause Android, sans effet à la reprise (marche et esquive normales à 16:43:59). Un `size_changed` déplié transitoire mesure 60 Hz, puis 120 Hz.

## Jalon 10 (APK 0.10.0, code 5) : premier monstre et auto-attaque à l'arrêt

Export debug le 24/10 : `aapt2` donne versionCode 5, versionName 0.10.0 ; SHA-256 1456db8a8d21db4aaea3f58161480ba39d56eda6ea152581042005a44d7b3bea. Sprite du monstre : Tiny Dungeon 121 (spectre), lisible sur l'herbe teintée et dans la Brume.

### C1 à C8 (PC, fenêtre 416 × 657, --hour=14, clics injectés par sonde ; journal build/captures/jalon10-C-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| C1 sortie par les Portes | OK | 3 monstres en (0, 256 / 320 / 384), triés avec les arbres ; jalon10-C1.png |
| C2 approche | OK | poursuite à 54 px ; rouge 0,4 s puis `coup_recu` 9 ; jalon10-C2-telegraphe.png |
| C3 auto-attaque | OK | coups à 1,817 / 2,650 / 3,483 / 4,321 / 5,154 s (0,833 s) ; PV 75, 55, 35, 15, −5 ; `mort_monstre` xp 30 |
| C4 esquive / recul | OK | balayage pendant le rouge : `rate` (sorti de portée) ; recul pendant le rouge : `rate` |
| C5 retour au village | OK | `abandon`, retour au point, PV pleins ; joueur 100 PV ; y min des monstres 242 (jamais < 203) |
| C6 mort du joueur | OK | 3 monstres, joueur immobile : `mort_joueur` après 4,1 s, retour en (0, 32), 100 PV |
| C7 dépliage en combat | OK (redimensionnement, pas l'éditeur) | télégraphe gelé à 0,103 s pendant 1 s, Lisière DISABLED ; reprise au repliage |
| C8 réapparition | OK | `reapparition` après 20,01 s, joueur à 141,7 px du point |

### F1 à F6 (Fold 8, 24/10 de 18:45 à 18:49, plié 120 Hz ; logcat build/captures/jalon10-F-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| F1 combat au pouce | OK | « impeccable » ; 7 `mort_monstre`, 37 `coup` dont 1 critique |
| F2 esquive | OK | « impeccable » ; 16 esquives joueur, 9 refusées (recharge) ; côté monstres 1 `esquive` (i-frames) et 4 `rate` |
| F3 mort et soins | OK, remarque | « impeccable mais c'est trop rapide » ; `mort_joueur` à 18:47:50 en (1, 289) |
| F4 pliage en combat | OK, remarque | dépliage 18:48:17, repliage 18:48:24, combat repris (`mort_monstre` à 18:48:25) ; 0 ERROR ; Antho : « quand je déplie, le combat se fige, c'est pas bien » |
| F5 lisibilité | OK | « impeccable », heure réelle 18 h (phase jour) |
| F6 ressenti | noté tel quel | « j'aimerais plus d'animation, et je ne voyais pas les combats comme ça. Je verrais plus en "instance". Quand on quitte le village, on quitte vraiment le village. On part dans un autre village, un donjon, une forêt, et je verrais bien comme un Brotato par exemple. Mais sur plusieurs plateaux différents qui restent dans le thème : on part en mission. Ça différencie vraiment le côté village et le côté "mission". » |

0 ERROR et 0 SCRIPT ERROR au logcat. Remarques F3, F4 et F6 : décisions de design (SOCLE §A1, §A3), à trancher en co-conception, rien n'est modifié.

## Jalon 10 bis (APK 0.10.1, code 6) : rythme des monstres dans BalanceA, déplié en temps réel, fondu d'évacuation

Export debug le 24/10 : `aapt2` donne versionCode 6, versionName 0.10.1 ; SHA-256 1720962d38e7808f9132e2be9ffb0498618dce69e882a2879f4dae4cdc262441.

### D1 à D5 (PC, fenêtre 416 × 657, --hour=14, clics injectés, redimensionnement pour le déplié ; journal build/captures/jalon10b-D-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| D1 mort | OK | `mort_joueur`, `retour` à +0,40 s sous un noir à 0,99, capture 100 % noire (jalon10b-D1-noir.png), fin à +1,1 s, 100 PV (jalon10b-D1-apres.png) |
| D2 déplié en combat | OK, réserve | combat continu : PV joueur 100 → 73, monstre 0 75 → 55, Lisière INHERIT, zoom 0,5 ; caméra visée sur le joueur, mais la vue dépliée (616 × 816 px de monde) couvre presque tout le sol (656 × 848) : la caméra ne bouge que de ±20 / ±16 px (jalon10b-D2-deplie-combat.png) |
| D3 déplié au village | OK | caméra (0, 0), zoom 0,5 (jalon10b-D3-deplie-village.png) |
| D4 mort en déplié | OK | fondu, puis caméra (0, 0) une fois le joueur rentré (jalon10b-D4-deplie-apres.png) |
| D5 doigt tenu à la mort | OK | `reset` à la mort ; après le retour, doigt tenu et bougé : joueur immobile (IDLE) ; nouveau glisser : il repart |

### G1 à G4 (Fold 8, 24/10 de 19:58 à 19:59, plié 120 Hz ; logcat build/captures/jalon10b-G-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| G1 fondu à la mort | OK | `mort_joueur` 19:58:57,384 en (−4, 300), `retour` 19:58:57,784 (+0,40 s) en (0, 32) ; seconde mort 19:59:20,119, dépliage pendant le fondu à 19:59:20,478, `retour` 19:59:20,530 : l'évacuation traverse la bascule |
| G2 déplié en combat | OK | déplié de 19:59:08,68 à 19:59:18,75 en (3, 266) : 9 `coup`, 7 `coup_recu`, 2 `mort_monstre` (19:59:11,2 et 19:59:15,4), joueur à 1 PV : le combat continue en temps réel |
| G3 déplié au village | OK | déplié de 19:59:00,58 à 19:59:05,62 en (7, 124), dans le rayon : aucun évènement de combat (Vision d'architecte) |
| G4 ressenti | noté tel quel | « fondu bien ; combat qui continue en déplié ok » |

0 ERROR et 0 SCRIPT ERROR au logcat (111 lignes : 18 `coup`, 24 `coup_recu`, 2 `mort_monstre`, 2 `mort_joueur`, 2 `retour`, 2 `reapparition`, 12 `reset`).

## Jalon 11 (APK 0.11.0, code 7) : segment de Brume à 3 nœuds, Cendre Vive et saturation

Export debug le 24/10 : `aapt2` donne versionCode 7, versionName 0.11.0 ; SHA-256 b68a5d2a5a77bd526bcf11a42fd5dc0b31d490f033825bc4d216e51e2c666143. Tuile du nœud de Brume : Tiny Dungeon 56 (pierre grise à facettes).

### E1 à E6 (PC, fenêtre 416 × 657, --hour=14, clics injectés, redimensionnement pour le déplié ; journal build/captures/jalon11-E-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| E1 passage | OK | passage en (0, 409), arrivée (0, 1632) nœud 0, `debut`, compteur « Cendre 0/80  Éclats 0 », limites caméra [−328, 1592, 328, 3128] ; jalon11-E1-lisiere.png |
| E2 récolte | OK | barre visible (jalon11-E2-recolte.png), `recolte`, Cendre 8 ; monstre à 30 px : progression 0 pendant 1,2 s |
| E3 Brasero | OK | 40 → 100 PV dans le rayon ; un monstre attiré à 60 px n'entre jamais dans la zone sûre (3 s) ; jalon11-E3-brasero.png |
| E4 Antre | OK | 12 monstres vivants, pas d'Élite ; jalon11-E4-antre.png |
| E5 retour et mort | OK | 3 passages nord → (0, 384), compteur masqué, `fin` « retour » (Cendre 8, XP 63) ; mort en Brume → (0, 32), 100 PV, `fin` « mort » |
| E6 déplié en Brume | OK | caméra = centre écran = joueur (0, 5440), zoom 0,5, limites du nœud, aucun vide ; jalon11-E6-deplie.png |

### H1 à H4 (Fold 8, 24/10 de 20:39 à 20:43, plié 120 Hz ; logcat build/captures/jalon11-H-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| H1 expédition complète | OK | `debut` 20:39:20 ; Carrefour 20:40:27 ; Antre 20:40:56 ; retour Carrefour 20:42:04, Lisière 20:42:38, village 20:42:50 : 3 min 30 s ; bilan `fin` « retour » : Cendre 48, Éclats 0, 4 kills, 5 nœuds, XP 435 |
| H2 saturation | OK (2e essai) | 1er essai : Cendre max 48 / 80, non atteinte. 2e essai (tampon logcat, build/captures/jalon11-H2-logcat.txt) : dernier kill à 21:08:31,555 → `saturation` Cendre 80, `dissipation` sur les 3 nœuds, `eveil_elite_reporte` ; retour au village 21:09:48, `fin` « retour » : Cendre 80, Éclats 3, 8 kills, 8 nœuds, XP 744. La ligne `vitrification`, antérieure à 21:08:25, est sortie du tampon |
| H3 lisibilité | non rapporté | Antho : « tout fait », sans détail |
| H4 ressenti | non rapporté | Antho : « tout fait », sans détail |

Autres faits du log : 27 `coup`, 11 `coup_recu`, 0 `mort_joueur`, 3 `reapparition` ; PV remontés de 28 à 100 entre 20:42:11 et 20:42:28 (passage au Brasero) ; seconde expédition courte (20:43:09 → 20:43:19, dépliage pendant 7,5 s), `fin` « retour ». 0 ERROR, 0 SCRIPT ERROR.

## Jalon 11 bis (APK 0.11.1, code 8) : auto-attaque en marche

Export debug le 24/10 : `aapt2` donne versionCode 8, versionName 0.11.1 ; SHA-256 fc96a5fcb4a4c312f5f7a848e1f6ff15007701da4d59a5005f6609136711d406. SOCLE §A3 modifié par Antho le 24/10 : l'auto-attaque tourne à l'arrêt et en marche, jamais en esquive ni en fondu ; la récolte reste à l'arrêt.

### K2 à K4 (PC, fenêtre 416 × 657, --hour=14, clics injectés ; journal build/captures/jalon11b-K-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| K2 coups en marche | OK | 4 s en tournant autour d'un monstre : 4 coups, tous en état MOVE, monstre tué |
| K3 esquive | OK | 3 esquives au contact, 176 images en DODGE (relevé image par image) : 0 coup en DODGE, 2 coups avant ou après |
| K4 récolte | OK | en marche contre un nœud 1,5 s : progression max 0,004 s (une image d'arrêt au posé) ; à l'arrêt : `recolte`, GATHERED |

### J1 et J2 (Fold 8, 24/10 de 21:24 à 21:28, plié 120 Hz ; logcat build/captures/jalon11b-J-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| J1 expédition en frappant en marche | OK | `debut` 21:24:50 ; Carrefour 21:26:19 ; `vitrification` 21:27:00 (Cendre 76) ; Antre 21:27:11 ; `saturation` 21:27:17 (Cendre 80) ; retour au village 21:27:56 : 3 min 06 s. Bilan `fin` « retour » : 12 kills, 7 nœuds, Cendre 80, 0 Éclat, XP 801, 0 mort, 5 coups reçus. Jalon 11 (à l'arrêt) pour comparaison : 3 min 30 s, 4 kills, 5 nœuds, Cendre 48, 11 coups reçus |
| J2 ressenti | noté tel quel | « On ne sait pas la portée, la portée est immense sur mes tests. Mais c'est mieux. Ce que j'aimerais pour les combats, un rogue-like comme Vampire Survivors ou Cult of the Lamb. On commence avec les armes qu'on aurait craftées au village, puis quand on gagne assez d'XP pendant la run (mission) on débloque des compétences, on peut trouver des armes dans la run pour nous aider, etc. Une fois le boss de la run vaincu (ou si on meurt), on retourne au village avec ce qu'on a ramassé mais pas les armes. Les armes ne sont qu'éphémères dans la run, sauf les armes qu'on a craftées au village. » |

0 ERROR et 0 SCRIPT ERROR au logcat (60 `coup`, 5 `coup_recu`, 12 `mort_monstre`, 7 `recolte`, 8 `reapparition`, 3 `dissipation`). Portée (J2) : l'Épée & Écu frappe à 40 px (BalanceC.WEAPON_SPECS, validé) contre 16 px au contact des monstres, sans repère visuel. Portée et run façon rogue-lite = sujets de design pour Argon, rien n'est modifié.

## Jalon 12 (APK 0.12.0, code 9) : Élite, 2 aptitudes, portées du n°29 et repère de portée

Export debug le 24/10 : `aapt2` donne versionCode 9, versionName 0.12.0 ; SHA-256 9e08efdfbfa6fbccb7e4f456de39fb02ed45f9b1db83abe13ea82fb5d772c805. Sprite de l'Élite : Tiny Dungeon 110 (démon rouge). Boutons d'aptitude : Button (Control), le deuxième doigt atteint un Control en 4.7.2 (viewport.cpp gui.touch_focus par index, base_button.cpp ScreenTouch de tout index).

### L1 à L4 (PC, fenêtre 416 × 657, --hour=14, clics injectés ; journal build/captures/jalon12-L-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| L1 portée | OK | anneau absent hors combat (jalon12-L1-sans-anneau.png), présent en combat (jalon12-L1-anneau.png) ; 1er coup à 23,9 px |
| L2 aptitudes | OK | I : 45 dégâts (monstre à 50), bouton à alpha 0,4 avec « 6 » ; II : 72 dégâts ; recharge de II −2,0 s en 2 s sans frapper, −2,4 s en frappant ; une aptitude armée au village est oubliée par le fondu du passage |
| L3 Élite | OK | dormant, 712 PV en (0, 6256) (jalon12-L3-elite-dort.png) ; saturation → `eveil_elite`, poursuite ; kill → « Cendre 100/80  Éclats 1 » (jalon12-L3-elite-tue.png) |
| L4 joystick + bouton | L4a OK sur PC, multi-touch au Fold (M2) | clic sur I : aptitude armée, joystick sans doigt ; clic témoin hors bouton : joystick suit le doigt |

### M1 à M4 (Fold 8, 24/10 de 22:03 à 22:06, plié 120 Hz ; logcat build/captures/jalon12-M-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| M1 expédition jusqu'à l'Élite | OK | `debut` 22:03:16 ; Carrefour 22:04:03 ; Antre 22:04:40 ; `vitrification` 22:04:48 (74) ; `saturation` et `eveil_elite` 22:05:08 ; `mort_elite` 22:05:36 (combat de 28 s) ; retour au village 22:06:08 : 2 min 52 s. Bilan `fin` « retour » : 13 kills (12 normaux + l'Élite), 7 nœuds, Cendre 100, 1 Éclat, XP 997, 0 mort, 8 coups reçus ; 16 aptitudes lancées (dont 1 critique, 68), 3 demandes pas prêtes, 55 autos |
| M2 aptitude en marche | OK | 3 aptitudes sur 16 lancées en état « marche » (22:03:20, 22:05:23, 22:05:29) : pouce sur le joystick et autre doigt sur le bouton |
| M3 lisibilité | OK | Antho : « bien lisible » |
| M4 ressenti | noté tel quel | « C'est bien, je pense que la portée augmentera avec les armes. Et l'Élite facile, pas trop de danger, faut juste bien bouger et que l'Élite reste dans le cercle d'attaque. » |

0 ERROR et 0 SCRIPT ERROR au logcat.

## Jalon 12 bis (APK 0.12.1, code 10) : Fauchage de Braise de l'Élite (n°31, n°32)

Export debug le 26/10 : `aapt2` donne versionCode 10, versionName 0.12.1 ; SHA-256 7477ca5046b40eba8988e6c8ad44eb54c095a3b48ad8165c4513f781c0063ae8.

### P1 et P2 (PC, fenêtre 416 × 657, 240 Hz, --hour=14 ; journal build/captures/jalon12b-P-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| P1 disque rouge | OK | absent sur un normal en télégraphe (jalon12b-P1-normal-telegraphe.png), absent sur l'Élite avant (jalon12b-P1-elite-avant.png), présent pendant (jalon12b-P1-elite-disque.png), absent après l'impact (jalon12b-P1-elite-apres.png) |
| P2 esquiver le Fauchage | OK | immobile : télégraphe à 35,906 px, hors de l'anneau de 24 px, `coup_recu` 14 ; entré à 24 px : 2 `coup` (712 → 672) puis `coup_recu` 14 ; sorti à pied pendant le télégraphe : impact à 80,173 px, `rate` (jalon12b-P2-sortie.png) ; esquive au début du télégraphe : impact à 71,988 px, `rate` |

### N1 à N3 (Fold 8)

| Test | Résultat | Preuve |
|---|---|---|
| N1 expédition jusqu'à l'Élite | OK | 26/10, plié, logcat build/captures/jalon12b-N-logcat.txt. `debut` 18:59:11 ; Carrefour 19:00:05 ; `vitrification` 19:00:38 (78) ; `saturation` et `eveil_elite` 19:00:43 ; Antre 19:00:53 ; poursuite de l'Élite 19:01:15 ; `mort_joueur` 19:01:34 : expédition de 2 min 23 s, combat de 18,2 s. Bilan `fin` « mort » : 8 kills, 8 nœuds, Cendre 80, 0 Éclat, XP 744. Élite : 8 coups reçus (14 chacun, 100 → mort), 11 impacts ratés, tous à pied (aucun pendant l'esquive : 1 esquive dans le combat, 1 refusée), Élite à 465 / 712 PV ; 2 aptitudes (72 et 45), 6 autos dont 1 critique ; 1 mort. 0 ERROR et 0 SCRIPT ERROR. Jalon 12 (M1) pour comparaison : Élite tué en 28 s, 0 mort |
| N2 lisibilité du disque en plié | OK | Antho : « oui bien lisible » |
| N3 ressenti | noté tel quel | « Oh oui, comme un dark soul lol » |
