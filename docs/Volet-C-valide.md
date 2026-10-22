# Volet C validé — Les 5 Écoles de Forge, armes modulaires, affixes

Validé le 22/10/2026 après les échanges n°16 à n°21 (Claude ↔ Argon). Chaque valeur a été vérifiée par script (`volet-c/scripts/prep_n16.py`, `audit_n16.py`, `audit_n18.py`, `audit_n20.py`). Les constantes sont dans `balance_c.gd`. Priorité : SOCLE v2 > Volets A et B > ce document > Journal.

## 1. Les 5 Écoles (armes seulement, pas d'armure)

| École | Isolat d'origine | Élément | Teinte (contraste sur #3A3D42) | Poinçon | Part offensive |
| --- | --- | --- | --- | --- | --- |
| L'Enclume de Clair-Foyer (F, élision) | 1 Clair-Foyer | Neutre | #E69F00 (4,84) | Enclume | 0,50 |
| Le Mycélium des Tourbières (M) | 2 Tourbière des Lanternes | Neutre | #009E73 (3,19) | Fiole & Spore | 0,55 |
| Le Brasier de Pic-Forgez (M) | 3 Pic-Forgez | Braise | #FF7A1A (4,18) | Flamme double | 0,60 |
| Le Harpon de Port-Sardine (M) | 4 Port-Sardine | Givre | #56B4E9 (4,73) | Harpon crochu | 0,65 |
| Le Sceau d'Obsidienne (M, sans élision) | 5 Citadelle d'Obsidienne | Neutre | #CC79A7 (3,56) | Clef de voûte | 0,40 |

- Tranche verticale : Enclume + Brasier (70 / 30), raretés Commun / Bon / Rare. Poinçon Foyer au jour 1, Brasier au rang 1 de son Contrat.
- Drop de l'École de la Lame par isolat (Foyer / Brasier / Spore / Abysse / Obsidienne) : 55/20/15/5/5, 20/10/55/10/5, 15/55/10/10/10, 10/10/15/55/10, 10/10/10/15/55. Garde et Pommeau suivent la Lame à 70 % (49 % d'armes 3/3).
- Bonus 3/3 : +3,5 % sur ATK_arme seule, aucun palier 2/3. Remplace WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS de balance_a.gd.

## 2. Armes

- 5 types : Épée & Écu (40 px), Hache d'Entaille (44 px), Vouge d'Éclaireur (52 px) en mêlée à 1,2 coup/s ; Arc de Chasse (160 px), Arbalète à Treuil (180 px) à 1,0 coup/s.
- 3 pièces : Lame 60 % d'ATK_arme + élément implicite + slots 1 et 4 ; Garde 25 % + slot 2 ; Pommeau 15 % + slot 3. La Lame n'est jamais remplaçable.
- Remontage de pièce (Garde ou Pommeau, même type d'arme, donneuse détruite) : 24 × M_isolat Or détruits, 2 minerais, 0 Cendre Vive. L'arme garde ses affixes et son budget. Distinct de la greffe d'affixe du Volet A.

## 3. Affixes (12)

- Combat : FLAT_ATK 0,5 ATK / pt, FLAT_HP 3 PV / pt, FLAT_DEF 0,55 DEF / pt ; PCT_ATK (% d'ATK_arme) 0,46 S, PCT_ASPD 0,90 S, PCT_CRIT_CHANCE 0,55 S, PCT_CRIT_DMG 0,18 S, avec plafonds par pièce / globaux +6 / +20 %, +4 / +12 %, +4 / +12 %, +10 / +30 %. S(ilvl) = B(ilvl, Commun) / 12.
- Implicite : ELEM_DMG sur la Lame (0 pt).
- Utilitaires hors IC : MOVE_SPEED (+12 %), CARGO_CAP (+6 kg), MINE_YIELD (+15 %, minage manuel en expédition), GATHER_YIELD (+15 %, inactif en tranche).
- Part max de B par affixe : 100 / 60 / 50 / 45 % pour 1 / 2 / 3 / 4 affixes (Commun / Bon / Rare / Épique et Légendaire).
- Identité d'une École = ses poids de tirage par affixe (voir balance_c.gd).

## 4. Preuves

- Plafond d'IC (4 Légendaires + 3/3 contre 4 Communs optimaux, build optimal par recherche) : 1,350 / 1,347 / 1,350 à ilvl 1 / 25 / 50.
- Équité (arme Rare selon les poids, armures à l'optimum) : écart max 1,17 / 1,26 / 1,30 %, Abysse −1,00 % contre Foyer à ilvl 50. Accepté par Antho (tolérance visée 1 %).
- Éléments : isolat 1 neutre, isolats 2 à 5 à 50 / 25 / 25 (neutre / lié au Givre / lié à la Braise), E = 1,0125 pour une arme élémentaire. Changement d'arme au Village et au Brasero seulement.

## 5. Systèmes

- Héritage : affixe nommé d'après un PNJ, raretés Rare et plus, +15 % sur un affixe utilitaire de la pièce, hors IC.
- Contrats d'École : +10 par craft, +5 par recyclage, +5 par vente ; rangs à 100 / 300 / 700 / 1 300 / 2 200 : Poinçon, façade de boutique, patine, trophée et titre, −50 % sur le remontage. Aucune pity, aucun Moral, aucun Or ni XP créé.
- Préférence d'École des PNJ : narrative seulement (souvenir, sprite), 0 Moral.
- Éclats Voilés : École et rareté cachées jusqu'à purification.

## 6. Intégration (Claude Code, sans changer de valeur)

- balance_c.gd consolidé par Claude : valeurs du n°16 pour les drops et les types d'arme (les tables du n°20 sont écartées), fonctions écrites à partir des constantes de BalanceA (les fonctions BalanceA.get_* appelées par Argon n'existent pas), pas de floor().
- Retirer WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS de balance_a.gd. Le test INFO du jalon 1 devient un test : ratio optimal avec 0,035 ≤ 1,40.
- Les noms affichés (Écoles, armes, pièces, lore) vont dans data/ avec leurs jetons grammaticaux.
