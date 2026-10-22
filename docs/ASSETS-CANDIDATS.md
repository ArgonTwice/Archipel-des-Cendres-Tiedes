# ASSETS-CANDIDATS — recherche du 2026-10-22

Statut : **brouillon non validé**. Rien n'est téléchargé, rien n'est dans `ASSETS.md`. Aucune valeur de ce document ne remplace la vérification de la page du pack juste avant l'import.

Légende : ✅ vérifié sur la page de l'asset · ⚠️ partiel (licence vue, contenu non détaillé par la page) · ❌ non vérifiable (accès bloqué) — **un ❌ ne peut pas être retenu tant que la licence n'est pas lue par Antho**.

Contexte lu : CLAUDE.md, SOCLE-v2 A1 (cosy mais sombre), A2 (5 isolats), A3 (portrait, pouce), A5 (75 sprites d'armes 64×64, mêlée + arc/arbalète).

> **Alerte cohérence (valable partout)** : le projet vise tuiles 16×16 / persos 16×24. Les packs Kenney sont en 16×16 mais d'un style « plat et propre » ; les packs 32×32 (ex. Dungeon Crawl) ne se mélangent pas sans redimensionnement 2× qui casse les pixels. Mixer tailles ou styles est la première cause d'incohérence.

---

## 1. Tuiles village + intérieurs / biomes

| Candidat | Auteur | URL | Licence | Tuile | Contenu | Attribution | Statut |
|---|---|---|---|---|---|---|---|
| Tiny Town | Kenney | https://kenney.nl/assets/tiny-town | CC0 (https://creativecommons.org/publicdomain/zero/1.0/) | 16×16 | « 130× » fichiers (non précisé), spritesheet + tuiles | Non | ✅ licence/taille ; ⚠️ formats/poids |
| Tiny Dungeon | Kenney | https://kenney.nl/assets/tiny-dungeon | CC0 | 16×16 | 130 fichiers (idem), donjon/intérieurs, persos et monstres | Non | ✅ licence/taille ; ⚠️ le reste |
| Roguelike/RPG pack | Kenney | https://kenney.nl/assets/roguelike-rpg-pack | CC0 | 16×16 | « 1700× » (non précisé) | Non | ✅ licence/taille ; ⚠️ le reste |
| Ninja Adventure | pixel-boy | https://pixel-boy.itch.io/ninja-adventure-asset-pack | **inconnue pour moi** (page derrière Cloudflare, 403) | 16×16 (à confirmer) | gros pack tuiles+persos+monstres+audio (à confirmer) | ? | ❌ **à lire par Antho** |

Notes : Tiny Town (village) + Tiny Dungeon (intérieurs, monstres) sont conçus pour s'accorder (même auteur, même grille). Biomes forêt / marais / volcan / port glacé / citadelle : **non vérifiés** pack par pack ; Roguelike/RPG couvre herbe, arbres, eau, neige probablement, mais je n'ai pas pu lister son contenu. Marais, volcan et citadelle : probablement à recolorer (palette) — voir manques.

## 2. Personnages (joueur + PNJ)

| Candidat | Auteur | URL | Licence | Taille | Contenu | Attribution | Statut |
|---|---|---|---|---|---|---|---|
| Puny Characters | Shade | https://opengameart.org/content/puny-characters | CC0 | base 16×16 sur canevas 32×32 | 8 directions : idle, marche, attaque épée/arc/bâton, lancer, dégât, mort ; 236 Ko (510 Ko avec orcs) | Non | ✅ |
| Surtizens | pebonius | https://opengameart.org/content/surtizens | CC0 | 16×16 | vieil humain, lunettes, etc. + chien, grenouille, canard, orc, gobelin, minotaure ; 38,8 Ko | Non | ✅ (petit) |
| Tiny Dungeon (persos) | Kenney | voir §1 | CC0 | 16×16 | quelques héros/monstres | Non | ⚠️ |

**Écart** : le cahier des charges demande 16×24 ; aucun candidat vérifié n'est en 16×24 (Puny = canevas 32×32). Décision d'Antho requise (voir questions).

## 3. Monstres (loups d'ombre, givre)

| Candidat | Licence | Taille | Remarque | Statut |
|---|---|---|---|---|
| Tiny Dungeon (Kenney) | CC0 | 16×16 | monstres génériques, pas de loup confirmé | ⚠️ |
| Puny Characters + orcs | CC0 | 16×16/32 | humanoïdes seulement | ✅ |
| Surtizens | CC0 | 16×16 | quelques créatures | ✅ |

Aucun loup d'ombre / créature de givre vérifié → **manque**, à recolorer ou créer.

## 4. Armes (75 sprites 64×64, modulaires lame/garde/pommeau, branche/corde/poignée)

| Candidat | Auteur | URL | Licence | Taille | Contenu | Statut |
|---|---|---|---|---|---|---|
| Wesnoth Items | Blarumyrran | https://opengameart.org/content/wesnoth-items | CC0 (déclaré sur la page ; « most Wesnoth assets are not in public domain; these are ») | non précisée | 42 objets : épées, 10 armes à distance, bâtons, etc. | ✅ licence ; ⚠️ taille ; **risque** : vérifier que chaque fichier est bien de ce pack |
| 5 RPG / Fantasy Weapons | Cerbion | recherche OGA | CC0 (d'après la recherche, page non ouverte) | 16×16 | épée, hache, arc, bâton | ⚠️ non vérifié sur la page |
| CC0 Ranged Icons | AntumDeluge | https://opengameart.org/content/cc0-ranged-icons | CC0 (page non ouverte ; compilation de plusieurs sources) | 32×32 (+ 24, 48) | arcs/arbalètes | ⚠️ compilation → vérifier chaque source |

Aucun kit **modulaire** trouvé. 64×64 × 75 pièces = création maison (voir manques).

## 5. Icônes (objets, ressources, Éclats), UI mobile

| Candidat | Auteur | URL | Licence | Contenu | Statut |
|---|---|---|---|---|---|
| Game Icons | Kenney | https://kenney.nl/assets/game-icons | CC0 | 105 fichiers | ✅ licence/nombre ; style UI générique |
| 1-Bit Pack | Kenney | https://kenney.nl/assets/1-bit-pack | CC0 | 16×16, 1078 « files » | ✅ ; monochrome → ne s'accorde pas avec des tuiles en couleur |
| UI Pack – Pixel Adventure | Kenney | https://kenney.nl/assets/ui-pack-pixel-adventure | CC0 | « 500× » fichiers, boutons/jauges/panneaux pixel | ✅ licence ; ⚠️ taille native non listée |
| Pixel UI Pack | Kenney | https://kenney.nl/assets/pixel-ui-pack | CC0 | 750 fichiers | ✅ |

## 6. Effets (feu, braise, givre, brume)

| Candidat | Licence | Contenu | Statut |
|---|---|---|---|
| Particle Pack (Kenney) — https://kenney.nl/assets/particle-pack | CC0 | 80 fichiers, textures 512×512, **haute résolution** (fumée, étincelles…) → incompatible pixel art brut, utilisable en Godot en shader/particules floutées | ✅ licence ; ⚠️ style |
| Autres (feu/givre pixel) | — | non trouvés/vérifiés | manque |

## 7. Polices FR (accents obligatoires)

| Candidat | Auteur | Licence | Accents | Statut |
|---|---|---|---|---|
| Pixelify Sans | The Pixelify Sans Project Authors (Google Fonts) | OFL-1.1 (d'après Fontsource/Arch, pas la page Google Fonts) | sous-ensemble `latin` + `latin-ext` listé par Fontsource | ⚠️ licence via tiers ; fichier OFL.txt à lire à l'import |
| Kenney Fonts — https://kenney.nl/assets/kenney-fonts | Kenney | CC0, 11 fichiers | **non précisé par la page** — tester é è ê à ç œ avant retenue | ⚠️ |
| Silkscreen (Google Fonts) | — | licence/accents **non vérifiés** (page non exploitable) | ? | ❌ |

## 8. Musique

| Candidat | Auteur | URL | Licence | Détail | Attribution | Statut |
|---|---|---|---|---|---|---|
| Medieval: The Bard's Tale | RandomMind | https://opengameart.org/content/medieval-the-bards-tale | CC0 | MP3 3,8 Mo + loop WAV 10,2 Mo ; luth/flûte paisible (village) | Non | ✅ |
| Incompetech (catalogue) | Kevin MacLeod | https://incompetech.com/music/royalty-free/faq.html | CC BY 4.0 (texte lu sur la FAQ) | morceaux à choisir un par un ; crédit **visible obligatoire** (écran Crédits) : « Titre Kevin MacLeod (incompetech.com) / Licensed under Creative Commons: By Attribution 4.0 / https://creativecommons.org/licenses/by/4.0/ » | **Oui** | ✅ licence ; pistes non choisies |
| Peaceful village loop | elerya | https://opengameart.org/content/peaceful-village-loop | **CC-BY 3.0** (d'après la recherche, non ouvert) | ambiance village | Oui | ⚠️ à rouvrir avant retenue |
| Ambiances sombres (Cendre Grise) | — | « Dark Cavern Ambient » CC0 signalé par recherche, non ouvert | CC0 ? | cave, pas glacial | — | ❌ non vérifié |

## 9. SFX (récolte, forge, combat, UI)

| Candidat | Auteur | URL | Licence | Fichiers | Statut |
|---|---|---|---|---|---|
| RPG Audio | Kenney | https://kenney.nl/assets/rpg-audio | CC0 | 50 (foley, pas, armes) | ✅ |
| Impact Sounds | Kenney | https://kenney.nl/assets/impact-sounds | CC0 | 130 | ✅ |
| Interface Sounds | Kenney | https://kenney.nl/assets/interface-sounds | CC0 | 100 | ✅ |

Formats (OGG/WAV) non indiqués sur les pages ; à constater à l'import. Freesound : **aucun fichier sélectionné** (licences CC0/CC-BY/NC mêlées, à examiner un par un).

---

## Combos cohérents

**Combo A — « Kenney pur » (recommandé)** : Tiny Town + Tiny Dungeon (+ Roguelike/RPG pour biomes) + Kenney Pixel UI / UI Pack Pixel Adventure + Game Icons + Kenney Fonts + RPG Audio / Impact / Interface Sounds + musique CC0 RandomMind (+ éventuellement Incompetech, CC-BY).
- Points forts : tout CC0 sauf Incompetech, même grille 16×16, un seul auteur pour tuiles/UI/SFX = cohérence maximale, aucune attribution obligatoire (hors Incompetech).
- Points faibles : style propre, peu « sombre/cosy WoW » ; persos en 16×16 (pas 16×24) ; il faudra recolorer pour la Cendre Grise.

**Combo B — « Kenney + persos OGA »** : tuiles Kenney (Tiny Town/Dungeon) + Puny Characters (persos 8 directions, armes arc/épée animées) + Surtizens (PNJ) + Wesnoth Items (armes) + Pixelify Sans + audio Kenney + musique RandomMind.
- Points forts : persos plus riches (8 directions, animations d'attaque), police pixel.
- Points faibles : **mélange d'auteurs** (Kenney plat vs Shade) → risque de style disparate ; Puny sur canevas 32×32 ; Wesnoth Items de taille inconnue.

**Recommandation : Combo A**, pour la cohérence, avec la tuile 16×16 verrouillée. Combo B seulement si Antho accepte un test visuel côte à côte avant de s'engager.

## Manques (gratuit introuvable ou non vérifié → création/adaptation)

1. 75 sprites d'armes 64×64 modulaires (5 types × 5 écoles × 3 pièces) : à créer ; les packs trouvés sont 16–32 px non modulaires.
2. Personnages 16×24 : aucun candidat vérifié.
3. Loups d'ombre, monstres de givre, boss (Seigneurs du Givre-Noir, Roi Sans-Flamme).
4. Tuiles marais, montagne volcanique, port glacé, citadelle sombre : non vérifiées, probablement recoloration de Kenney.
5. Effets pixel de brume / givre / braise (le Particle Pack Kenney est 512×512).
6. Ambiances sombres glaciales (musique) ; SFX de forge spécifiques (Freesound à examiner).
7. Icônes des Éclats et des ressources propres au jeu.
8. Silhouettes des 625 combinaisons + shaders de rareté : code/Godot, pas un asset.

## Risques de licence

1. **Ninja Adventure (itch.io)** : licence non lue (page bloquée). Ne pas l'utiliser sans lecture directe par Antho, même si elle est souvent citée comme CC0.
2. **Compilations OGA / Wesnoth Items / CC0 Ranged Icons** : une page « CC0 » peut regrouper des sources hétérogènes ; vérifier les fichiers (et les commentaires de la page) un par un.
3. **Incompetech et Peaceful village loop (CC-BY)** : attribution visible obligatoire dans l'écran Crédits (CLAUDE.md : acceptées, mais à tracer dans ASSETS.md).
4. **Pixelify Sans** : OFL confirmée via des tiers, pas la page Google Fonts ; lire le fichier OFL.txt livré avant import.
5. Les pages Kenney ne mentionnent pas d'auteur dans le champ renvoyé ; l'auteur est « Kenney » (kenney.nl) — à noter tel quel dans ASSETS.md.
6. Formats et poids non confirmés pour la plupart des packs Kenney.

## Limites de cette recherche

- itch.io (Cloudflare 403) et plusieurs pages Google Fonts étaient inexploitables : tout candidat itch.io est marqué ❌.
- Freesound et OpenGameArt n'ont été explorés que par recherche : seules les pages marquées ✅ ont été ouvertes.
- Le style réel (aperçu visuel) n'a pas été vu : la compatibilité entre packs est une estimation (taille de grille + auteur), pas une vérification visuelle.
