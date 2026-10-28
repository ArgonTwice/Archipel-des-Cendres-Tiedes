# Volet D validé — Vie du village de la tranche verticale

Validé le 23/10/2026 après les échanges n°22 à n°24 (Claude ↔ Argon, réflexion Élevé, règles R1 à R6). Chaque valeur a été vérifiée par script (`volet-d/scripts/prep_n22.py`, `audit_n22.py`). Les constantes sont dans `balance_d.gd`. Priorité : SOCLE v2 > Volets A, B et C > ce document > Journal. Le Volet D ajoute des constantes, il ne modifie aucune valeur de A, B ou C.

## 1. Lien (0 à 1000) et Réputation

| Palier | Seuil | Nom | Effet |
| --- | --- | --- | --- |
| 0 | 0 | Inconnu | Amnésique |
| 1 | 100 | Connaissance | Souvenir 1/5 |
| 2 | 250 | Compagnon | Souvenir 2/5, compte pour la synergie des suiveurs |
| 3 | 450 | Ami | Souvenir 3/5 |
| 4 | 700 | Confident | Souvenir 4/5, le gérant renomme sa boutique |
| 5 | 1000 | Frère de Braise | Souvenir 5/5, son nom peut signer un affixe d'Héritage |

- Synergie : une paire de suiveurs compte dans N_liens si les deux ont au moins 250 de Lien, et seulement tant que la flamme est au-dessus de l'Oubli 2.
- Gains : cadeau 24 (cooldown 3 j par PNJ), Coup de feu choix Amitié 12 (1 par jour), expédition comme suiveur 8 (2 par jour), mission déléguée 4, fiche 10 (5 si déléguée, 2 par jour), Alerte de Sauvetage réussie 30, Veillée 10.
- Équivalence : 1,50 Or = 1 point de Lien (18 Or du comptoir = 12 Lien).
- Aucune perte de Lien, ni hors-ligne ni en session. La Réputation est fusionnée dans le Lien de l'émetteur.
- Rythme (jours pour chaque palier, 1 PNJ favori / les 5) : Régulier J+4 / 8 / 14 / 22 / 31 et J+10 / 24 / 42 / 65 / 93 ; Pause Café J+10 / 24 / 43 / 67 / 96 et J+30 / 74 / 133 / 206 / 295 ; Assidu J+3 / 8 / 14 / 21 / 30 et J+5 / 13 / 23 / 35 / 50. Pause Café et Assidu prennent l'Or au comptoir, comme au Volet B.

## 2. Traits (1 ou 2 par PNJ, 50 / 50)

| Trait | Poids | Production | Moral par tick | Autre | Incompatible avec |
| --- | --- | --- | --- | --- | --- |
| Noctambule | 15 | ×1,00 | 0 | Travaille 20 h – 07 h | — |
| Costaud | 20 | ×1,05 | 0 | Cargaison ×1,30 (Volet A) | — |
| Perfectionniste | 15 | ×0,90 | +1 | Usure d'outil ×0,75 | Tête-en-l'air, Bosseur |
| Tête-en-l'air | 15 | ×0,90 | +2 | 10 % d'oubli en session, espérance hors-ligne | Perfectionniste, Bosseur |
| Bosseur | 20 | ×1,10 | −1 | — | Perfectionniste, Tête-en-l'air |
| Bout-en-train | 15 | ×1,00 | +2 | — | — |

- M_trait de 0,90 à 1,155 ; Moral par tick de −1 à +4. Points fixes de Moral en Normal : 78 (pire tirage) à 94 (meilleur, production ×1,15).
- Aucun effet sur l'équipement du joueur, l'XP, la Cendre Vive ou l'Or. Le circuit du Volet B tient au pire tirage (Extraction 45 u/j pour 40 u/j de besoin).

## 3. Griffe de l'artisan (trait principal du gérant)

| Trait du gérant | Griffe | Effet |
| --- | --- | --- |
| Noctambule | Lanterne de Veille | Boutique ouverte 24 h / 24, +3 Lien par fiche émise |
| Costaud | Charpente Renforcée | Stock max ×1,15 |
| Perfectionniste | Comptoir Méticuleux | +4 Lien par cadeau |
| Tête-en-l'air | Tarif Étourdi | Prix max ×1,15 au lieu de ×1,25 (gain d'arbitrage max −1 Or sur les 5 isolats) |
| Bosseur | Service Express | +3 Lien sur le choix Amitié du Coup de feu |
| Bout-en-train | Auberge Chaleureuse | +2 Moral à tous les PNJ par tick (non cumulable) : point fixe Normal 86, Forge ardente 42 |

