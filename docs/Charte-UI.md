# Charte d'interface — Archipel des Cendres Tièdes

Version 1, 28/10/2026. Elle part du modèle validé sur Fold aux jalons 19 et 19 bis (onglets PNJ et Village, « façon Kairosoft »).
Toutes les constantes visuelles restent « techniques, PROPOSÉ » jusqu'à leur validation sur Fold. Aucune valeur de jeu ici : les seuils et les nombres sont lus dans BalanceA, B, C, D et F.

## 1. Couleurs par rôle

Une constante par rôle, toutes dans `scripts/ui/ui_style.gd`. Aucune couleur n'est écrite ailleurs. Palette Okabe-Ito, lisible par les daltoniens.

| Rôle | Constante | Valeur | Usage |
|---|---|---|---|
| Texte | `TEXT` | blanc | texte courant, état neutre |
| Secondaire | `MUTED` | blanc à 60 % | raisons de grisé, aides, résumés |
| Titre | `TITLE` | #56B4E9 | intertitres de section |
| Attente | `NEXT` | #009E73 | « Demain : … », « demain X » sur une tête |
| Bon | `GOOD` | #009E73 | meilleure pièce, Moral haut, rattrapage actif, gain |
| Mauvais | `BAD` | #D55E00 | moins bonne pièce, grève, perte |
| Alerte | `ALERT` | #E69F00 | Moral bas, manque proche |
| Qualité Supérieure | `SUPERIOR` | #E69F00 | étiquette « Supérieure » |
| Fond de fiche | `DETAIL_BG` | blanc à 6 %, marge 4 px | panneau sous une tête ouverte |

Tables dérivées, construites sur les rôles :
- `MORAL_COLORS` : STRIKE → BAD, LOW → ALERT, NORMAL → TEXT, HIGH → GOOD (validé sur Fold, jalon 19 bis) ;
- `VERDICT_COLORS` : 1 → GOOD, -1 → BAD, 0 → TEXT.

Règles :
- **La couleur ne porte jamais seule le sens.** Il y a toujours un mot à côté : « En grève », « Rattrapage ×2 », « Meilleure que l'équipée », « Supérieure ».
- Attente et Bon partagent le vert, et Alerte et Qualité Supérieure partagent l'orange. Ce sont des rôles distincts, qui ne se croisent jamais sur un même élément. Si l'un change, l'autre ne bouge pas.

