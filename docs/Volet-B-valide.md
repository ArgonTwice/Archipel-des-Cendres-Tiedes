# Volet B validé — Économie du village, hors-ligne, Moral, logistique

Validé le 22/10/2026 après les échanges n°11 à n°14 (Claude ↔ Argon). Chaque valeur a été vérifiée par script (`volet-b/scripts/audit_n11.py` à `audit_n14.py`). Les constantes sont dans `balance_b.gd`. Priorité : SOCLE v2 > ce document > Journal.

## 1. Production des PNJ
- V = Prod_base × (0,60 + 0,20 E) × M_cad × M_moral × M_usure × M_trait. Prod_base : Extraction 5,0 / Forge 2,5 / Taverne 3,0 u/h.
- Cadence : Paisible 0,80 / Normal 1,00 / Forge ardente 1,30. Moral : grève 0, 20–49 : 0,75, 50–84 : 1,00, ≥ 85 : 1,15. Outil brisé 0,60.
- 5 PNJ de départ à 2★ : 3 gérants (Forge, Taverne, Matériaux), 2 gardes-éclaireurs.

## 2. Hors-ligne O(1)
- t_eff = min(t, 12 h), 0 si l'horloge recule de plus de 60 s. Rendement 0,60, Glanage 0,25. Au-delà de 12 h : stase douce (aucun tick, aucun frais, aucune usure).
- Strate 1 → 2 → 3, la Taverne servie en priorité (6 bouillons max), la Forge prend le reste. Les ventes de la strate 1 partent du stock après consommation.
- Stock plein : temps résiduel → +2 Moral/h. Fiche de rupture sous 15 % de la cible.

## 3. Prix et Or
- Prix_Vente = max(1, round(P_eff × clamp(1,25 − 0,25 r, 0,75, 1,25))), rachat = floor(× 0,60). P_eff = P_base × M_isolat. Achats du joueur : pas de taxe. Gain d'arbitrage ≤ 0 prouvé en entiers.
- Postures : cible 40 / 60 / 85 % du stock max, taxe 10 / 20 / 30 %. Stock max : matériaux 60 + 40 (L − 1), produits 30 + 20 (L − 1).
- Circuit à M_isolat 1 : 130 Or créés/j (solde 50 + caravanes 80), CA 200, salaires 45 %, taxes 20 % (floor par boutique), trésoreries 35 % (150 Or initiaux). Les trésoreries paient rachats et primes (22 × M_isolat) ; rachat suspendu si la caisse est vide. Comptoir : 18 × M_isolat, 87 XP à la vocation de la boutique.
- Puits : frais fixes 8 × L par boutique, usure, consommation, greffes. Améliorations : boutique 250 L² Or + 15 L Tier 0, Grand Âtre 600 L² (Nv2 : + 40 minerais + 40 Tier 0), route 500 Or.

## 4. Moral
- Tick unique par day_index : M + travail (−6 / −12 / −24) + repas (+6, −8 sans, 0 hors-ligne) + lit (6 + 2 (Maison − 1)) + round((80 − M) × 0,25).
- Grève sous 20, M_moral = 0 pendant toute la grève, +40 par tick, sortie plafonnée à 50. Normal : équilibre 80. Forge ardente seule : point fixe 32.
- Veillée : +10 à 5 PNJ, 5 bouillons + 2 charbons, recharge 3 j. Cadeau : +12, 1 EQUIP_FORGE, 3 j par PNJ.

## 5. Missions et chantiers
- Escouade 2–4 (2 en tranche). P = (0,40 + 0,20 E) × clamp(ilvl / L, 0,5, 1,25). Réussite = clamp(0,60 + 0,25 (S − S_req), 0,15, 0,95), S_req 1,60 / 3,20. Succès : 100 % de la cargaison, échec : 0 % (récupérable). Mission de minage : 4 minerais.
- Braises : 15 / run, 2 min par Braise, 50 % max. Chantiers : min(1440, 60 L²) min (L de départ), Âtre 2 : 240 min.

## 6. Profils (Or possédé, ≥ 0 chaque jour)

| Profil | Âtre 2 | J+7 | J+30 | J+90 | J+180 | J+365 |
| --- | --- | --- | --- | --- | --- | --- |
| Pause Café | J+34 | 266 | 1 140 | 2 330 | 3 650 | 3 840 |
| Régulier | J+17 | 392 | 99 | 502 | 2 345 | 4 146 |
| Assidu | J+9 | 477 | 379 | 1 995 | 5 004 | 5 010 |

Note : en prix unitaires entiers, les trésoreries de l'Assidu sont à −1 à −3 Or/j à partir de l'isolat 2. Elles touchent 0 à J+287 ; la suspension du rachat lui coûte 78 Or sur l'année.

## 7. Intégration (Claude Code, sans changer de valeur)
- Taxes, salaires et trésoreries : floor par boutique et par vente.
- ISOLAT_GOLD_MULTIPLIERS = BalanceA.ISOLAT_XP_MULTIPLIERS (une seule source). ISOLAT_SCALES_ALL_NOMINAL_GOLD_FLOWS inutile.
- COUNTER_EVENT_XP_REWARD (B) double XP_VILLAGE_COUNTER_EVENT (A) : garder celui de A.
- CLOCK_DRIFT_TOLERANCE_SEC et OFFLINE_MAX_HOURS : retirer de Clock.gd, lire BalanceB.
- NPC_NEW_SHOP_SAVINGS_THRESHOLD : inactif en tranche (budget dépensé à 100 %).