## 4. Jour et nuit

- Heure locale réelle (fuseau mémorisé). Aube 6 h, jour 8 h, crépuscule 19 h, nuit 22 h.
- Chaque PNJ travaille 10 h par jour : 8 h – 13 h et 14 h – 19 h, ou 20 h – 01 h et 02 h – 07 h pour un Noctambule.
- Boutiques ouvertes de 8 h à 22 h. La nuit, la Cloche de Garde ouvre le comptoir au joueur sans malus ni surcoût, Coup de feu compris. Le tableau est ouvert en permanence.
- Aucun flux du Volet B ne dépend de l'heure : tout se calcule par day_index et t_eff.

## 5. Lanterne-Mère

| Niveau | Cendre Vive | Sacoche | Isolat | Vocation max | Braises | Charbon | Or |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 150 | 6 | 1 | 1 | 0 | 0 | 0 |
| 2 | 220 | 8 | 1 | 5 | 90 | 10 | 0 |
| 3 | 300 | 10 | 2 | 15 | 300 | 25 | 0 |
| 4 | 400 | 12 | 3 | 25 | 600 | 50 | 0 |
| 5 | 500 | 15 | 4 | 35 | 1 050 | 80 | 0 |

- Tranche : niveaux 1 et 2. Jours d'atteinte : Régulier J+6 / 26 / 66 / 136 ; Assidu J+3 / 13 / 39 / 98 ; Pause Café (100 % forge) J+12 / 52 / 132 / 281.
- Les Braises servent aussi à accélérer les chantiers : c'est un choix du joueur.

## 6. Grand Âtre

| Niveau | Rayon (tuiles) | Postes | PNJ max | Coût depuis le niveau précédent | Chantier |
| --- | --- | --- | --- | --- | --- |
| 1 | 12 | 6 | 5 | — | — |
| 2 | 18 | 10 | 10 (5 en tranche) | 600 Or + 40 minerais + 40 Tier 0 | 240 min |
| 3 | 24 | 16 | 16 | 2 400 Or + 80 + 80 | 240 min |
| 4 | 30 | 23 | 23 | 5 400 Or + 120 + 120 | 540 min |
| 5 | 36 | 30 | 30 | 9 600 Or + 160 + 160 | 960 min |

- Auto-assignation (en session seulement) = Affinité (1,00, +0,15 métier favori, +0,10 trait adapté, max 1,25) × Besoin (2,00 − 1,50 × remplissage du stock ; 0,10 stock plein ; 1,00 pour un garde) × Aptitude (0,60 + 0,20 × étoiles).

## 7. Intégration (Claude Code, sans changer de valeur)

- balance_d.gd consolidé par Claude : Griffe du n°23, coûts de l'Âtre au-delà du Nv2 nommés dans D (ATRE_UPGRADE_*_PER_LVL), pas de fonction de prix en doublon.
- Prix avec Griffe : ajouter un paramètre price_mult_max à sell_price de scripts/economy.gd (défaut BalanceB.PRICE_MULT_MAX). Le test d'anti-arbitrage couvre aussi 1,15.
- Le jalon 2 (DAG hors-ligne + grève) lit M_trait par get_npc_trait_prod_mult et le Moral des traits et de la Griffe dans le tick unique.
- Noms affichés (paliers, traits, enseignes) dans data/ avec leurs jetons grammaticaux.

## 8. Complément n°38 (28/10/2026)

- Aptitudes secondaires des 5 PNJ de départ plafonnées à 1 étoile, poids {0 : 60, 1 : 40} ; principale = 2 étoiles.
- Métier favori = poste de départ.
- Postes Nv1 : EXTRACTION 2, FORGE 1, TAVERN 1, GUARD 2 (Nv2 : 3, 2, 2, 3) ; GATHER et MERCHANT fermés en tranche.
- Le gérant garde sa gérance et sa Griffe quand il change de poste ; changement gratuit.
- Auto-assignation en session, différée au prochain tick, 1 changement par PNJ et par jour au plus, gain minimal 0,25.