### Couleurs d'École (données de jeu, pas de l'UI)
- Elles existent déjà dans `BalanceC.SCHOOL_DATA[id]["color_hex"]`, validées au Volet C : Foyer (Enclume) #E69F00, Spore #009E73, Brasier #FF7A1A, Abysse #56B4E9, Obsidienne #CC79A7.
- L'UI les lit par `UiStyle.school_color(id)`, sans les recopier.
- Elles colorent seulement le nom d'École sur une pièce (« Enclume 3/3 »), et seulement quand les 3 Écoles sont identiques. Sinon, le texte reste en TEXT.
- Remarque pour Argon, non bloquante : Enclume (#E69F00) et Brasier (#FF7A1A) sont proches l'un de l'autre. Le nom écrit lève l'ambiguïté.

### Rareté des pièces
- Il n'y a pas de couleur de rareté en tranche : le mot suffit (Commune, Bonne, Rare). Les 3 raretés de la tranche n'ont pas besoin d'un code couleur, et toute couleur de rareté entrerait en collision avec celles des Écoles.
- Si on en veut une plus tard, avec Épique et Légendaire, la question passe par Argon : c'est une convention de genre, qui touche au sens du jeu.

## 2. Grammaire des écrans

| Besoin | Élément | Fonction |
|---|---|---|
| Un objet qui a des détails ou des réglages (PNJ, boutique, pièce, Éclats) | **ligne dépliable** : tête à bascule (icône 16 px, 2 lignes, étiquette d'état à droite), fiche dessous | `_card` |
| Un objet sans détail (vocation, Cendre, coffre) | **ligne simple** : même rendu qu'une tête fermée, sans bascule | `_line` |
| Un choix exclusif parmi 2 à 4 valeurs (poste, cadence, posture, mode de craft) | **rangée de choix** : boutons à bascule, choix en cours enfoncé, aide en MUTED dessous | `_block` |
| Découper une fiche ou une page | **intertitre** en TITLE | `_section` |
| Une action principale de page (Purifier, Forger) | **bouton d'action** en bas de la page, avec sa raison en MUTED juste dessous s'il est grisé | — |
| Une décision qui bloque tout le reste (Équiper ou Jeter) | **carte plein écran** : onglets grisés jusqu'au choix | Apercu |
| Un retour bref, sans décision (montée de niveau, changement de poste) | **toast** de 2,5 s, qui ne bloque rien | `show_toast` |

Règles communes :
- Une seule fiche ouverte par page (ButtonGroup allow_unpress), et toutes fermées au lancement.
- Défilement au doigt partout (`touch_scroll`) : un glissé fait défiler, un appui ouvre.
- Grisé : une raison qui grise toute la page va en tête de page. La raison d'un seul bouton va juste sous ce bouton. Le bouton choisi garde son fond « pressed ».
- Tout est créé une fois dans `_ready`. Les `show_*` ne changent que des textes, des couleurs, des états et la visibilité.

## 3. Iconographie

Une icône par notion, déclarée une seule fois dans `UiStyle.ICONS` (notion → planche + région). Toutes en 16 × 16, au contour sombre épais.

| Notion | Icône | Source |
|---|---|---|
| Or | coin_05d | Kyrise, CC-BY 4.0 (dans le dépôt) |
| Cendre, Grand Âtre | campfire, image 0 (animée dans le bandeau) | krial, CC0 (dans le dépôt) |
| Éclat | item_gem_quartz | DB32, CC0 (dans le dépôt) |
| Minerai, coffre | filon de cuivre | senmou, CC0 (dans le dépôt) |
| Onglets Perso, Sacoche, Forge, PNJ, Village, Options | TD 112, TT 107, TD 74, TD 99, TT 104, TT 83 | Kenney, CC0 |
| PNJ | leur sprite du village | Kenney, CC0 |
| Matériaux, Taverne, Forge (boutique) | roche, tonneau, enclume | Kenney, CC0 |
| Combattant | TD 112 (le héros) | Kenney, CC0 |
| Mineur | pickaxe_iron | **DB32, CC0, NOUVEAU** |
| Forgeron | TD 74 (enclume) | Kenney, CC0 |
| Arme | sword_iron | **DB32, CC0, NOUVEAU** |
| Casque | armor_helmet_iron | **DB32, CC0, NOUVEAU** |
| Plastron | armor_chest_iron | **DB32, CC0, NOUVEAU** |
| Bottes | armor_boots_iron | **DB32, CC0, NOUVEAU** |

- Les icônes NOUVEAU viennent du même pack que l'Éclat du bandeau : 16x16 RPG Items (DB32), aroachifoundonmypillow, CC0, https://opengameart.org/content/16x16-rpg-items-db32.
- Les planches Kenney n'ont ni casque, ni plastron, ni bottes.
- Chaque nouvel asset demande l'accord d'Antho et une ligne dans ASSETS.md, dans le même commit.
- Les Écoles n'ont pas d'icône : leur nom écrit en couleur suffit en tranche.

## 4. Textes

- **Boutons = verbe d'action** : « Purifier un Éclat », « Forger l'Arme », « Équiper », « Jeter », « Libérer ». Les noms seuls sont réservés aux onglets.
- **Nombres** :
  - entiers avec une espace insécable (U+00A0) tous les 3 chiffres : « 1 150 », « 715 400 » (`EqText.num`) ;
  - décimales à la virgule ;
  - pourcentages « 5 % », multiplicateurs « ×1,5 » ;
  - signe « - » (U+2212 absent de Silkscreen).
- **Capacités et stocks** : « a/b » sans espace (« Cendre 120/150 », « Stock 0/69 »). Pour l'XP, « a / b XP », avec des espaces, parce que les nombres ont des séparateurs de milliers.
- **Unités** après le nombre : « 12 Or », « 4 minerais », « 25,8 kg ». Pluriel par `plural`.
- **Genre et nombre** par jetons M / F / FP :
  - raretés accordées (« Commune », « Bon », « Rares ») ;
  - articles élidés (« l'Arme », « les Bottes ») ;
  - pronoms (« Forge-la », « Forge-le », « Forge-les ») ;
  - gérant ou gérante, endormi ou endormie.
- **Glyphes absents de Silkscreen** : ★, U+2212, →, U+202F. Les étoiles s'écrivent en toutes lettres (« 2 étoiles »).

## 5. Lisibilité

- 2 lignes au plus par tête : le nom d'abord, puis le résumé le plus utile.
- Une information par ligne, la plus importante en premier.
- L'état en couleur va à droite de la tête, sur la ligne du nom, en mouse_filter IGNORE.
- Largeur utile 296 px. Texte de tête, étiquette comprise, ≤ 264 px. Texte de fiche ≤ 288 px. Chaque jalon a un jumeau Python qui mesure ses textes en Silkscreen 8.
- Plié = un pouce : pas de cible de moins de 16 px de viewport, un toast plié tient sur une ligne (180 px de large), bandeau à icônes seules plus valeur.
