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

## Jalon 12 ter (APK 0.12.2, code 11) : icône du projet

Export debug le 26/10 : plus aucune ERROR (l'erreur « No project icon specified » a disparu) ; reste l'avertissement `aapt2` sur `mipmap/themed_icon` (référence du modèle Godot vers un fichier absent, indépendante de l'icône : icon.xml déclare bien background, foreground et monochrome). `aapt2` : versionCode 11, versionName 0.12.2, application-icon = res/mipmap-anydpi-v26/icon.xml ; SHA-256 fc3bf1df00f6a8c6a86f34cc82523dbf63cb08173665cabd15695b1c57b78634. Avant-plan à l'échelle 7 (224 × 112, diagonale 250 px, dans la zone sûre de 264 px = 66/108 × 432) ; monochrome = icon_foreground.png. Aperçus tirés de l'APK (mipmap-xxxhdpi) : build/captures/jalon12ter-icone-192.png, jalon12ter-icone-adaptative.png (masque rond de 264 px, rien n'est rogné).

| Test | Résultat | Preuve |
|---|---|---|
| Icône sur l'écran d'accueil, plié | OK | APK installé (adb install -r OK, versionCode 11) ; Antho : « Icône OK plié et déplié » |
| Icône sur l'écran d'accueil, déplié | OK | idem |

## Jalon 13 (APK 0.13.0, code 12) : XP de vocation et niveaux sauvegardés

Export debug le 26/10 : 0 ERROR ; `aapt2` donne versionCode 12, versionName 0.13.0 ; SHA-256 afd858df281632ea62fd5755919a9d7e4e5e86a2b8740d84816affc1ba0ef558.

### Q1 à Q3 (PC, fenêtre 416 × 657, --hour=14, sauvegardes du PC supprimées avant ; journal build/captures/jalon13-Q-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| Q1 toast au 7e kill | OK | 7e kill : `niveau` COMBATTANT 2 (xp 210), joueur `niveau` 2 PV 118 / 118, ATK 24, DEF 6 ; toast « Combattant niveau 2 ! » visible (jalon13-Q1-toast.png) |
| Q2 relance | OK | retour au village : `fin` « retour », écriture ; relance : voc_xp {COMBATTANT 210, MINEUR 0, FORGERON 0}, joueur Nv 2 PV 118 / 118 (jalon13-Q2-relance.png) |
| Q3 déplié | OK | « Combattant  Nv 2  10 / 330 XP », « Mineur  Nv 1  0 / 200 XP », « Forgeron  Nv 1  0 / 200 XP » (jalon13-Q3-deplie.png) |

### R1 à R4 (Fold 8, sauvegarde du jalon 12 conservée)

| Test | Résultat | Preuve |
|---|---|---|
| R1 sauvegarde du jalon 12 | OK | copie avant installation dans build/backup-fold-jalon12/ : seq 204, Or 60, 5 PNJ (moral 83 / 85 / 91 / 82 / 87), sans clé player ; après le boot 0.13.0 : seq 205, même graine, Or 60, mêmes PNJ (Forge 92 : reprise hors-ligne de 40 min), voc_xp 0 / 0 / 0, `niveau` 1, 100 PV ; 0 ERROR |
| R2 deux expéditions | OK | logcat build/captures/jalon13-R-logcat.txt. Expédition 1 : `debut` 21:38:46, `fin` « mort » 21:41:37 (2 min 51 s), 12 kills, 7 nœuds, Mineur 2 (21:39:26), Combattant 2 (21:40:05, PV max 118) ; Élite : 12,1 s, 8 coups reçus (14), 3 impacts ratés, 8 autos et 3 aptitudes, Élite à 347 / 712. Expédition 2 : `debut` 21:42:02, `fin` « mort » 21:44:08 (2 min 06 s), 12 kills, 7 nœuds, Mineur 3 (21:42:30), Combattant 3 (21:42:56, 64 → 136 PV max) ; Élite : 12,8 s, 6 coups reçus, 6 ratés, 12 autos et 1 aptitude, Élite à 356 / 712. 2 morts. Sauvegarde relue sur l'appareil après les 2 fins : seq 209, Combattant 720, Mineur 882, Forgeron 0. 0 ERROR |
| R3 relance | OK | la fermeture depuis les applis récentes laissait le même processus (pid 14013) : arrêt par `am force-stop`, relance par l'icône → pid 2599, `niveau` 3, 136 PV ; sauvegarde relue : seq 221, Combattant 810 (Nv 3), Mineur 1 071 (Nv 4), Forgeron 0, XP des parties jouées entre-temps comprise |
| R4 ressenti | noté tel quel | « on sent la pregression mais le boss waow, digne d'un dark soul » |

## Jalon 14 (APK 0.14.0, code 13) : Lanterne sauvegardée, Cendre Vive et Éclats

Export debug le 26/10 : 0 ERROR ; `aapt2` donne versionCode 13, versionName 0.14.0 ; SHA-256 f6c9c1bcdabf2f862b9a96415aa96d5e0c7cd48857fc4ad767475da8de7ce2a3.

### T1 à T3 (PC, fenêtre 416 × 657, --hour=14, partie neuve ; journal build/captures/jalon14-T-sonde.txt)

Chaque phase : 10 kills de normaux et 3 nœuds de Brume comptés par le signal gathered de Segment (sans geste de récolte).

| Test | Résultat | Preuve |
|---|---|---|
| T1 expédition et retour | OK | expédition : Cendre 44, Éclats 3 ; `fin` « retour » ; « Lanterne : Cendre 44/150  Éclats 3/6 » plié et déplié (jalon14-T1-retour.png) |
| T2 2e expédition, mort | OK | Cendre 44, Éclats 3 de plus ; `fin` « mort » ; « Lanterne : Cendre 88/150  Éclats 6/6 » (jalon14-T2-mort.png) |
| T3 relance | OK | au lancement : « Lanterne : Cendre 88/150  Éclats 6/6 » (jalon14-T3-relance.png) |

### U1 à U3 (Fold 8, sauvegarde du jalon 13 conservée, copie dans build/backup-fold-jalon13/)

| Test | Résultat | Preuve |
|---|---|---|
| U1 sauvegarde du jalon 13 | OK | avant : seq 222, Or 60, Combattant 810, Mineur 1 071 ; après le boot 0.14.0 (pid 13879) : seq 223, mêmes valeurs, Lanterne 0 / 0, `niveau` 3, 136 PV ; 0 ERROR |
| U2 deux expéditions | OK | logcat build/captures/jalon14-U-logcat.txt. Expédition 1 : 22:34:08 → 22:37:02 (2 min 54 s), `fin` « retour », 13 kills dont l'Élite (combat de 16,7 s), 7 nœuds, Cendre 100, 1 Éclat ; Combattant 4 ; Lanterne 0/0 → 100/150, 1/6. Expédition 2 : 22:37:10 → 22:40:16 (3 min 06 s), `fin` « retour », 13 kills dont l'Élite (16,2 s), 7 nœuds, Cendre 100, 5 Éclats ; Mineur 5, Combattant 5 (172 PV) ; Lanterne → 150/150 (10 `lanterne_pleine`, 50 de Cendre perdus), 6/6 (1 `sacoche_pleine`, l'Éclat de l'Élite). 0 mort, 0 ERROR |
| U3 relance | OK | `am force-stop` (pid 13879) puis relance par l'icône → pid 26336, `niveau` 5, 172 PV ; sauvegarde relue : seq 226, Combattant 1 922, Mineur 1 953, Forgeron 0, Lanterne 150 / 6 |

## Jalon 15 (APK 0.15.0, code 14) : purification des Éclats et équipement porté

Export debug le 26/10 : 0 ERROR ; `aapt2` donne versionCode 14, versionName 0.15.0 ; SHA-256 5dc3a66c5e8e7fa6b7a54bcab17d45cd485bf12fe8ce547923aa8dee7314da33.

### Q1 à Q3 (PC, 416 × 657 plié et 1248 × 1300 déplié, --hour=14, partie neuve ; journal build/captures/jalon15-Q-sonde.txt)

Expédition de la sonde : 7 nœuds comptés par le signal gathered, 12 normaux, puis l'Élite : 6 Éclats normaux, l'Éclat de l'Élite refusé (`sacoche_pleine`). Choix de la sonde : Équiper si l'écart PV / ATK / DEF n'a aucun négatif, sinon Jeter.

| n | Pièce | Choix | Stats avant → après (Nv 3) |
|---|---|---|---|
| 0 | Arme Bonne, Brasier 3/3, ATK d'arme 10,9, +5,5 ATK, +6 % ATK d'arme | Équiper | ATK 27 → 33 |
| 1 | Plastron Commun, +36 PV | Équiper | PV 136 → 172 |
| 2 | Bottes Rares, +28 PV, +10 % dégâts critiques, +2,3 DEF | Équiper | PV 172 → 199, DEF 8 → 10, ×1,5 → ×1,6 |
| 3 | Bottes Bonnes, +24 PV, +2,8 ATK | Jeter | inchangé |
| 4 | Plastron Commun, +6,6 DEF | Jeter | inchangé |
| 5 | Arme Bonne, Enclume 3/3, +3,5 DEF, +22 PV | Jeter | inchangé |

| Test | Résultat | Preuve |
|---|---|---|
| Q1 purification au village | OK | 6 purifications (n 0 à 5), Sacoche 6 → 0, bouton grisé ensuite ; final PV 199, ATK 33, DEF 10, cadence 1,20/s, critique 5 % ×1,6 (jalon15-Q1-avant.png, jalon15-Q1-apres.png) |
| Q2 Brasero | OK | Sacoche complétée à 3 par la sonde ; au Brasero (0, 3984) : n 6 jetée, n 7 (Casque Commun +6,0 ATK) équipée, 3e bouton grisé, brazier_purified 2 (jalon15-Q2-brasero-grise.png) |
| Q3 relance | OK | relance : PV 199, ATK 39, DEF 10, équipement identique ; aperçu (Bottes Communes +6,6 DEF) fermé par le pliage puis rouvert : même pièce, purify_n 8 inchangé (jalon15-Q3-relance.png, jalon15-Q3-apercu.png) |

Lisibilité PC : le « & » d'« Épée & Écu » ressemble à un « $ » dans Silkscreen.

### V1 à V4 (Fold 8, sauvegarde du jalon 14 conservée, copie dans build/backup-fold-jalon14/)

| Test | Résultat | Preuve |
|---|---|---|
| V1 sauvegarde du jalon 14 | OK | avant : seq 229, Or 60, Combattant 1 922, Mineur 1 953, Lanterne 150 / 6 ; après le boot 0.15.0 (pid 2795) : seq 230, mêmes valeurs, 6 Éclats normaux, 0 d'Élite, purify_n 0, arme de départ ; `equipement` puis `niveau` 5 (172 PV, ATK 32, DEF 11) ; 0 ERROR |
| V2 purification des 6 Éclats | OK | Antho : arme purifiée et équipée, puis les autres ; journal : n 6 = Éclat d'Élite purifié en premier au village (Bottes, jetées) ; n 0 à 5 hors journal (capture coupée) |
| V3 deux expéditions équipé | OK | journal build/captures/jalon15-V-logcat.txt : 2 fins « retour » (7 nœuds, 13 monstres, Élite tuée, Cendre 100, Éclats 1 puis 6) ; niveau 6 Mineur et Combattant (ATK 53, DEF 15, PV 189/213) ; 0 ERROR |
| V4 Brasero | OK | Antho, après le ré-export |
| W1 toast « Combattant niveau X » | KO, corrigé | resté affiché ; cause probable : le timer (somme des delta) finissait avant Time.get_ticks_msec() + 2,5 s, le masquage était ignoré ; correctif : numéro du dernier toast ; APK 0.15.0 ré-exporté et installé le 27/10 à 08:19 ; W1 bis OK (Antho) |
| Lisibilité à 48 px par tuile | OK | Antho : panneau Équipement lisible ; LEVEL_UP_TOAST_SEC 2,5 s lisible ; « & » de Silkscreen lu « $ », remplacement par « et » refusé, & conservé ; soin partiel non vu (invisible à PV pleins) |

## Jalon 15 bis (APK 0.15.1)

Niveau du segment figé au départ (BalanceA.get_segment_mob_level, n°37), Sacoche = liste d'Éclats avec leur ilvl. Simulateur : 660 PASS, 0 FAIL (G1 à G7).

Export debug le 27/10 : 0 ERROR ; `aapt2` donne versionCode 15, versionName 0.15.1 ; SHA-256 6a0925aab54fd3950fd63a41adf1334795ec10f92b0cdd7ccb9aadec4902edfe.

### W1 et W2 (PC, 416 × 657, --hour=14, partie neuve ; journal build/captures/jalon15b-W-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| W1 1re expédition | OK | Combattant 1, elite_kills 0 : « debut » niveau_segment 1, nœuds [1, 1, 1], Élite 712 / 16 / 4, normal 95 / 10 / 4 ; Élite tué ; fin : Combattant 3, elite_kills 1, Sacoche 3 normaux + 1 d'Élite, tous ilvl 1 |
| W2 2e expédition | OK | attendu get_segment_mob_level(0, 3, 1) = 3 : « debut » niveau_segment 3, nœuds [3, 3, 3], Élite 1147 / 23 / 6, normal 153 / 14 / 6 ; Éclats ramassés ilvl 3 ; Combattant 4 en fin, monstres restés au niveau 3 |

### X1 à X3 (Fold 8, sauvegarde du jalon 15 conservée, copie dans build/backup-fold-jalon15/ ; journal build/captures/jalon15b-X-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| X1 sauvegarde du jalon 15 | OK | avant : seq 276, Combattant 3 064 (niveau 6), shards 0, shards_elite 0, purify_n 13 ; après le boot 0.15.1 (pid 30217) : seq 277, shard_bag [], elite_kills 0, anciennes clés retirées ; segment attendu 6 ; « niveau » 6 : 245 / 40 / 23 ; 0 ERROR |
| X2 deux expéditions | OK | expédition 0 : « debut » niveau_segment 6 ; 12 normaux, 7 nœuds, 0 Éclat (probabilité 0,95^12 × 0,80^7 = 0,11) ; Élite niveau 6 : stat 245 / 40 / 23 (« niveau » 6), 211 PV au 1er coup, 17,8 s du 1er coup à la mort du joueur, 8 coups reçus à 27 (10 ratés), Élite à 900 / 1800 ; coups portés : 36 (auto), 80 et 128 (aptitudes) ; 1 mort, fin « mort », Éclat garanti de l'Élite perdu ; expédition 1 : « debut » niveau_segment 6 (pas de recalcul, Combattant 6, elite_kills 0), 3 normaux, 4 nœuds, 1 Éclat normal ilvl 6, retour sans combat d'Élite ; 0 ERROR |
| X3 purification d'Éclats ilvl 6 | OK | n 13 au village, source NORMAL, ilvl 6 : Arme Commune, Écoles 3/3/1, FLAT_HP 26,0, équipée -> 323 / 63 / 16 |

## Jalon 16 (APK 0.16.0)

Minerai de nœud dans la cargaison (Mineur), coffre au retour, caisse unique à la mort ; Forge du village (craft avec ou sans Cendre, emplacement choisi, Qualité Supérieure). Simulateur : 679 PASS, 0 FAIL (K0 à K5, C2, Cargaison, Caisse, Forge, Sauvegarde ; +1 compilation de forge.gd). Sprite de caisse : tuile 63 de Tiny Dungeon (« caisse », déjà au dépôt).

Export debug le 27/10 : 0 ERROR ; `aapt2` donne versionCode 16, versionName 0.16.0 ; SHA-256 cb7a42fa5639093505c6e823da4ab99b806ae6cc4620ebf55923e28c6fd7217a.

### Y1 à Y4 (PC, 416 × 657 plié et 1248 × 1300 déplié, --hour=14, partie neuve ; journal build/captures/jalon16-Y-sonde.txt)

| Test | Résultat | Preuve |
|---|---|---|
| Y1 expédition, retour | OK | 7 nœuds récoltés, cargaison 14, compteur « Minerai 14/25,2 kg » (Mineur 2) ; retour : log « coffre » ajout 14, coffre 14 |
| Y2 mort avec minerai, caisse | OK | 7 nœuds, cargaison 14, mort au nœud 0 cellule (8, 116) : « caisse_posee » 14, sprite visible sous Noeud0 en (128, 1856), fin « mort » ; nouvelle expédition à la caisse : « caisse_ramassee » pris 14 reste 0, caisse null, sprite masqué ; retour : coffre 28 |
| Y3 deux crafts | OK | Arme avec Cendre : coffre 28 → 24, Cendre 150 → 125, Forgeron +126, Rare ilvl 1, équipée ; Bottes sans Cendre : coffre 20, Cendre 125, Forgeron +25, Communes, jetées (jalon16-Y3-forge.png, jalon16-Y3-apres.png) |
| Y4 quitter sur la carte | OK | Casque sans Cendre laissé ouvert (forge_pending écrit), relance : carte visible, même pièce, 4 boutons Forge grisés (jalon16-Y4-carte.png, jalon16-Y4-relance.png) |

Correctif pendant Y : le panneau Forge affichait le coffre d'avant le retour (14 au lieu de 28) ; main.gd rafraîchit le joueur à chaque fin d'expédition.

### Z1 à Z4 (Fold 8, sauvegarde du jalon 15 bis conservée, copie dans build/backup-fold-jalon15b/ ; journal build/captures/jalon16-Z-logcat.txt)

| Test | Résultat | Preuve |
|---|---|---|
| Z1 sauvegarde du jalon 15 bis | OK | capture déplié jalon16-Z-ecran-4630947004648141459.png : coffre 0, Forgeron 1 (0 / 200 XP), Cendre 150, 323 / 63 / 16, boutons Forge grisés ; avant : seq 293, Combattant 3 514, Mineur 3 528, Forgeron 0 (niveau 1), Cendre 150, Sacoche vide ; chargement PC de cette copie : chest {}, crate null, forge_n 0, forge_pending null |
| Z2 deux expéditions | OK | jalon16-Z-logcat.txt (0 ERROR) : mort, « caisse_posee » 16 au nœud 1 ; expédition suivante « caisse_ramassee » 16 reste 0, « cargaison_pleine » ×3 (2 perdus) ; Élite (niveau de segment 7, Combattant 7) éveillé à la saturation, tué ; retour : minerai 26, coffre 32 |
| Z3 crafts à la Forge | OK | 4 crafts [FORGE] : sans Cendre +50 XP Commun ilvl 2 ; avec Cendre +252 XP, n 3 Supérieure ilvl 4, n 4 Bon ; coffre −4 par craft (Antho) ; Antho : intérêt de « Avec Cendre » et Qualité Supérieure non compris → jalon 16 bis |
| Z4 lisibilité du panneau Forge | NON (3 non) | sans forger : effet de « Avec Cendre » incompris, coût invisible, Qualité Supérieure non remarquée sur la carte → jalon 16 bis |

Correctif pendant Z (plié) : la ligne d'expédition « Cendre … Éclats … Minerai … kg » dépassait 208 px et décalait toute la colonne à gauche ; Label à retour à la ligne (deux scènes) et minerai sur sa propre ligne en plié.

## Jalon 16 bis (APK 0.16.1)

Forge lisible, interface seulement (aucune règle ni valeur). Panneau Forge déplié : titre « Forge », réserve « Tu as : N minerais, N Cendre », interrupteur, aide (EqText.forge_help : coût, raretés lues dans BalanceF, Qualité Supérieure, ilvl, XP réelle avec rattrapage), 4 boutons, raison du grisé (EqText.forge_block_reason). Carte : « Pièce forgée » / « Pièce purifiée », « QUALITÉ SUPÉRIEURE : +2 ilvl » en tête, 16 px, #E69F00 (PROPOSÉ). Après le premier Z4 (colonne qui déborde) : menu du bas à la Kairosoft « Équipement | Forge | Crédits », un seul panneau à la fois, aucun au lancement (village visible), 2e appui referme, la carte de résultat masque les panneaux et grise les onglets. Après Z4 ter (Antho : Supérieure trop grosse) : taille des lignes, couleur gardée ; verdict coloré en tête de carte (EqText.compare : meilleure si aucune stat ne baisse et une monte, moins bonne à l'inverse, sinon neutre ; vert #009E73, vermillon #D55E00, PROPOSÉ). Simulateur : 689 PASS, 0 FAIL (+10).

Export debug le 27/10 : 0 ERROR ; `aapt2` donne versionCode 17, versionName 0.16.1 ; SHA-256 093d536c44b89131a6ba8f783c7d329cd778e87962acc393e3b0823bea5f23f6 (sans menu), puis 30fd7f44dc6a13a4739f9dc33036988a51a12d1f22c2a922a118c4117850fedf (avec menu), puis 3f157ee9ce2c9d883628776eceacf1978a1e4bc43c7ad3531efcf46bc703f589 (verdict, même version). Installé par `adb install -r` ; sauvegarde du Fold conservée, copie dans build/backup-fold-jalon16/.

### AA0 à AA4 (PC, 924 × 1224 déplié, échelle 3 = 308 × 408 comme le Fold déplié, --hour=14, partie neuve, coffre 12 et Cendre 100 posés par une sonde temporaire ; sauvegarde PC restaurée ensuite)

416 × 657 donne le mode plié (rapport 1,58 > 1,45).

| Test | Résultat | Preuve |
|---|---|---|
| AA0 menu fermé | OK | Or, 3 Vocations, Lanterne en haut, village dégagé, menu « Équipement | Forge | Crédits » en bas (jalon16b-AA0-menu-ferme.png) |
| AA1 Forge sans craft | OK | avec Cendre : coût 4 minerais + 25 Cendre, Commun 65 %, Bon 25 %, Rare 10 %, Supérieure 20 % +2 ilvl, ilvl 1, +126 XP ; sans : 4 minerais, toujours Commun, jamais, ilvl 1, +25 XP (jalon16b-AA1-avec-cendre.png, jalon16b-AA1-sans-cendre.png) |
| AA2 bouton grisé | OK | coffre 2 : 4 boutons grisés, « Il manque 2 minerais » atténuée sous les boutons (jalon16b-AA2-grise.png) |
| AA3 carte Supérieure | OK | fixture K5 (graine 1, n 8, Plastron, Forgeron 1) : « QUALITÉ SUPÉRIEURE : +2 ILVL » ambrée à la taille des lignes, « MEILLEURE QUE L'ÉQUIPÉE » en vert, « Pièce forgée », Plastron Bon ilvl 3 (jalon16b-AA3-superieure.png, copiée dans Téléchargements du Fold) ; onglets grisés |
| AA4 onglet Équipement | OK | panneau Équipement seul, titre « Équipement » (jalon16b-AA4-equipement.png) |

### Z4 bis, premier passage (Fold 8, APK 0.16.1 sans menu, sauvegarde du jalon 16 conservée ; journal build/captures/jalon16b-Z4-logcat.txt, 0 ERROR)

| Test | Résultat | Preuve |
|---|---|---|
| Sans forger, effet de « Avec Cendre » compris | OUI | Antho |
| Coût visible | OUI | Antho |
| Qualité Supérieure saute aux yeux | PARTIEL | Antho : ne saute pas aux yeux, mais écrite et compréhensible |
| Lisibilité à 48 px par tuile | NON | capture déplié : colonne plus haute que l'écran, débordement des deux côtés ; Or et Vocations coupés en haut, rapport coupé en bas ; sous-menus demandés |

### Z4 ter (Fold 8, APK 0.16.1 avec menu, sauvegarde conservée)

| Test | Résultat | Preuve |
|---|---|---|
| Lisibilité, rien de coupé | OK | Antho : « bien mieux » |
| Qualité Supérieure saute aux yeux | PARTIEL | 1 craft avec Cendre sur le Fold, non Supérieure (log) ; sur capture AA3 : « pas mal, mais trop gros » → taille des lignes ; Antho demande un repère « meilleure que l'équipée » → verdict coloré |

### Z4 quater (Fold 8, APK 0.16.1 avec verdict)

| Test | Résultat | Preuve |
|---|---|---|
| Qualité Supérieure visible sans être trop grosse | OK | Antho : « C'est parfait » |
| Verdict meilleure / moins bonne lisible sur la carte | OK | Antho : « C'est parfait » |

## Jalon 17 (APK 0.17.0)

Menus rangés façon Kairosoft, interface seulement (aucune règle ni valeur). Bandeau Hud identique plié / déplié : fond #0E0C10 alpha 0,47 sans bord, couples icône + nombre (1 px, 6 px entre couples, marge 2 px), 20 px de haut ; plié sans Or, minerai seulement en Brume (kg portés / capacité) ; déplié : Or, Cendre, Éclats, minerai du coffre ou cargaison. Jauge de saturation 2 px sous le bandeau en Brume (Cendre de l'expédition / SEGMENT_PRE_ELITE_CENDRE_BUDGET, #AAB4C8 sur #0E0C10 alpha 0,63). Déplié : 4 onglets à icône seule (Perso TD 112, Sacoche TT 107, Forge TD 74, Options TT 83), fenêtre unique de 0,5 × la zone ancrée au-dessus des onglets (barre de titre #463024 + « × », défilement vertical), carte Équiper / Jeter et Rapport de veillée centrés. Thème : fond #141216 alpha 0,92, bord 1 px #96846E, marge 2 px ; valeurs validé sur Fold (jalon 17), Z5 : 5 oui. Icônes du HUD : 4 PNG OpenGameArt vérifiés au sha256, AtlasTexture en taille native. Simulateur : 700 PASS, 0 FAIL (+11).

Export debug le 28/10 : 0 ERROR ; `aapt2` donne versionCode 18, versionName 0.17.0 ; SHA-256 5a3d352162552fb7160dbbd7c68878fb8d31b278446db4a5b59569eb9d596a4c. Installé par `adb install -r` (versionCode 18, versionName 0.17.0 relus sur l'appareil).

### BB1 à BB7 (PC, --hour=14, sauvegarde PC restaurée ensuite ; Cendre 75, 2 Éclats dont 1 d'Élite, coffre 12 posés par une sonde temporaire)

Plié 416 × 657 (zone 208 × 328), déplié 924 × 1224 (zone 308 × 408). Mesures du jeu réel (get_global_rect) : bandeau y 0 à 20, jauge 20 à 22, fenêtre 184 à 388 (204 px), onglets 388 à 408 (20 px), aussi en Brume.

| Test | Résultat | Preuve |
|---|---|---|
| BB1 plié en Brume | OK | Cendre 75/150, Éclats 2/6, minerai 4/25,2, jauge 32/80 (jalon17-BB1-plie-brume.png) |
| BB2 déplié sans onglet | OK | monde entre bandeau et onglets (jalon17-BB2-deplie-sans-onglet.png) |
| BB3 onglet Perso | OK | vocations, stats sur 2 lignes, arme sur 2 lignes (jalon17-BB3-perso.png) ; maquette non disponible côté Claude Code, comparaison à faire par Antho |
| BB4 Sacoche, Purifier grisé | OK | au Brasero, quota atteint : « Déjà 2 purifications au Brasero cette expédition » atténuée (jalon17-BB4-sacoche-grise.png) |
| BB5 Forge | OK | contenu du jalon 16 bis sans titre (jalon17-BB5-forge.png) |
| BB6 carte Équiper / Jeter | OK | centrée, fenêtre masquée, onglets grisés (jalon17-BB6-carte.png) |
| BB7 Options puis Crédits | OK | bouton Crédits, écran Crédits avec ligne Kyrise et remerciements CC0 (jalon17-BB7a-options.png, jalon17-BB7b-credits.png) |

Retours à la ligne (Label visibles, lignes affichées − lignes du texte) : 0 partout à 208 et 308 px, sauf l'écran Crédits : ligne Kyrise et ligne de remerciements sur 2 lignes chacune à 300 px (attendu pour ces longueurs) ; texte OFL déjà replié avant.

### Z5 (Fold 8, APK 0.17.0, sauvegarde conservée, copie dans build/backup-fold-jalon17/ ; journal build/captures/jalon17-Z5-logcat.txt, 0 ERROR)

| Test | Résultat | Preuve |
|---|---|---|
| (1) icônes du bandeau reconnues sans légende | OUI | Antho |
| (2) plié dégagé, jauge lisible | OUI | Antho |
| (3) niveaux, équipement et minerais trouvés sans chercher | OUI | Antho |
| (4) 4 onglets au pouce sans erreur | OUI | Antho |
| (5) fenêtre conservée au pliage / dépliage, sans saccade | OUI | Antho |

## Jalon 17 bis (APK 0.17.1)

Feu de camp de la Cendre animé dans le bandeau, cosmétique (aucune règle ni valeur, aucun asset modifié). ui_layer.gd : FIRE_FRAMES 4, FIRE_FRAME_MS 125 (durée de l'auteur, GIF 120–130 ms ; validé sur Fold (jalon 17 bis)), fire_region(ms) pure (région de HUD_ICONS["cendre"] décalée d'une largeur d'image), _animate_fire(ms) ne touche la région qu'au changement d'image, appelé par _process avec Time.get_ticks_msec() (horloge monotone, pas Clock). AnimatedTexture écartée : « Deprecated: This class does not work properly in current versions and may be removed in the future » (doc Godot 4.7). Couche masquée = process_mode DISABLED, feu figé. Simulateur : 703 PASS, 0 FAIL (+3).

Export debug le 28/10 : 0 ERROR ; `aapt2` donne versionCode 19, versionName 0.17.1 ; SHA-256 29497d160ac570577f556beaea57125e6bb65ba86f42cb919bbe7b51122a12a5. Installé par `adb install -r`, sauvegarde du Fold conservée, copie dans build/backup-fold-jalon17b/ ; lancement : 0 ERROR (build/captures/jalon17b-Z6-logcat.txt).

### AB1, AB2 et FPS (PC, script de capture hors dépôt, _process de la couche coupé pendant les captures ; sauvegarde PC restaurée ensuite)

| Test | Résultat | Preuve |
|---|---|---|
| AB1 déplié 924 × 1224 (zone 308 × 408), images 0 à 3 | OK | 4 bandeaux distincts, feu entier (jalon17b-AB1-deplie-image0..3.png) |
| AB2 plié 416 × 657 (zone 208 × 328), images 0 à 3 | OK | 4 bandeaux distincts, feu entier (jalon17b-AB2-plie-image0..3.png) |
| FPS déplié, 10 s animé / 10 s fixe | inchangé | 237,0 (234 à 240) / 236,1 (233 à 238) |
| FPS plié, 10 s animé / 10 s fixe | inchangé | 236,2 (232 à 240) / 235,4 (229 à 240) |

Le prompt indiquait « 416 × 657 déplié » : 416 × 657 donne le mode plié (rapport 1,58), le déplié a été pris à 924 × 1224 comme au jalon 17.

### Z6 (Fold 8, APK 0.17.1, sauvegarde conservée)

| Test | Résultat | Preuve |
|---|---|---|
| Feu animé en plié, au village et en Brume | OUI | Antho : « C'est parfait » |
| Feu animé en déplié | OUI | Antho : « C'est parfait » |
| Après 3 pliages / dépliages, toujours animé, sans saccade ni clignotement | OUI | Antho : « C'est parfait » |
| Rythme | OUI | Antho : « C'est parfait » |

## Jalon 18 (APK 0.18.0)

Premier « gérer » du déplié : onglets PNJ (TD 99) et Village (TT 104, le puits) entre Forge et Options, 6 onglets. Page PNJ : 5 cartes créées une fois dans _ready (lignes VillageText.npc_lines, 3 boutons de cadence pour les producteurs, aide atténuée) ; page Village : atre_lines puis 3 blocs de boutique (shop_lines, 3 postures, aide). Réglage différé : clés optionnelles cadence_next / posture_next, appliquées à la fin du tick (OfflineDag, étape g'), effacées par unpack si inconnues ; OfflineDag.set_next efface l'attente quand on rechoisit la valeur en cours (PROPOSÉ, à valider). Réglages au village seulement, jamais sans sauvegarde ; lecture partout. Noms : après Z7 (5), tirés de la graine (VillageText.npc_identities : un RNG par PNJ « npc/name/i », jamais « npc/i », traits des sauvegardes inchangés ; genre imposé par le sprite via sprite_genders : mineur TD 86 M, aubergiste TD 99 F, forgeron TD 87 M, chevaliers libres ; 5 noms distincts par village ; réservoir de data/village/npcs.json, 30 noms masculins et 30 féminins, chacun 15 vrais prénoms et 15 noms fantasy inventés (demande d'Antho après Z7), le genre suit le nom, rien de sauvegardé ; réservoir PROPOSÉ). Aucune valeur créée. Simulateur : 724 PASS, 0 FAIL (+21).

Export debug le 28/10 : 0 ERROR ; versionCode 20, versionName 0.18.0 ; SHA-256 cd318cc90f4edc5e9013b280424061415e6463032e0b9ebacb77fa580a5ce99c (noms fixes), puis b77cf62ef56bbdbe0bf6a40690bf4c128fb83b63c2c4919fde935eb75db20ffe (noms procéduraux), puis df372fc76397a5641e4843aa6977b4ebd334e6833c3e747ead566796bd734cb3 (noms fantasy mêlés aux vrais prénoms), puis 1a7414a8b6a9de5e2ef8a85aabb271887d3ca419d23ee2e4250dfc6c2e776dff (genre par sprite, bouton grisé sélectionné, même version). Installé par `adb install -r`, sauvegarde du Fold conservée, copie dans build/backup-fold-jalon18/ ; lancement : 0 ERROR (build/captures/jalon18-Z7-logcat.txt).

### AC1 à AC4 (PC 924 × 1224, zone 308 × 408 ; script de capture hors dépôt ; sauvegarde PC restaurée ensuite)

Le prompt indiquait « 416 × 657 déplié » : c'est le format plié, le déplié a été pris à 924 × 1224.

| Test | Résultat | Preuve |
|---|---|---|
| AC1 onglet PNJ, haut puis bas | OK | cartes lisibles, défilement jusqu'à la 5e (jalon18-AC1-pnj-haut.png, jalon18-AC1-pnj-bas.png) |
| AC2 onglet Village | OK | Âtre, 3 boutiques, postures (jalon18-AC2-village.png) |
| AC3 cadence et posture en attente | OK | « Demain : Paisible (…) », Taverne : Exportation allumée, « Demain : Exportation (…) » ; journal [VILLAGE] reglage (jalon18-AC3-*.png) |
| AC4 en Brume | OK | « Réglages au village seulement » en tête, boutons grisés ; correctif : le bouton choisi garde le fond « pressed » une fois grisé, refait (jalon18-AC4-brume-grise.png) |

Aucun Label visible ne passe à la ligne à 308 px.

### Z7 (Fold 8, APK 0.18.0, sauvegarde conservée)

| Test | Résultat | Preuve |
|---|---|---|
| (1) état de chaque PNJ compris sans aide (Moral, activité, outil) | OUI | Antho |
| (2) stock, cible et prix lus dans Village | OUI | Antho |
| (3) « Demain : … » visible après un réglage | OUI | Antho |
| (4) le lendemain, cadence et posture changées | OUI | Antho, constaté le 29/10 |
| (5) noms des PNJ | OUI (après correctifs) | Antho : non sur les noms fixes, puis noms procéduraux, fantasy mêlés aux vrais prénoms, genre par sprite ; oui sur 0.18.0 1a7414a8 |
| Lisibilité à 48 px par tuile | OUI | Antho |


## Jalon 19 (APK 0.19.0)

Postes des PNJ : aptitudes déduites de la graine (scripts/village/assignment.gd, RNG npc/apt/i, rien de sauvegardé), saisir-déposer sur la carte en déplié au village (pose en _unhandled_input, glissé et lâcher en _input comme le joystick : passer sur la fenêtre ne perd pas le PNJ), 4 boutons de poste et « Libérer » dans chaque carte, occupation des postes dans l'onglet Village. Changement de poste et auto-assignation : clés optionnelles post_next / stars_next appliquées au tick avec cadence_next (OfflineDag, étape g'' ; passage en Garde : cadence NORMAL, cadence_next effacée, n°38 Q7b), locked, assign_day ; unpack efface toute valeur invalide. Auto-assignation au lancement et à chaque bascule, juste avant la sauvegarde. Cellule du lâcher comptée comme rect_at (tuile (0, 0) centrée sur l'origine). Constantes techniques PROPOSÉ : NPC_PICK_RADIUS_PX 10, DRAG_MIN_PX 4.

Export debug le 28/10 : 0 ERROR ; versionCode 21, versionName 0.19.0 ; SHA-256 cf67ce954fcd97477bf93b1f244b2b63fa0de62ec43f923a1b8bbe04da12b09d, puis 6682894b16959207f53dcfecdc81abbbd9e42e9b072c528394ab4e5f60c29d9f (cadence NORMAL au passage en Garde, racine nettoyée, même version), puis 726431fa437a15eec3cf67085ef2b1568ccaa234c119eda6c007020f66712565 (page PNJ façon Kairosoft, même version), puis 66db1e1713c6f3f3a10b4bcef5fdb4813242e2814fef1fe62a022d8e664fbe38 (défilement tactile, même version). Aucun appareil branché à l'export : installation par Antho (`adb install -r build/archipel-debug.apk`), sauvegarde du Fold conservée (clés optionnelles, aptitudes déduites de sa graine).

### AD1 à AD5 (PC 924 × 1224, zone 308 × 408, --hour=10 ; script de capture hors dépôt ; sauvegarde PC restaurée ensuite)

Le prompt indiquait « 416 × 657 déplié » : c'est le format plié, le déplié a été pris à 924 × 1224 comme au jalon 18.

| Test | Résultat | Preuve |
|---|---|---|
| AD1 PNJ saisi au doigt au-dessus de la Forge | OK | garde 3 tenu sur la tuile (-5, 0) (jalon19-AD1-saisie-forge.png) |
| AD2 toast après un échange, cartes « Demain : … » | OK | « Kaelys et Lambert échangent demain », « Demain : Garde, 0 étoile », « Poste : verrouillé » ; journal [VILLAGE] poste swap carte (jalon19-AD2-echange-toast.png) |
| AD3 onglet Village, occupation des postes | OK | « Extraction 1/2, Forge 1/1, Taverne 1/1, Garde 2/2 » (jalon19-AD3-village-postes.png) |
| AD4 bouton « Libérer » | OK | visible sous la carte verrouillée (jalon19-AD4-liberer.png) |
| AD5 en Brume | OK | « Réglages au village seulement » en tête, boutons de poste, cadence et « Libérer » grisés, bouton choisi visible (jalon19-AD5-brume-raison.png, jalon19-AD5-brume-grise.png) |

Aucun Label visible ne passe à la ligne à 308 px (ligne la plus large : 277 px).

### Z8 (Fold 8, APK 0.19.0, sauvegarde conservée)

| Test | Résultat | Preuve |
|---|---|---|
| (1) saisir un PNJ sur la carte et le lâcher sur un bâtiment est naturel | OUI | Antho |
| (2) l'échange sur un poste plein est compréhensible | OUI | Antho |
| (3) « Libérer » rend le PNJ à l'auto-assignation | OUI | Antho |
| (4) le lendemain, les PNJ travaillent à leur nouveau poste | OUI | Antho, constaté le 29/10 |
| (5) lignes d'aptitudes lisibles | NON puis OUI | Antho : « brouillon, entassé » -> page PNJ façon Kairosoft (726431fa) |
| Lisibilité à 48 px par tuile | NON puis OUI | idem ; Antho demande un vrai défilement tactile |

Refonte de la page PNJ (Z8 5 et 6) : une ligne par PNJ (sprite Tiny Dungeon de village.json, nom, poste) ; un appui ouvre sa fiche dessous, une seule à la fois (ButtonGroup) ; fiche sur fond léger, intertitres bleu ciel Profil / Poste / Cadence, aptitude sur chaque bouton de poste (« Forge 1 »), Collecte et Négoce fermés en ligne atténuée, attente en vert. Couleurs Okabe-Ito et fond : PROPOSÉ. Correctif : la graine du monde est posée avant le premier affichage (noms et aptitudes faux jusqu'au rafraîchissement suivant). Captures jalon19-AE1-liste.png, jalon19-AE2-fiche-producteur.png, jalon19-AE3-fiche-garde.png.

Défilement tactile (66db1e17) : les boutons et panneaux de la fenêtre défilante passent de STOP à PASS (UiLayer.touch_scroll), le glissé remonte au ScrollContainer. Mesure PC (émulation tactile, fiche ouverte, max 187 px) : glissé de 80 px -> 87 px, inertie jusqu'à 187 ; la ligne glissée ne s'ouvre pas, un appui simple l'ouvre. Vaut pour toutes les pages (Sacoche, Forge, PNJ, Village). Fold : OUI (Antho).

## Jalon 19 bis (APK 0.19.1)

UI seule. Moral coloré : étiquette « Moral N » ou « En grève » enfant du bouton de tête de chaque PNJ (ancrée en haut à droite, mouse_filter IGNORE), couleur par bande de production VText.moral_band (seuils de BalanceB : grève < 20, bas < 50, normal < 85, haut), MORAL_COLORS Okabe-Ito (PROPOSÉ). Onglet Village en lignes dépliables, même construction que la page PNJ (UiLayer._card), ButtonGroup à part : Grand Âtre (tête atre_head, fiche atre_detail + Postes / occupation), Matériaux, Taverne, Forge (tête shop_head avec « demain … » si une posture attend, fiche shop_lines + Posture). shop_lines : 1re ligne « Gérant : X » / « Gérante : X ». atre_lines supprimée. Icône du Grand Âtre : image 0 du feu du bandeau élargie à 16 px (région (0, 0, 16, 16)) pour aligner les textes avec les tuiles roche, tonneau, enclume.

Largeurs mesurées dans Godot (Silkscreen 8) : pire tête « Stock 999/999, Solidaire, demain Exportation » 236 px ; « Esclarmonde » + « Moral 100 » 116 px (sans espace ; le jumeau donne 124) ; autres têtes <= 169 px ; tout sous 264 px.

Export debug le 28/10 : 0 ERROR ; versionCode 22, versionName 0.19.1 ; SHA-256 b3d247d5b4b81b526b9a803fbec8142ff40b1934961673d86b637e41ade6e823. Installé par `adb install -r`, sauvegarde du Fold conservée, copie dans build/backup-fold-jalon19bis/ ; 0 ERROR au lancement.

### AE1 à AE5 (PC 924 × 1224, zone 308 × 408, --hour=10 ; script de capture hors dépôt, Moral 49 / grève / 90 et posture en attente posés en mémoire ; sauvegarde PC restaurée ensuite)

| Test | Résultat | Preuve |
|---|---|---|
| AE1 page PNJ fermée, Moral coloré | OK | blanc 79, orange 49, vermillon « En grève », vert 90 (jalon19bis-AE1-pnj-moral.png) |
| AE2 onglet Village fermé, 4 lignes | OK | feu, roche, tonneau, enclume ; textes alignés (jalon19bis-AE2-village-ferme.png) |
| AE3 Taverne ouverte, posture en attente | OK | « demain Exportation » sur la tête, « Demain : Exportation (…) » dans l'aide (jalon19bis-AE3-taverne-ouverte.png) |
| AE4 Grand Âtre ouvert | OK | rayon, Postes, occupation (jalon19bis-AE4-atre-ouvert.png) |
| AE5 en Brume | OK | raison en tête, postures grisées, choix visible (jalon19bis-AE5-brume-grise.png) |
| Défilement au doigt sur une tête Village | OK | glissé sur la ligne Forge : 54 px de défilement, ligne non ouverte |

### Z9 (Fold 8, APK 0.19.1, sauvegarde conservée)

| Test | Résultat | Preuve |
|---|---|---|
| (1) couleur du Moral lue d'un coup d'œil, « En grève » saute aux yeux | OUI | Antho |
| (2) onglet Village fermé plus clair qu'avant | OUI | Antho |
| (3) ouvrir une ligne et changer une posture est naturel (« demain » sur la ligne) | OUI | Antho |
| (4) défilement au doigt sur Village sans ouverture par erreur | OUI | Antho |

## Jalon 20 (APK 0.20.0)

Charte d'interface (docs/Charte-UI.md) : scripts/ui/ui_style.gd réunit les couleurs par rôle (TEXT, MUTED, TITLE, NEXT, GOOD, BAD, ALERT, SUPERIOR, DETAIL_BG, DETAIL_MARGIN_PX ; MORAL_COLORS et VERDICT_COLORS bâties dessus, mêmes valeurs qu'avant), school_color (lue dans BalanceC) et ICONS (bandeau, onglets, Âtre, boutiques, vocations, emplacements). ui_layer.gd et village_text.gd n'ont plus aucune couleur en dur. _card rend une étiquette d'état (le Moral PNJ passe par elle) ; _line = ligne simple (fond du bouton, icône 16 px centrée, 2 lignes, étiquette dans la rangée, en haut). Perso : Vocations (3 _line, « Rattrapage ×2 » en GOOD), Stats, Équipement (4 _card, Supérieur·e·s en SUPERIOR, fiche = piece_detail, 1re ligne de l'arme en couleur d'École si 3/3, emplacement vide = empty_detail). Sacoche : Cendre, Éclats (fiche par ilvl dans l'ordre de next_index), coffre, puis Purifier. sacoche_lines supprimée. 5 icônes DB32 CC0 (assets/icons/items/), sha256 vérifiés, import par défaut identique à item_gem_quartz (filtre Nearest du projet).

Largeurs mesurées dans Godot : têtes + étiquette 197 px au plus, fiches 212 px au plus (identiques au jumeau).

Export debug le 28/10 : 0 ERROR ; versionCode 23, versionName 0.20.0 ; SHA-256 a0b206182fb4c2ffde164d650eeb4c2023dab618b891b2cb5cce339b6fd27429. Installé par `adb install -r`, sauvegarde du Fold conservée, copie dans build/backup-fold-jalon20/ ; 0 ERROR au lancement.

### AF1 à AF5 (PC 924 × 1224, zone 308 × 408, --hour=10 ; script de capture hors dépôt, XP, pièces, Éclats et Moral posés en mémoire ; sauvegarde PC restaurée ensuite)

| Test | Résultat | Preuve |
|---|---|---|
| AF1 Perso fermé, rattrapage visible | OK | 2 « Rattrapage ×2 » en vert sur la ligne du nom (jalon20-AF1-perso-ferme.png) |
| AF2 Arme ouverte, Enclume 3/3 en couleur | OK | ligne « Enclume 3/3, ATK d'arme … » en #E69F00 (jalon20-AF2-arme-ouverte.png) |
| AF3 emplacement vide ouvert | OK | « Forge-le à la Forge, ou purifie un Éclat » (jalon20-AF3-emplacement-vide.png) |
| AF4 Sacoche, Éclats ouverts | OK | 2 d'Élite ilvl 6 (en premier), 1 ilvl 4, 2 ilvl 3 (jalon20-AF4-sacoche-eclats.png) |
| AF5 PNJ et Village inchangés | OK | fenêtre identique au jalon 19 bis (écart max 1/255 sur quelques centaines de pixels : la carte vue à travers le fond translucide) (jalon20-AF5-pnj.png, jalon20-AF5-village.png) |

### Z10 (Fold 8, APK 0.20.0, sauvegarde conservée)

| Test | Résultat | Preuve |
|---|---|---|
| (1) Perso se lit d'un coup d'œil (vocations, rattrapage, pièces) | à tester | |
| (2) icônes d'équipement DB32 assorties au reste | à tester | |
| (3) liste des Éclats par ilvl utile | à tester | |
| (4) PNJ, Village et bandeau inchangés | à tester | |
| (5) ouvrir une pièce puis glisser pour défiler est naturel | à tester | |
