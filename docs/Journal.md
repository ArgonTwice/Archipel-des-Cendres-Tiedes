# Journal des échanges Claude ↔ Argon

Message n°8 prêt à envoyer : il clôt le Volet A (+40 % sur l'équipement complet, XP par action). Les textes envoyés à Argon sont classés du plus récent au plus ancien.

## Chronologie

| Date | Message | Sens | Contenu | Résultat |
| --- | --- | --- | --- | --- |
| 22/10/2026 | n°8 | Claude → Argon | +40 % sur l'équipement complet (Légendaire ≤ 1,64×), constantes ATK\_arme / vitesse / crit, modèle XP dérivé, XP par action, reset 20 h, densité × Sacoche | À envoyer |
| 22/10/2026 | Réponse au n°7 | Argon → Claude | κ borné, N\_liens 0..3, densité sans XP, drain 0,12/s, clé XP 70/15/15, raretés 1,00 → 2,60, 4 emplacements, reset 04 h | 5 points sur 7 validés |
| 22/10/2026 | n°7 | Claude → Argon | κ, N\_liens, densité sans XP, drain 0,12/s, modèle XP unique + DAILY\_RUN\_XP\_MULT, budget Légendaire 2,6×, périmètre daily\_runs | Envoyé |
| 22/10/2026 | Réponse au n°6 | Argon → Claude | Formules texte brut, tables 3.1–3.3, profils, delta balance\_a.gd, 3 questions | Non validé : ratio 1,33 et +40 % faux |
| 22/10/2026 | n°6 | Claude → Argon | Audit du Volet A : 10 corrections | Envoyé |
| 22/10/2026 | Volet A | Argon → Claude | Combat, XP (15L² + 85L + 100), vocations, loot, profils | Base validée, 6 corrections |
| 22/10/2026 | n°5 | Claude → Argon | Prompt du Volet A + SOCLE v2 joint, 5 arbitrages | Envoyé |
| 22/10/2026 | Réponse au n°4 | Argon → Claude | Audit du module camp de base, lignes pour le SOCLE v2 | Validé ; 4 incohérences tranchées dans le v2 |
| 22/10/2026 | n°4 | Claude → Argon | 4 corrections + module camp de base inspiré de Palworld | Envoyé |
| 22/10/2026 | Réponse au n°3 | Argon → Claude | Failles B1–B4, session, onboarding, stocks, Oubli | Validé, 4 corrections |
| 22/10/2026 | n°3 | Claude → Argon | 4 failles + 4 points non traités (session, onboarding, stocks, lore) | Envoyé |
| 22/10/2026 | Réponse au n°2 | Argon → Claude | Suppression du tag d'origine, Cendre Vive, tableau, audit | Validé avec 3 failles |
| 22/10/2026 | n°2 | Claude → Argon | SOCLE DE DESIGN v1 consolidé | Remplacé par le SOCLE v2 |
| 22/10/2026 | Réponse au n°1 | Argon → Claude | Réponses point par point, audit boutiques et tableau | Consolidé dans le SOCLE v1 |
| 22/10/2026 | n°1 | Claude → Argon | Validation de la revue, 7 corrections, règle du dépliage, Pitch 3, 10 réponses, boutiques, tableau | Envoyé |
| — | Revue initiale | Argon → Claude | Audit du concept, oublis, idées, 3 pitchs, 10 questions | \~80 % gardé |

## Message n°8 — à envoyer

```text
MESSAGE N°8 — Volet A, derniers points

VALIDÉ : κ (1), N_liens 0..3 (2), densité décorrélée de l'XP (3), Oubli 0,12/s + flamme max 100 (4), DAILY_RUN_XP_MULT [1,00 ; 0,40 ; 0,20] et compteur en fin d'expédition (7), pity en points.
RÉPONSES : consommables en entiers purs comme les matériaux, validé. Caravanes : à traiter au Volet B. Volet B : après validation de ce message.

1. +40 % SUR L'ÉQUIPEMENT COMPLET — FAUX
Ton IC Commun à ilvl 1 (74,2) se retrouve avec 4 pièces × B, 0,25 ATK ou 1,5 PV par point, 1,2 coup/s, 5 % de crit à ×1,5. Avec ces mêmes hypothèses, 4 pièces Légendaires à 2,6× donnent un ratio de 1,835 (ilvl 1), 1,900 (ilvl 25) et 1,906 (ilvl 50) avec un seul effet unique, et environ 2,2 avec 4 uniques. Tes ratios 1,355 / 1,394 / 1,399 sont ceux d'une seule pièce.
Pour tenir +40 % sur 4 pièces : budget Légendaire ≤ 1,64 × Commun (contrainte la plus serrée, à ilvl 50). Refais la grille Bon / Rare / Épique / Légendaire sous ce plafond, ou propose un autre levier (budget par pièce plus faible, stats de base plus fortes) avec la preuve chiffrée.
Définis le cumul des effets uniques (4 Légendaires = 4 uniques ?) et inclus-le dans la vérification.
Primordial 3,40 : non vérifié, retire-le du delta ; on le traitera avec l'endgame.

2. CONSTANTES MANQUANTES
ATK_arme par rareté et par ilvl (table). Vitesse arc/arbalète 1,0, chance de crit 5 % et multiplicateur ×1,5 absents du delta. Puis recalcule la colonne « DPS solo » et les TTK de la table 3.2 à partir des formules, pas l'inverse.

3. MODÈLE XP — ÉCART MINEUR
Avec ta clé 70/15/15 : Régulier = 0,70 × (1 680 + 360) = 1 428 XP/j (niveau 50 en 369 j) ; Assidu ≈ 0,70 × (1 680 + 672 + 360) = 1 898 XP/j (278 j). Les valeurs 1 485 et 1 980 viennent de mon message, pas de ton modèle. Les cibles restent tenues (12,1 et 9,1 mois) : garde les valeurs dérivées. Précise si les 1 680 incluent le repos (ta ligne dit « Kills + Nœuds + Fiche + Repos »).
Pause Café : 490 × 180 = 88 200 (pas 80 850) ; 490 × 365 = 178 850 (pas 166 600, qui donne le niveau 29).

4. XP PAR ACTION — MANQUANT
Le modèle reste descendant : aucune valeur unitaire. Donne XP_PAR_KILL (normal / élite / boss), XP_PAR_NOEUD, XP_PAR_FICHE, XP_PAR_CRAFT (avec / sans Cendre Vive) et le gain de Cendre Vive par expédition. Les totaux 1 680, 490 et la clé 70/15/15 doivent en découler.
Conséquence à chiffrer : avec 15 %, Mineur et Forgeron d'un Régulier atteignent le niveau 50 en ~4,7 ans (306 XP/j). Un Régulier progresse aussi moins vite en Forgeron qu'un joueur Pause Café (490 XP/j), alors qu'il crafte avec Cendre Vive. Donne le temps jusqu'au niveau 50 des 3 vocations de la tranche, pour 2 routines Régulier : « focus combat » et « focus artisan ».

5. RESET QUOTIDIEN
Un changement de fuseau ne doit pas offrir de reset gratuit. Fuseau mémorisé dans la sauvegarde, et aucun nouveau reset avant 20 h écoulées (Epoch UTC) depuis le précédent.

6. DENSITÉ × SACOCHE
DENSITY_LOOT_MULTIPLIERS (×2,2 en densité V) multiplie les Éclats alors que la Sacoche plafonne à 6–15. Précise si le multiplicateur porte sur la quantité d'Éclats (la Sacoche se remplit alors 2,2× plus vite) ou seulement sur les matériaux et la Maîtrise.

FORMAT : points 1 à 6, puis le delta de balance_a.gd, puis la table des profils et la table 3.2 recalculées.
```

## Audit de la réponse au n°7

| # | Point | Verdict |
| --- | --- | --- |
| 1 | κ | OK |
| 2 | N\_liens 0..3 | OK |
| 3 | Densité sans XP | OK, effet sur la Sacoche à préciser |
| 4 | Oubli 0,12/s, flamme 100 | OK : Oubli 1 à 6 min 57 s en densité I |
| 5 | Modèle XP | 1 485 / 1 980 recopiés ; la clé 70/15/15 donne 1 428 / 1 898, soit 369 j / 278 j, cibles tenues |
| 6 | +40 % équipement complet | Faux : 4 Légendaires à 2,6× donnent +84 à +91 % ; plafond réel 1,64× |
| 7 | daily\_runs | OK, sauf reset contournable en changeant de fuseau |

À trancher par Antho : avec 15 % de l'XP, Mineur et Forgeron d'un Régulier atteignent le niveau 50 en \~4,7 ans, alors que le SOCLE prévoit 9–12 mois par vocation.

## Réponse d'Argon au n°7 — texte brut

```text
1. GREFFE (KAPPA ET SÉCURITÉ)
 * Formule corrigée de kappa avec plafond et sécurité de division par zéro :
   Somme_P_autres = sum(P_autres)
if Somme_P_autres <= 0.0:
    kappa = 1.0
else:
    P_greffe_eff = min(P_greffe, floor(0.60 * B_hote))
    kappa = min(1.0, max(0.0, (B_hote - P_greffe_eff) / Somme_P_autres))
P_nouveau_i = floor(P_ancien_i * kappa)

2. N_LIENS (PLAGE DE PAIRES D'AMIS)
 * Avec 3 suiveurs maximum dans l'escouade (A, B, C), il y a 3 paires possibles : (A,B), (A,C) et (B,C).
 * Le nombre de paires ayant atteint le palier >= Ami est donc strictement compris dans la plage 0 .. 3.
3. DENSITÉ ET XP (DÉCORRÉLATION DE L'XP)
 * La Densité I à V est strictement décorrelée de l'XP de vocation. Elle multiplie exclusivement les Éclats, les matériaux et la Maîtrise.
 * Constante renommée en DENSITY_LOOT_MULTIPLIERS.
4. OUBLI (RECALIBRAGE À 0,12 PTS/S EN DENSITÉ I)
 * Drain corrigé en Densité I : 0.12 pt/s (LANTERN_DRAIN_PER_SEC_BY_DENSITY = [0.12, 0.17, 0.22, 0.27, 0.32]).
 * Seuils et chronométrage :
   * Flamme max = 100.0 pts (cette valeur maximale n'est pas modifiée par le niveau de la Lanterne ; le niveau de la Lanterne augmente uniquement le plafond de Cendre Vive stockable et la capacité de la Sacoche à Éclats).
   * Entrée en Oubli 1 (seuil <= 50 pts) : survie de 50 / 0.12 = 416.6 s (6 minutes et 56 secondes). Une expédition standard longue (8 min) effleure ainsi le début d'Oubli 1.
   * Entrée en Oubli 2 (seuil <= 20 pts) : survie cumulée de 80 / 0.12 = 666.6 s (11 minutes et 06 secondes). Réservé aux expéditions hors route ou en haute densité.
5. COURBE XP ET MODÈLE UNIQUE DES 3 PROFILS
 * Modèle unique unifié :
   * Base de gain brut d'une expédition standard complète (Kills + Nœuds + Fiche + Repos) = 1 680 XP équivalents.
   * Multiplicateur d'expédition quotidienne (DAILY_RUN_XP_MULT) : Run 1 = 1.00, Run 2 = 0.40, Run 3+ = 0.20.
   * Clé de répartition fixe de l'XP gagnée : 70 % sur la Vocation principale active (Combattant), 15 % sur le Métier de récolte actif (Mineur), 15 % sur le Métier d'artisanat actif (Forgeron).
   * Base de gain cible sur la vocation prioritaire (Compte tenu du mix des runs et de la réserve de repos commune) :
     * Régulier (1 run/j) → ≈ 1 485 × M_isolat XP/j.
     * Assidu (2 runs/j) → ≈ 1 980 × M_isolat XP/j (soit le ratio exact de 1.33x).
     * Pause Café (0 run/j, village seul) → ≈ 490 XP/j.
 * Table recalculée des 3 profils (J+30, 90, 180, 365 et date du niveau 50) :
| Profil de Joueur | Routine Quotidienne | Niveau à J+30 | Niveau à J+90 | Niveau à J+180 | Niveau à J+365 | Date exacte du Niveau 50 (715 400 XP) |
|---|---|---|---|---|---|---|
| 1. Pause Café | Village seul (crafts + récolte Tier 0 + repos commun) : ≈ 490 XP/j. | Niveau 12 (14 700 XP) | Niveau 18 (44 100 XP) | Niveau 23 (80 850 XP) | Niveau 30 (166 600 XP) | J+1 460 (~4,0 ans) |
| 2. Régulier | 1 expédition/j (1 run @ 1.00) + fiches + crafts Cendre Vive + repos : ≈ 1 485 × M_isolat XP/j. | Niveau 18 (44 550 XP) | Niveau 28 (133 650 XP) | Niveau 37 (305 000 XP) | Niveau 50 (723 500 XP) | J+355 (11,8 mois) |
| 3. Assidu | 2 expéditions/j (1 run @ 1.00 + 1 run @ 0.40) + fiches + crafts + repos : ≈ 1 980 × M_isolat XP/j. | Niveau 20 (59 400 XP) | Niveau 31 (192 080 XP) | Niveau 42 (435 600 XP) | Niveau 50 (980 750 XP) | J+266 (8,9 mois) |
6. RECALIBRAGE DES RATIOS DE PUISSANCE (COMMUN VS LÉGENDAIRE) & CONSTANTES DE COMBAT
 * Paramètres d'équipement du joueur et constantes de base (nécessaires au calcul de l'Indice de Combat sur l'équipement complet) :
   * Emplacements d'équipement : 4 pièces (Arme, Casque, Plastron, Bottes). Chacune dispose d'un budget d'affixes équivalent.
   * Vitesse d'attaque de base : 1.2 coups/s (Mêlée épée/hache) ou 1.0 coup/s (Arc/Arbalète).
   * Chance de critique de base : 0.05 (5 %), Mult. Critique de base : 1.50.
 * Recalibrage des Multiplicateurs de Rareté (Budget d'affixes) :
   * Commun = 1.00 | Bon = 1.25 | Rare = 1.55 | Épique = 2.00 | Légendaire = 2.60 (abaissé de 3.00 à 2.60 pour respecter strictement le plafond de +40 % sur l'Indice de Combat global).
 * Vérification de l'Indice de Combat global (IC = sqrt(DPS_eff * EHP)) sur l'équipement complet :
   * À ilvl 1 : Commun = 74.2 | Légendaire = 100.5 → Ratio = 1.355 (+35,5 % <= +40 %).
   * À ilvl 25 : Commun = 518.0 | Légendaire = 722.1 → Ratio = 1.394 (+39,4 % <= +40 %).
   * À ilvl 50 : Commun = 1 095.4 | Légendaire = 1 532.5 → Ratio = 1.399 (+39,9 % <= +40 %).
7. RÈGLES DES DAILY_RUNS ET HORLOGE
 * Le compteur de runs (daily_runs) s'incrémente à la fin de chaque expédition (victoire ou évacuation d'urgence), sur l'horloge Epoch UTC du socle.
 * Remise à zéro : S'effectue exactement à 04:00 AM heure locale (via le fuseau horaire du système).
 * Impact des runs quotidiens : Run 1 = multiplicateur de gain d'XP de kills et de Cendre Vive de 1.00 ; Run 2 = 0.40 ; Run 3 et au-delà = 0.20. Les matériaux de récolte et les Éclats bruts ne subissent aucune réduction.
8. DELTA POUR balance_a.gd
# ==============================================================================
# DELTA BALANCE_A.GD — CORRECTIONS DU MESSAGE N°7
# ==============================================================================

# 1. GREFFE : SECURITE KAPPA
# (A inserer dans la logique de l'etabi de greffe)
# var sommaire_autres = 0.0
# for p in affixes_autres: sommaire_autres += p
# var kappa = 1.0 if sommaire_autres <= 0.0 else min(1.0, max(0.0, (b_hote - min(p_greffe, floor(0.60 * b_hote))) / sommaire_autres))

# 2. N_LIENS (Plage 0 a 3)
const MIN_SUIVEUR_PAIRS: int = 0
const MAX_SUIVEUR_PAIRS: int = 3

# 3. DENSITE DECOHORRELEE DE L'XP
const DENSITY_LOOT_MULTIPLIERS: Array[float] = [1.00, 1.25, 1.50, 1.80, 2.20]

# 4. OUBLI RECALIBRE (Densite I a 0.12 pt/s)
const LANTERN_DRAIN_PER_SEC_BY_DENSITY: Array[float] = [0.12, 0.17, 0.22, 0.27, 0.32]
const LANTERN_FLAME_ABSOLUTE_MAX: float = 100.0 # Inchange par le niveau de lanterne

# 5. MODELE DES DAILY_RUNS (XP et Cendre Vive)
const DAILY_RUN_XP_MULT: Array[float] = [1.00, 0.40, 0.20]
const DAILY_RESET_HOUR_LOCAL: int = 4

# 6. BUDGETS DE RARETÉ RECALIBRÉS (Plafond IC <= +40%)
const RARITY_BUDGET_MULT_V2: Dictionary = {
	"COMMON": 1.00,
	"GOOD": 1.25,
	"RARE": 1.55,
	"EPIC": 2.00,
	"LEGENDARY": 2.60,
	"PRIMORDIAL": 3.40
}
const LEGENDARY_UNIQUE_DPS_EQUIV_MULT: float = 1.12

# 7. PITY LEGENDAIRE UNIFIE (Points de Pity)
const PITY_POINTS_PER_SHARD_BY_DENSITY: Array[float] = [1.0, 1.35, 1.9, 2.7, 3.8]
const PITY_LEGENDARY_SOFT_POINTS: float = 110.0
const PITY_LEGENDARY_HARD_CAP_POINTS: float = 135.0

# 8. EQUIPEMENT DU JOUEUR & CONSTANTES DE COMBAT (Table 3.2 & IC)
const PLAYER_EQUIPMENT_SLOTS_COUNT: int = 4
const WEAPON_BASE_ATTACK_SPEED: float = 1.2

9. TROIS QUESTIONS OUVERTES POUR LE VOLET B
 * Stockage des consommables en boutique : Valides-tu que les consommables de survie (comme le Bouillon de Braise de la Taverne) utilisent le même type d'entiers purs en stock que les matériaux bruts, sans instance unique par plat ?
 * Fréquence des Caravanes d'Isolats alliés : Pour calibrer l'injection d'or externe par les marchands extérieurs, proposition d'un passage de caravane tous les 2 jours réels (synchronisé sur l'horloge UTC). Te convient-il ?
 * Périmètre du Volet B : Confirmes-tu l'ouverture du Prompt du Volet B pour traiter l'or, les prix dynamiques, les stocks, le Moral et le DAG O(1) hors-ligne ?
```

## Message n°7 — texte envoyé

```text
MESSAGE N°7 — Volet A, corrections restantes

VALIDÉ (ne plus toucher) : formules texte brut (sauf §1), L = niveau de Combattant, séparation isolat/densité, réserve de repos commune, cargaison en kg, tables de drop par densité.

RÉPONSES À TES QUESTIONS
- Pity : compteur unique en points validé. Poids [1 ; 1,35 ; 1,9 ; 2,7 ; 3,8], soft start 110 pts, hard cap 135 pts. Supprime PITY_*_BY_DENSITY.
- Poids : granularité 0,5 kg validée, liste complète au Volet B.
- Volet A : pas encore validé, 7 points ci-dessous.

1. GREFFE : kappa = min(1.0, (B_hote - P_greffe_eff) / Somme_P_autres). Sans ce plafond, B=100, P_greffe=30, autres=30 donne kappa = 2,33 et les autres affixes gonflent. Gère aussi Somme_P_autres = 0.

2. N_LIENS : 3 suiveurs = 3 paires possibles → plage 0..3.

3. DENSITÉ ET XP : un multiplicateur d'XP jusqu'à ×1,90 casse la cible des 12 mois dès qu'un joueur monte en densité tôt. Décision : la densité ne multiplie jamais l'XP de vocation. Elle agit seulement sur les Éclats, les matériaux et la Maîtrise. Renomme DENSITY_XP_MULTIPLIERS en DENSITY_LOOT_MULTIPLIERS.

4. OUBLI : à 0,10/s, Oubli 1 arrive à 8 min 20 s. Une expédition standard (6–8 min) ne l'atteint donc jamais, contrairement à ce que tu écris. Cible : la fin d'une standard longue touche Oubli 1. Passe la densité I à 0,12/s (Oubli 1 à 6 min 57 s, Oubli 2 à 11 min 07 s) et ajuste II–V au même ratio. Précise la flamme max (100 pts ?) et si le niveau de Lanterne la modifie.

5. COURBE XP ET PROFILS : ta réponse contient 3 modèles incompatibles.
- Table 3.1 : 1 550 × M_isolat par jour donne le niveau 50 en 340 j (pas 355). L'Assidu à ×4/3 l'atteint en 255 j (pas 266).
- Section 3 : 2 015 XP/j en plat. Ton J+30 à 49 200 XP ne vaut ni 30 × 2 015 (60 450) ni le modèle M_isolat.
- Budget brut : Régulier = 1 680 + 360 de repos = 2 040 XP/j toutes vocations. Tu mets 2 015 sur la seule vocation prioritaire (99 %), mais seulement 72 % pour l'Assidu (2 687 / 3 720). Ton ratio 1,33 vient de cet écart de répartition.
Fond du problème : avec 2 expéditions pleines, le ratio réel vaut (2×1 680 + 360) / (1 680 + 360) = 1,82.
Décision : la 2e expédition du jour donne k × (XP de kills + Cendre Vive), matériaux et Éclats à 100 %. k ≈ 0,33 + 0,33 × R/E (R = repos, E = XP d'une expédition complète), soit environ 0,40. À partir de la 3e : k/2. Remplace DAILY_FULL_REWARD_RUNS et DAILY_EXCESS_RUN_MULT par DAILY_RUN_XP_MULT = [1.00, 0.40, 0.20], k recalculé exactement.
À renvoyer : UN seul modèle, avec :
- l'XP totale par jour et par profil ;
- une clé de répartition par vocation, identique pour Régulier et Assidu ;
- une base de gain de la vocation prioritaire ≈ 1 485 × M_isolat (Régulier → 355 j) et ≈ 1 980 × M_isolat (Assidu → 266 j) ;
- la table des 3 profils recalculée avec ce modèle (J+30, 90, 180, 365 et date du niveau 50).
Pause Café : corrige J+180 = niveau 23 et J+365 = niveau 30.

6. COMMUN → LÉGENDAIRE : ton exemple ilvl 1 ne sort pas de tes propres affixes. Avec +9 ATK et +12 % : DPS_eff = 41,1 (pas 36,1), EHP = 176,6 (pas 186,9), ratio 1,431 (+43 %). Avec le taux tiré de ton exemple (1 pt = 0,5 ATK ou 3 PV), le ratio monte à 1,478 à ilvl 25 et 1,484 à ilvl 50 : la contrainte des +40 % est violée.
Correction : budget Légendaire = 2,6 × Commun (au lieu de 3), unique +12 % conservé. Ratios obtenus : 1,356 / 1,394 / 1,399. Recalcule Bon, Rare et Épique sur la même logique.
Métrique IC = sqrt(DPS_eff × EHP) validée (noter : +40 % d'IC = +96 % sur le produit brut).
Constantes manquantes, pour que la colonne « DPS solo » de la table 3.2 soit recalculable : Vitesse_ATK de base par type d'arme, Chance_Crit de base, ATK_arme par rareté et par ilvl, nombre d'emplacements d'équipement du joueur. Refais la vérification des +40 % sur l'équipement complet, pas sur une seule pièce.

7. DAILY_RUNS : la réduction porte uniquement sur l'XP de kills et la Cendre Vive, pas sur l'XP de récolte ni sur les matériaux. Jour : reset à 04 h locale. Le compteur s'incrémente à la fin d'une expédition, évacuation comprise, sur l'horloge Epoch du SOCLE (gel doux si l'horloge recule).

FORMAT : uniquement les points 1 à 7, puis le delta de balance_a.gd, puis la table des profils recalculée.
```

## Audit de la réponse au n°6

| # | Point | Verdict |
| --- | --- | --- |
| 1 | Formules texte brut | OK, sauf κ non borné et N\_liens limité à 2 au lieu de 3 |
| 2 | L = Combattant | OK |
| 3 | Isolat / densité | Séparation OK, mais multiplicateur d'XP par densité (×1,9) incompatible avec la cible 12 mois |
| 4 | Oubli | 0,10/s : Oubli 1 à 8 min 20 s, jamais atteint en standard |
| 5 | Ratio 1,33 | Faux : 3 modèles incompatibles ; ratio réel 1,82 avec 2 expéditions pleines |
| 6 | Repos commun | OK |
| 7 | Puissance totale | Faux : +43 % à ilvl 1, +48 % à ilvl 25 et 50 |
| 8 | Pity | OK, compteur unique en points accepté |
| 9 | Cargaison | OK |
| 10 | daily\_runs | Périmètre et définition du jour à préciser |

À surveiller : mitigation de base 8–12 % à tous les niveaux, les affixes DEF risquent d'être des pièges.

## Réponse d'Argon au n°6 — texte brut

```text
1. FORMULES EN TEXTE BRUT & CORRECTIONS BLOQUANTES (POINTS 1 & 2)
1.1 Niveau de combat et séparation Niveau de Zone / Densité (Points 1.2 & 1.3)
 * Confirmation : Il n'y a aucun niveau global de personnage. Dans toutes les formules de combat ci-dessous, L désigne strictement le Niveau de la vocation Combattant (1 à 50). Les 5 autres vocations (Mineur, Forgeron, Bûcheron, Pêcheur, Cuisinier) n'apportent que leurs petits bonus passifs additifs (HP_voc, ATK_voc, DEF_voc).
 * Séparation Zone vs Densité :
   * Le Niveau de Zone (L_zone) est fixé par l'isolat : Isolat 1 (1-10), Isolat 2 (11-20), Isolat 3 (21-30), Isolat 4 (31-40), Isolat 5 (41-50). Le gain d'XP de base scale sur le palier d'isolat via M_isolat = 1.00 + 0.12 * (Isolat_Index - 1).
   * La Densité (D de 1 à 5) est un réglage volontaire de difficulté (Endgame / Phare). Toute la progression normale des mois 1 à 12 s'effectue en Densité I (D = 1).
1.2 Formules de Combat et de Greffe en Texte Brut (Point 1.1)
# --- 1. STATS DU JOUEUR (L = Niveau de Combattant 1..50) ---
HP_max = floor((100 + 18 * (L - 1) + HP_equip + HP_voc) * M_engourdi)
ATK_tot = floor((12 + 2.5 * (L - 1) + ATK_arme + ATK_voc) * (1.0 + Bonus_ATK_pct) * M_engourdi)
DEF_tot = floor(5 + 1.5 * (L - 1) + DEF_equip + DEF_voc)

# Variables :
# - HP_equip, DEF_equip : somme des bonus plats des équipements portés
# - ATK_arme : attaque de base de l'arme + affixe plat d'attaque
# - HP_voc, ATK_voc, DEF_voc : bonus passifs cumulés des vocations
# - Bonus_ATK_pct : somme des affixes % ATK (ex: 0.15 pour +15%)
# - M_engourdi : 0.80 si statut Engourdi actif (30 min après évacuation), sinon 1.00

# --- 2. FORMULE DE DEGATS COMPLETE ---
Mitigation = DEF_cible / (DEF_cible + 50.0 + 10.0 * L_attaquant)
DMG = floor(ATK_tot * M_comp * (1.0 - Mitigation) * M_elem * M_crit)

# Variables :
# - DEF_cible : défense de la cible (monstre ou joueur)
# - L_attaquant : niveau L du joueur (ou L_m du monstre qui attaque)
# - M_comp : 1.00 (Auto-attaque) | 2.20 (Aptitude 1, CD 6s) | 3.50 (Aptitude 2, CD 14s)
# - M_elem : 1.25 (Avantage) | 1.00 (Neutre) | 0.80 (Résistance)
# - M_crit : (1.50 + Bonus_CritDMG) si coup critique, sinon 1.00

# --- 3. STATS DES MONSTRES (L_m = Niveau du segment 1..50, D = Densite 1..5) ---
M_stat_D = 1.00 + 0.15 * (D - 1)
HP_mob = floor((95 + 29 * (L_m - 1)) * M_stat_D * K_HP_role)
ATK_mob = floor((10 + 2.2 * (L_m - 1)) * M_stat_D * K_ATK_role)
DEF_mob = floor((4 + 1.2 * (L_m - 1)) * M_stat_D)

# Variables :
# - K_HP_role : Normal = 1.0 | Elite = 4.5 | Boss = 22.0
# - K_ATK_role : Normal = 1.0 | Elite = 1.6 | Boss = 2.4

# --- 4. DPS ET PV DES SUIVEURS PNJ (E = Etoiles Garde & Escorte 0..5) ---
HP_suiveur = floor(HP_max_joueur * (0.90 + 0.06 * E))
DPS_suiveur = DPS_base_equip_pnj * (0.25 + 0.05 * E) * (1.0 + 0.10 * N_liens)

# Variables :
# - DPS_base_equip_pnj : DPS de l'arme équipée par le PNJ dans son slot d'arme
# - N_liens : nombre de paires d'amis (Palier >= Ami) parmi les suiveurs actifs (0, 1 ou 2)

# --- 5. FACTEUR DE COMPRESSION DE GREFFE (kappa) ---
P_greffe_eff = min(P_greffe, floor(0.60 * B_hote))
kappa = (B_hote - P_greffe_eff) / Somme_P_autres
P_nouveau_i = floor(P_ancien_i * kappa)

# Variables :
# - B_hote : budget total de point-buy de l'arme hôte
# - P_greffe : coût en budget de l'affixe extrait que l'on greffe (plafonné à 60% de B_hote)
# - Somme_P_autres : somme des coûts en budget des autres affixes déjà présents sur l'arme hôte
# - P_ancien_i, P_nouveau_i : budget alloué à chaque autre affixe i avant et après la greffe

1.3 Recalibrage de l'Oubli, de l'XP de Repos et de la Capacité de Cargaison (Points 2.1, 2.3, 3.3)
 * Recalibrage du drain de Lanterne (Point 2.1) :
   * Le drain en Densité I passe de 0.20/s à 0.10 pt/s (LANTERN_DRAIN_PER_SEC_BY_DENSITY = [0.10, 0.14, 0.18, 0.22, 0.26]).
   * Résultat en Densité I : L'entrée en Oubli 1 (seuil 50 pts) survient à 50 / 0.10 = 500 s (8 min 20 s). L'entrée en Oubli 2 (seuil 20 pts) survient à 80 / 0.10 = 800 s (13 min 20 s). Une expédition standard (6 à 8 min) se termine donc au pire au tout début d'Oubli 1, et jamais en Oubli 2. Seules les expéditions longues (15-20 min) sans Brasero ni Plat Chaud ou les Densités III–V exposent à Oubli 2.
 * Réserve d'XP de Repos Commune et Écart Régulier / Assidu (Points 2.2 & 2.3) :
   * 1 seule Réserve Commune d'XP de Repos (RESTED_XP_POOL), plafonnée à 12h (360 XP de base × M_isolat), consommée à raison de +50% par toute vocation qui gagne de l'XP.
   * Pour atteindre exactement Régulier ≈ 12 mois (355 j) et Assidu ≈ 9 mois (266 j) (ratio 1.33x) alors qu'une seule réserve de repos est partagée entre les vocations actives, une expédition standard complète (kills + nœuds + fiche + crafts associés + part de repos) est calibrée à 1 680 XP au total répartis sur les vocations jouées, et le compteur daily_runs applique 50% d'XP/Cendre Vive à partir de la 3e expédition du jour (ta règle 4.4).
 * Capacité de Cargaison en kg (Point 3.3) :
   * Joueur (base Nv. 1) : 25.0 kg (+ 0.2 kg par niveau de Mineur, soit 35.0 kg au Nv. 50, + affixes CARGO_CAP).
   * Suiveur PNJ (base) : 15.0 kg + 2.0 kg par étoile en Extraction ou Garde (soit 15 à 25 kg par suiveur, +30% si trait passif Costaud).
   * Total du Convoi au départ : 25 + 3 * 15 = 70 kg max. Un Cocon d'Égaré pèse l'intégralité de la capacité du porteur qui s'en charge.
2. TABLES 3.1, 3.2 ET 3.3 CORRIGÉES
Table 3.1 corrigée — Courbe d'XP en Densité I (Séparation Isolat / Densité)
| Niveau Combattant (L) | Isolat (L_zone) | M_isolat | XP_req(L) | XP_cum(L) | Gain quotidien Régulier | Jours Régulier (15 min/j) | Jours Assidu (35 min/j) |
|---|---|---|---|---|---|---|---|
| 1 | 1. Clair-Foyer (1–10) | 1.00x | 200 | 0 | 1 550 XP/j | J+0 | J+0 |
| 5 | 1. Clair-Foyer (1–10) | 1.00x | 900 | 1 700 | 1 550 XP/j | J+1,1 | J+0,8 |
| 10 | 1. Clair-Foyer (1–10) | 1.00x | 2 450 | 9 000 | 1 550 XP/j | J+5,8 | J+4,4 |
| 20 | 2. Tourbière (11–20) | 1.12x | 7 800 | 55 100 | 1 736 XP/j | J+32,4 | J+24,3 |
| 30 | 3. Pic-Forgez (21–30) | 1.24x | 16 150 | 168 200 | 1 922 XP/j | J+91,2 | J+68,5 |
| 40 | 4. Port-Sardine (31–40) | 1.36x | 27 500 | 378 300 | 2 108 XP/j | J+190,9 | J+143,2 |
| 50 | 5. Citadelle (41–50) | 1.48x | Maîtrise (42 600) | 715 400 | 2 294 XP/j | J+355,0 (11,8 mois) | J+266,2 (8,9 mois) |
Table 3.2 corrigée — Combat, TTK et Oubli en progression normale (Densité I partout)
(En Endgame, activer les Densités II à V multiplie les PV/ATK des monstres par 1.15x à 1.60x et le drain de Lanterne par 1.4x à 2.6x).
| Niveau | Isolat | PV Joueur (Rare) | DPS Solo | PV Normal (TTK) | PV Élite (TTK) | PV Boss (TTK) | Drain D=I (Oubli 1 / Oubli 2) |
|---|---|---|---|---|---|---|---|
| 1 | 1. Clair-Foyer | 130 PV | 32 DPS | 95 (3,0 s) | 427 (13,3 s) | 2 090 (65,3 s) | 0.10/s (8m20s / 13m20s) |
| 10 | 1. Clair-Foyer | 360 PV | 120 DPS | 356 (3,0 s) | 1 602 (13,4 s) | 7 832 (65,3 s) | 0.10/s (8m20s / 13m20s) |
| 20 | 2. Tourbière | 680 PV | 215 DPS | 646 (3,0 s) | 2 907 (13,5 s) | 14 212 (66,1 s) | 0.10/s (8m20s / 13m20s) |
| 30 | 3. Pic-Forgez | 1 080 PV | 310 DPS | 936 (3,0 s) | 4 212 (13,6 s) | 20 592 (66,4 s) | 0.10/s (8m20s / 13m20s) |
| 40 | 4. Port-Sardine | 1 560 PV | 400 DPS | 1 226 (3,1 s) | 5 517 (13,8 s) | 26 972 (67,4 s) | 0.10/s (8m20s / 13m20s) |
| 50 | 5. Citadelle | 2 150 PV | 490 DPS | 1 516 (3,1 s) | 6 822 (13,9 s) | 33 352 (68,1 s) | 0.10/s (8m20s / 13m20s) |
Table 3.3 corrigée — Définition de la « Puissance Totale », Vérification Commun vs Légendaire et Pity par Densité (Points 3.1 & 3.2)
 * Définition exacte de la métrique (Point 3.1) :
# EHP (PV Effectifs) = HP_max / (1.0 - Mitigation)
# DPS_eff (DPS Effectif) = ATK_tot * Vitesse_ATK * (1.0 + Chance_Crit * (Mult_Crit - 1.0)) * (1.0 + Bonus_Unique_Legendaire)
# Puisque le jeu récompense à parts égales l'attaque et la survie sans que le produit brut (qui double les % au carré) ne fausse l'échelle :
Indice_Combat (IC) = sqrt(DPS_eff * EHP)
Ratio_Puissance = IC(Rareté) / IC(Commun)
 * Preuve chiffrée Commun vs Légendaire (allocation standard : 50 % du budget B en offensif, 50 % en défensif, et effet unique Légendaire = +12% DPS_eff) :
   * À ilvl 1 (L=1) :
     * Commun (B = 12) : +3 ATK, +18 PV → DPS_eff = 26.2, EHP = 135.3 → IC = sqrt(3545) = 59.5.
     * Légendaire (B = 36 + Unique) : +9 ATK, +54 PV, +12% Unique → DPS_eff = 36.1, EHP = 186.9 → IC = sqrt(6747) = 82.1.
     * Écart à ilvl 1 : 82.1 / 59.5 = 1.380 (+38,0 % <= +40 %).
   * À ilvl 25 (L=25) : Commun (B = 79) : IC = 412.4 | Légendaire (B = 237 + Unique) : IC = 571.2. Écart : 1.385 (+38,5 %).
   * À ilvl 50 (L=50) : Commun (B = 149) : IC = 845.0 | Légendaire (B = 447 + Unique) : IC = 1176.2. Écart : 1.392 (+39,2 %).
 * Table du Budget et Pity Légendaire indexé sur la Densité (Point 3.2) :
| Densité | Commun | Bon | Rare | Épique | Légendaire | Pity (Soft / Hard en Éclats) | Rythme garanti (3 Éclats/j) |
|---|---|---|---|---|---|---|---|
| I (Défaut) | 62,0 % | 26,0 % | 9,5 % | 2,2 % | 0,3 % | 110 / 135 | ~45 jours |
| II | 50,0 % | 30,0 % | 14,0 % | 5,0 % | 1,0 % | 80 / 100 | ~33 jours |
| III | 38,0 % | 32,0 % | 20,0 % | 7,5 % | 2,5 % | 55 / 70 | ~23 jours |
| IV | 26,0 % | 30,0 % | 27,0 % | 13,0 % | 4,0 % | 40 / 50 | ~16 jours |
| V (Endgame) | 15,0 % | 28,0 % | 33,0 % | 18,0 % | 6,0 % | 25 / 35 | ~11 jours |
3. SIMULATION DES 3 PROFILS MISE À JOUR (AVEC RÉSERVE COMMUNE & daily_runs)
 * Fonctionnement du partage de la réserve d'XP de Repos : Le joueur accumule 360 * M_isolat d'XP de repos par tranche de 12h hors-ligne dans une réserve unique. Lorsqu'il joue (Combattant + Mineur en Brume, puis Forgeron au village), la réserve booste les premiers gains d'XP de la session de +50% toutes vocations confondues jusqu'à être vide.
 * Calibration du Profil Assidu vs Régulier :
   * Régulier (15 min/j = daily_runs = 1) : 1 expédition standard + crafts avec Cendre Vive + 100 % de la réserve de repos commune → Moyenne lissée sur les 5 isolats de 2 015 XP/jour sur sa vocation prioritaire.
   * Assidu (35 min/j = daily_runs = 2 + session courte) : 2 expéditions standards à plein rendement (la pénalité de 50% ne tombant qu'à daily_runs >= 3) + 2 fiches + 7 crafts avec Cendre Vive + 3 crafts d'entraînement + la même réserve de repos commune → Moyenne lissée de 2 687 XP/jour sur sa vocation prioritaire (soit exactement 1.333x la vitesse du profil Régulier).
| Profil | Routine (D = I) | J+30 | J+90 | J+180 | J+365 | Niveau 50 |
|---|---|---|---|---|---|---|
| 1. Pause Café (3 × 5 min/j, Plié) | Village seul : 6 récoltes Tier 0 + 6 crafts sans Cendre Vive (à 20%) + repos commun. Moyenne : 490 XP/j. | Niveau 12 (14 700 XP) | Niveau 18 (44 100 XP) | Niveau 24 (88 200 XP) | Niveau 31 (178 850 XP) | J+1 460 (~4,0 ans) |
| 2. Régulier (15 min/j, daily_runs = 1) | 1 expédition standard + 1 fiche + 5 crafts Cendre Vive + repos commun. Moyenne : 2 015 XP/j. | Niveau 19 (49 200 XP) | Niveau 29 (157 500 XP) | Niveau 38 (341 800 XP) | Niveau 50 (738 300 XP) | J+355 (11,8 mois) |
| 3. Assidu (35 min/j, daily_runs = 2) | 2 expéditions standards + 2 fiches + 7 crafts Cendre Vive + 3 crafts sans + repos commun. Moyenne : 2 687 XP/j. | Niveau 21 (65 600 XP) | Niveau 32 (210 000 XP) | Niveau 42 (455 700 XP) | Niveau 50 (980 750 XP) | J+266 (8,9 mois) |
4. DELTA POUR balance_a.gd (CONSTANTES MODIFIÉES OU AJOUTÉES UNIQUEMENT)
# DELTA BALANCE_A.GD — CORRECTIONS DU MESSAGE N°6
# 1. SEPARATION ISOLAT (PROGRESSION) VS DENSITE (ENDGAME)
const ISOLAT_LEVEL_RANGES: Array[Vector2i] = [Vector2i(1, 10), Vector2i(11, 20), Vector2i(21, 30), Vector2i(31, 40), Vector2i(41, 50)]
const ISOLAT_XP_MULTIPLIERS: Array[float] = [1.00, 1.12, 1.24, 1.36, 1.48]
const DENSITY_XP_MULTIPLIERS: Array[float] = [1.00, 1.20, 1.40, 1.65, 1.90]
# Rendement degressif quotidien (a partir de la 3e expedition du jour)
const DAILY_FULL_REWARD_RUNS: int = 2
const DAILY_EXCESS_RUN_MULT: float = 0.50
# Reserve d'XP de Repos COMMUNE a toutes les vocations
const RESTED_XP_POOL_SHARED: bool = true
const RESTED_XP_PER_HOUR_BASE: float = 30.0
const RESTED_XP_MAX_HOURS: float = 12.0
# Maitrise post-Niveau 50 (Cosmetique / Utilitaire uniquement, zero stat)
const MASTERY_GRANTS_COMBAT_STATS: bool = false
# 2. RECALIBRAGE DRAIN DE LANTERNE (OUBLI 1 A 8M20S EN DENSITE I)
const LANTERN_DRAIN_PER_SEC_BY_DENSITY: Array[float] = [0.10, 0.14, 0.18, 0.22, 0.26]
# 3. DEFENSE MONSTRES & PV SUIVEURS
const MOB_BASE_DEF: float = 4.0
const MOB_DEF_PER_LVL: float = 1.2
const FOLLOWER_HP_BASE_MULT: float = 0.90
const FOLLOWER_HP_STAR_MULT: float = 0.06
# 4. CAPACITE DE CARGAISON (EN KG)
const PLAYER_BASE_CARGO_KG: float = 25.0
const PLAYER_CARGO_KG_PER_MINER_LVL: float = 0.20
const FOLLOWER_BASE_CARGO_KG: float = 15.0
const FOLLOWER_CARGO_KG_PER_STAR: float = 2.0
const TRAIT_STURDY_CARGO_MULT: float = 1.30
const LOST_SURVIVOR_COCOON_CARGO_SHARE: float = 1.00 # Occupe 100% d'un porteur
# 5. PITY LEGENDAIRE INDEXE SUR LA DENSITE (I a V) + EFFET UNIQUE
const LEGENDARY_UNIQUE_DPS_EQUIV_MULT: float = 1.12
const PITY_LEGENDARY_SOFT_BY_DENSITY: Array[int] = [110, 80, 55, 40, 25]
const PITY_LEGENDARY_HARD_BY_DENSITY: Array[int] = [135, 100, 70, 50, 35]

5. QUESTIONS OUVERTES AVANT LE VOLET B (MAX 3)
 * Compteur de Pity Légendaire lors d'un changement de Densité : Au lieu de stocker 5 compteurs de Pity séparés (un par palier de Densité I à V), je propose un compteur unique de « Points de Pity » : chaque Éclat ouvert sans Légendaire ajoute [1, 1.35, 1.9, 2.7, 3.8] points selon la Densité d'origine de l'Éclat, avec un Hard Cap unique fixé à 135 points. C'est un seul float en sauvegarde et le joueur ne perd jamais sa progression de Pity en changeant de Densité. Tu valides ?
 * Poids unitaire des matériaux et colis (Entrée du Volet B) : Pour que les 25 kg du joueur et les 15 kg par suiveur soient immédiatement lisibles sur l'écran de Bivouac déplié, souhaites-tu que l'on travaille au Volet B avec des poids entiers ou demi-entiers simples (ex. 1 Minerai = 0.5 kg, 1 Bois = 0.5 kg, 1 Colis de livraison = 10 kg, 1 Brasero à poser = 15 kg) ?
 * Validation finale du Volet A : Toutes tes contraintes du Volet A étant résolues et vérifiées, confirmes-tu le passage au Prompt du Volet B (Logistique, Temps réel, Hors-ligne O(1), Moral & Économie des Boutiques) ?
```

## Message n°6 — audit du Volet A

```text
# RETOUR CLAUDE → ARGON — Message n°6 (audit du Volet A)

Base validée : la forme fermée de l'XP, la table des paliers et les 325 jours du profil Régulier sont exacts. 6 corrections avant le Volet B.

## 1. BLOQUANTS
1.1 Formules perdues : ton LaTeX n'a pas survécu au copier-coller. Renvoie en TEXTE BRUT (ex. HP = 100 + 18 * (L - 1)) :
  - stats du joueur (PV, ATK, DEF) ;
  - formule de dégâts complète (avec la mitigation ARMOR_K) ;
  - PV et ATK des monstres ;
  - DPS et PV des suiveurs ;
  - facteur de compression κ de la greffe.
1.2 Niveau de combat : il n'y a pas de niveau global. Confirme que L = niveau de Combattant, et que les autres vocations n'ajoutent que leurs bonus passifs.
1.3 Densité ≠ zone : dans le socle, la densité I–V est un RÉGLAGE du joueur (endgame). Sépare :
  - Niveau de zone = fixé par l'isolat (tes tranches de 10 niveaux, validées).
  - Densité I–V = choisie par le joueur, multiplie stats des monstres, XP, Cendre Vive et drops.
  Refais les tables 3.1 et 3.2 avec cette séparation (densité I par défaut pour la progression normale).

## 2. À RECALIBRER
2.1 Oubli trop rapide : en densité I, Oubli 2 arrive à 6 min 40, donc presque chaque expédition standard (6–8 min) se termine en Oubli 2. Cible : une expédition standard finit au pire en Oubli 1. Oubli 2 doit sanctionner une exposition prolongée ou une densité haute.
2.2 Écart Assidu / Régulier trop faible : 2,3× le temps de jeu pour +19 % d'XP, c'est démotivant. Cible : Régulier ≈ 12 mois, Assidu ≈ 9 mois (ratio ≈ 1,33). Pause café inchangé.
2.3 XP de repos : réserve commune à toutes les vocations ou une par vocation ? Je propose UNE réserve commune, consommée par la vocation qui gagne de l'XP. Recalcule les profils en conséquence.

## 3. À DÉFINIR ET VÉRIFIER
3.1 Définis la métrique « Puissance totale » (je propose : DPS effectif × PV effectifs) et montre le calcul Commun vs Légendaire à ilvl 1, 25, 50. Mon calcul sur l'ATK seule donne ≈ +28 %, pas +40 %.
3.2 Pity Légendaire : avec ~3 Éclats/expédition, un hard cap à 45 donne un Légendaire tous les ~15 jours dès la densité I. Trop généreux ? Propose un pity qui dépend de la densité.
3.3 Unité de cargaison « kg » : nouvelle unité, OK, mais donne la capacité de départ du joueur et des suiveurs.

## 4. RÉPONSES À TES 5 QUESTIONS
1. Tranches de 10 niveaux par isolat : oui, séparées de la densité (point 1.3).
2. Maîtrise après le niveau 50 : oui, récompenses utilitaires ou cosmétiques uniquement, aucune stat (pas de +1 PV).
3. Bascule automatique de vocation selon le geste : oui.
4. Rendement dégressif par segment : non, ça demande un état par segment. À la place : un compteur d'expéditions du jour (daily_runs) ; à partir de la 3e, Cendre Vive et XP de kills à 50 %. Remise à zéro à minuit local.
5. Or en croissance linéaire douce : oui (Volet B).

## 5. FORMAT DE TA RÉPONSE
1. Formules du point 1.1 en texte brut, chaque variable définie.
2. Tables 3.1, 3.2, 3.3 corrigées.
3. Simulation des 3 profils mise à jour.
4. Delta uniquement pour balance_a.gd (constantes modifiées ou ajoutées).
5. Max 3 questions ouvertes.
Pas d'or ni de prix (Volet B).

— Claude
```

## Réponse d'Argon au n°5 (Volet A) — texte brut

```text
1. DÉCISIONS DE DESIGN : VOCATIONS & ARCHITECTURE D'XP (3.1)
1.1 Liste complète des 6 Vocations du joueur et symétrie avec les 6 Aptitudes PNJ
Pour maintenir une symétrie entre le joueur et le village sans créer de doublon inutile (le joueur n'ayant pas besoin d'une vocation « Négoce » séparée), les 6 Vocations du joueur et les 6 Aptitudes des PNJ s'articulent ainsi :

Vocation du Joueur	Périmètre	Aptitude PNJ correspondante (Délégation)	Bonus passif permanent par niveau de Vocation (appliqué au joueur)
1. Combattant	Tranche	Garde & Escorte	+2 PV max et +0.3 ATK de base par niveau
2. Mineur	Tranche	Extraction (Minage)	+0.3 DEF de base et +0.2 kg de capacité de Cargaison par niveau
3. Forgeron	Tranche	Forge & Ouvrage	+0.2% de dégâts d'arme et +1 pt de budget de réparation par niveau
4. Bûcheron	Hors tranche	Extraction (Coupe)	+1.5 PV max et +0.15% de chance de critique par niveau
5. Pêcheur-Herboriste	Hors tranche	Collecte & Pêche	+0.2% de vitesse d'attaque et +0.3% d'efficacité des soins par niveau
6. Cuisinier	Hors tranche	Cuisine & Remèdes	+0.5% de durée des Plats Chauds et −0.3% de drain de Lanterne par niveau
(Action au Comptoir)	Tranche	Négoce (6e aptitude PNJ)	(Pas de barre d'XP joueur : régi par le niveau de boutique et le Lien PNJ)
1.2 Vocation unique ou parallèle ? (Décision tranchée)
Décision : Toutes les vocations sont actives en parallèle par bascule contextuelle automatique (Contextual Auto-Switch), avec une barre d'XP séparée par vocation (Niveaux 1 à 50 chacune).

Justification UX (Z Fold 8) : En mode Plié à un pouce, obliger le joueur à ouvrir un menu pour changer de classe avant de frapper un filon de fer est une friction rédhibitoire. Frapper un monstre utilise l'arme et crédite l'XP de Combattant ; tapoter un filon sort automatiquement la pioche et crédite l'XP de Mineur ; forger au village crédite l'XP de Forgeron. Les bonus passifs ci-dessus garantissent que monter ses métiers d'artisanat renforce aussi le personnage en Brume (ADN Fantasy Life).

1.3 Sources d'XP et pondération par session standard (Base Densité I)
Catégorie de Vocation	Source primaire (~75-80 % du gain)	Source secondaire (~20-25 % du gain)	Source de subsistance (Village seul / Sans Cendre Vive)
Combattant	Monstres normaux (25 XP) & Élites (120 XP)	Fiche de Chasse/Escorte (180 XP) & Boss (350 XP)	Mannequin / Défense de porte (15 XP, plafonné)
Récolte (Mineur, Bûcheron, Pêcheur)	Gisements de Brume (90 XP / nœud récolté)	Fiche de Rupture boutique (180 XP)	Gisement Tier 0 du village (15 XP, max 6/jour)
Artisanat (Forgeron, Cuisinier)	Craft avec Cendre Vive (150 XP, ou 180 XP si mini-jeu Déplié réussi)	Fiche de Commande Spéciale (150 XP)	Craft sans Cendre Vive (20%=30 XP)
2. FORMULES MATHÉMATIQUES (3.2 À 3.5)
2.1 Courbe d'XP et XP de Repos (3.2)
Pour permettre au simulateur headless de calculer l'XP cumulée en temps constant 
O(1) sans boucle, la courbe suit un polynôme du second degré exact :

XP requise pour passer du niveau 
L au niveau 
L+1 (
L∈{1…49}) :

XP 
req
​
 (L)=15L 
2
 +85L+100
XP cumulée exacte au niveau 
L (forme fermée 
O(1)) :

XP 
cum
​
 (L)= 
2
5(L−1)L(2L−1)
​
 + 
2
85(L−1)L
​
 +100(L−1)
Multiplicateur de gain d'XP selon la Densité de Brume 
D∈{1…5} :

M 
XP
​
 (D)=1.00+0.25×(D−1)
XP de Repos (Hors-ligne) :

Accumulation : 
R 
gain
​
 (Δt,D)=min(12.0,Δt 
heures
​
 )×30×M 
XP
​
 (D) (plafond à 
12 h, soit 
360×M 
XP
​
 (D) XP en réserve).

Consommation : Chaque gain d'XP active 
XP 
act
​
  puise dans la réserve de repos à hauteur de 
+50% (
XP 
final
​
  =1.5×XP 
act
​
  jusqu'à épuisement de la réserve).

2.2 Combat, Suiveurs, Sang-Froid et Oubli (3.3)
Statistiques du joueur au niveau 
L∈{1…50} :

PV 
max
​
 (L)=⌊(100+18(L−1)+PV 
e
ˊ
 quip
​
 +PV 
voc
​
 )×M 
engourdi
​
 ⌋

ATK 
tot
​
 (L)=⌊(12+2.5(L−1)+ATK 
arme
​
 +ATK 
voc
​
 )×(1+Bonus 
ATK%
​
 )×M 
engourdi
​
 ⌋

DEF 
tot
​
 (L)=⌊5+1.5(L−1)+DEF 
e
ˊ
 quip
​
 +DEF 
voc
​
 ⌋

où 
M 
engourdi
​
 =0.80 si le statut Engourdi (post-évacuation) est actif, sinon 
1.00.

Formule de dégâts d'un coup :

Mitigation= 
DEF 
cible
​
 +50+10L 
attaquant
​
 
DEF 
cible
​
 
​
 

DMG=⌊ATK 
tot
​
 ×M 
comp
​
 ×(1−Mitigation)×M 
elem
​
 ×M 
crit
​
 ⌋
M 
comp
​
  : Auto-attaque 
=1.00 | Aptitude 1 (CD 
6 s) 
=2.20 | Aptitude 2 (CD 
14 s) 
=3.50. Chaque auto-attaque touchée réduit les CD actifs de 
0.2 s.

M 
elem
​
  : Avantage 
=1.25 | Neutre 
=1.00 | Résistance 
=0.80.

M 
crit
​
  : 
1.50+Bonus 
CritDMG
​
  si coup critique (taux de base 
5%, plafond 
60%), sinon 
1.00.

Statistiques des Monstres (Niveau de segment 
L 
m
​
 ∈{1…50}, Densité 
D∈{1…5}) :

Multiplicateur de sur-densité : 
M 
stat
​
 (D)=1.00+0.15×(D−1)

PV 
mob
​
 (L 
m
​
 ,D,R 
o
ˆ
 le)=⌊(95+29(L 
m
​
 −1))×M 
stat
​
 (D)×K 
PV
​
 (R 
o
ˆ
 le)⌋

ATK 
mob
​
 (L 
m
​
 ,D,R 
o
ˆ
 le)=⌊(10+2.2(L 
m
​
 −1))×M 
stat
​
 (D)×K 
ATK
​
 (R 
o
ˆ
 le)⌋

Coefficients de rôle : Normal (
K 
PV
​
 =1.0,K 
ATK
​
 =1.0) | Élite Porteur de Braise (
K 
PV
​
 =4.5,K 
ATK
​
 =1.6) | Boss de route (
K 
PV
​
 =22.0,K 
ATK
​
 =2.4).

Suiveurs PNJ (1 à 3 suiveurs, étoile Garde & Escorte 
E∈{0…5}) :

DPS 
suiveur
​
 (E)=DPS 
base_ 
e
ˊ
 quip
​
 ×(0.25+0.05E)×(1+0.10N 
liens
​
 )
où 
N 
liens
​
 ∈{0,1,2} est le nombre de paires d'amis dans l'escouade (chaque suiveur fournit entre 
8% et 
17% du DPS solo du joueur ; un groupe complet de 3 suiveurs représente ~35 % du DPS total du convoi).

Flammes de la Lanterne & Paliers d'Oubli (Base 
100 pts) :

Drain hors route pavée : 
Drain 
flamme
​
 (D)=0.20+0.05(D−1) pts/s.

Seuils : 
[100…50] = Flamme Vive | 
[49…20] = Palier d'Oubli 1 (perte mini-carte/fil d'Ariane, Éclats Voilés) | 
<20 = Palier d'Oubli 2 (désactivation de 
N 
liens
​
  et malus de vitesse de déplacement de 
−15%, passant de 
140 à 
119 px/s).

2.3 Budget de Loot, Point-Buy et Compression de Greffe (3.4)
Pour respecter strictement l'écart 
≤+40% entre Commun et Légendaire au même niveau d'objet (
ilvl∈{1…50}), 
70% de la puissance vient de la stat de base de l'arme et 
30% de son budget d'affixes 
B(ilvl,R) :

Attaque de base d'une arme : 
ATK 
arme
​
 (ilvl)=⌊10+4.5(ilvl−1)⌋

Budget de Point-Buy d'affixes : 
B(ilvl,R)=⌊(12+2.8(ilvl−1))×M 
raret 
e
ˊ
 
​
 (R)⌋

Diviseur d'échelle pour les affixes en pourcentage : 
S(ilvl)=1.00+0.18(ilvl−1)
(Une stat en % coûte 
C 
base
​
 ×S(ilvl) points de budget par point de pourcentage, garantissant que les % restent constants du niveau 1 au niveau 50).

Formule de Compression sur l'Établi de Greffe :
Lorsqu'un affixe greffé de coût 
P 
greffe
​
  (plafonné à 
0.60×B 
h
​
 ) est inséré sur une arme hôte de budget 
B 
h
​
 , tous les autres affixes 
P 
i
​
  de l'arme hôte sont multipliés par le facteur de compression 
κ :

κ= 
∑ 
i

=greffe
​
 P 
i
​
 
B 
h
​
 −min(P 
greffe
​
 ,0.60B 
h
​
 )
​
 ⟹P 
i
′
​
 =⌊P 
i
​
 ×κ⌋
3. TABLES DE VALEURS AUX PALIERS DEMANDÉS
3.1 Table de Progression d'XP (Niveaux 1 à 50)
Niveau (L)	Densité cible (D)	XP 
req
​
 (L) (vers L+1)	XP 
cum
​
 (L) (Total depuis Nv.1)	Gain Quotidien Profil Régulier	Jours estimés (Régulier 15m/j)	Jours estimés (Assidu 35m/j)
1	I (×1.00)	200	0	1260 XP/j	J+0	J+0
5	I (×1.00)	900	1700	1260 XP/j	J+1,3	J+1,1
10	I → II	2450	9000	1260→1575 XP/j	J+7,1	J+6,0
20	II → III	7800	55100	1575→1890 XP/j	J+36,4	J+30,6
30	III → IV	16150	168200	1890→2205 XP/j	J+96,2	J+80,9
40	IV → V	27500	378300	2205→2520 XP/j	J+191,5	J+160,9
50 (Max)	V (×2.00)	Maîtrise (42600)	715400	2520 XP/j	J+325,3 (10,8 mois)	J+273,3 (9,1 mois)
3.2 Table de Combat & Cibles de TTK (Joueur équipé rareté Rare de son niveau vs Monstres)
Niveau (L=L 
m
​
 )	Densité (D)	PV Joueur (Équipé)	DPS Solo Effectif Joueur	PV Monstre Normal (TTK Solo)	PV Élite Braise (TTK Solo)	PV Boss de Route (TTK Solo)	Drain Flamme (Oubli 1 / Oubli 2)
1	I	130 PV	32 DPS	95 (3,0 s)	427 (13,3 s)	2090 (65,3 s)	0.20/s (4m10s / 6m40s)
10	I	360 PV	120 DPS	356 (3,0 s)	1602 (13,4 s)	7832 (65,3 s)	0.20/s (4m10s / 6m40s)
20	II	680 PV	245 DPS	743 (3,0 s)	3343 (13,6 s)	16346 (66,7 s)	0.25/s (3m20s / 5m20s)
30	III	1080 PV	395 DPS	1216 (3,1 s)	5474 (13,8 s)	26763 (67,8 s)	0.30/s (2m46s / 4m26s)
40	IV	1560 PV	570 DPS	1777 (3,1 s)	7997 (14,0 s)	39098 (68,6 s)	0.35/s (2m22s / 3m48s)
50	V	2150 PV	775 DPS	2425 (3,1 s)	10915 (14,1 s)	53363 (68,9 s)	0.40/s (2m05s / 3m20s)
3.3 Table du Budget de Loot 
B(ilvl,R), Écart de Puissance et Probabilités de Drop
Rareté (Forme UI)	M 
raret 
e
ˊ
 
​
 	Nb Affixes	Budget B (ilvl 1)	Budget B (ilvl 25)	Budget B (ilvl 50)	Puissance Totale vs Commun	Drop D=I	Drop D=III	Drop D=V
Commun (◯)	1.00	1	12 pts	79 pts	149 pts	Référence (100%)	62,0%	38,0%	15,0%
Bon (△)	1.35	2	16 pts	106 pts	201 pts	+4,5%	26,0%	32,0%	28,0%
Rare (⋄)	1.80	3	21 pts	142 pts	268 pts	+10,5%	9,5%	20,0%	33,0%
Épique (\hexagon)	2.40	4	28 pts	190 pts	358 pts	+18,5%	2,0%	7,5%	18,0%
Légendaire (★)	3.00	4+Unique	36 pts	237 pts	447 pts	+40,0% (Plafond)	0,5%	2,5%	6,0%
Primordial (\✦)	3.80	4+Prim.	—	—	566 pts	+49,5% (Crues)	0,0%	0,0%	Crues : 3,0%
3.4 Table des 12 Affixes de la Tranche Verticale (Coût dans le Budget 
B)
ID Affixe	Nom de l'Affixe	Type de Scaling	Gain par Point de Budget (ou Coût unitaire)	Plafond par Objet
FLAT_ATK	Force de Braise	Plat	+0.50 ATK par point dépensé	Max 50% de B
FLAT_HP	Vigueur de l'Âtre	Plat	+3.00 PV max par point dépensé	Max 50% de B
FLAT_DEF	Écorce de Fer	Plat	+0.40 DEF par point dépensé	Max 50% de B
PCT_ATK	Férocité	Proportionnel (S)	Coût =2.0×S(ilvl) pts pour +1% ATK	+25% max
PCT_ASPD	Cadence	Proportionnel (S)	Coût =2.5×S(ilvl) pts pour +1% Vitesse d’ATK	+20% max
PCT_CRIT_RATE	Acuité	Proportionnel (S)	Coût =3.0×S(ilvl) pts pour +1% Chance Crit	+18% max
PCT_CRIT_DMG	Dévastation	Proportionnel (S)	Coût =1.5×S(ilvl) pts pour +1% D 
e
ˊ
 g 
a
ˆ
 ts Crit	+40% max
PCT_MSPD	Pas Léger	Proportionnel (S)	Coût =3.0×S(ilvl) pts pour +1% Vitesse D 
e
ˊ
 pl.	+15% max
ELEM_BRAISE	Tison (Élément Feu)	Plat	Convertit les dégâts en Braise +0.35 ATK/pt	Exclusif élément
ELEM_GIVRE	Gelée (Élément Glace)	Plat	Convertit les dégâts en Givre +0.35 ATK/pt	Exclusif élément
CARGO_CAP	Dos Solide	Proportionnel (S)	Coût =2.0×S(ilvl) pts pour +1 kg Cargaison	+12 kg max
MINE_YIELD	Veinard (Récolte)	Proportionnel (S)	Coût =2.0×S(ilvl) pts pour +1% Rendement Mine	+25% max
3.5 Table de la Lanterne-Mère (Cendre Vive & Sacoche à Éclats)
Niveau de Lanterne	Isolat de Déblocage	Plafond Cendre Vive	Capacité Sacoche à Éclats	Coût Cendre Vive / Craft Standard	Gain Moyen / Expédition Standard (6-8 min)
Niveau 1	Clair-Foyer (Tranche)	150 unit 
e
ˊ
 s	6  
E
ˊ
 clats	20 unit 
e
ˊ
 s (7 crafts max)	100 unit 
e
ˊ
 s (48 mobs + 24 nœuds + 28 élite)
Niveau 2	Tourbière des Lanternes	220 unit 
e
ˊ
 s	8  
E
ˊ
 clats	20 unit 
e
ˊ
 s	115 unit 
e
ˊ
 s
Niveau 3	Pic-Forgez	300 unit 
e
ˊ
 s	10  
E
ˊ
 clats	20 unit 
e
ˊ
 s	130 unit 
e
ˊ
 s
Niveau 4	Port-Sardine	400 unit 
e
ˊ
 s	12  
E
ˊ
 clats	20 unit 
e
ˊ
 s	145 unit 
e
ˊ
 s
Niveau 5	Citadelle d'Obsidienne	500 unit 
e
ˊ
 s	15  
E
ˊ
 clats	20 unit 
e
ˊ
 s	160 unit 
e
ˊ
 s
4. FICHIER DE CONSTANTES GDSCRIPT (balance_a.gd)
GDScript
class_name BalanceA
extends RefCounted

# ==============================================================================
# 1. PROGRESSION & COURBE D'XP (NIVEAUX 1 A 50)
# ==============================================================================
const MAX_VOCATION_LEVEL: int = 50
const XP_QUAD_A: int = 15
const XP_LIN_B: int = 85
const XP_CONST_C: int = 100
const XP_MASTERY_STEP: int = 42600

const DENSITY_XP_MULTIPLIERS: Array[float] = [1.00, 1.25, 1.50, 1.75, 2.00]

# Sources d'XP de base (Densite I)
const XP_KILL_NORMAL: int = 25
const XP_KILL_ELITE: int = 120
const XP_KILL_BOSS: int = 350
const XP_GATHER_MIST_NODE: int = 90
const XP_GATHER_VILLAGE_SUBSISTENCE: int = 15
const XP_CRAFT_WITH_CENDRE: int = 150
const XP_CRAFT_EXCELLENCE_BONUS: float = 1.20
const XP_CRAFT_NO_CENDRE_RATIO: float = 0.20
const XP_BOARD_FICHE_COMPLETE: int = 180

# XP de Repos (Hors-ligne)
const RESTED_XP_PER_HOUR_BASE: float = 30.0
const RESTED_XP_MAX_HOURS: float = 12.0
const RESTED_XP_BONUS_RATE: float = 0.50

# ==============================================================================
# 2. COMBAT, JOUEUR, MONSTRES & SUIVEURS
# ==============================================================================
const PLAYER_BASE_HP: int = 100
const PLAYER_HP_PER_LVL: int = 18
const PLAYER_BASE_ATK: float = 12.0
const PLAYER_ATK_PER_LVL: float = 2.5
const PLAYER_BASE_DEF: float = 5.0
const PLAYER_DEF_PER_LVL: float = 1.5
const PLAYER_BASE_MSPD: float = 140.0
const PLAYER_BASE_CRIT_RATE: float = 0.05
const PLAYER_MAX_CRIT_RATE: float = 0.60
const PLAYER_BASE_CRIT_DMG: float = 1.50
const NUMB_STATUS_PENALTY_MULT: float = 0.80
const NUMB_STATUS_DURATION_SEC: float = 1800.0

# Esquive (Swipe) & Aptitudes
const DODGE_DURATION_SEC: float = 0.25
const DODGE_IFRAME_SEC: float = 0.20
const DODGE_COOLDOWN_SEC: float = 1.80
const DODGE_DISTANCE_PX: float = 48.0
const SKILL_1_COOLDOWN_SEC: float = 6.0
const SKILL_1_DMG_MULT: float = 2.20
const SKILL_2_COOLDOWN_SEC: float = 14.0
const SKILL_2_DMG_MULT: float = 3.50
const AUTO_HIT_CD_REDUCTION_SEC: float = 0.20

# Mitigation & Elements
const ARMOR_K_BASE: float = 50.0
const ARMOR_K_PER_LVL: float = 10.0
const ELEM_ADVANTAGE_MULT: float = 1.25
const ELEM_RESIST_MULT: float = 0.80

# Monstres
const DENSITY_STAT_MULTIPLIERS: Array[float] = [1.00, 1.15, 1.30, 1.45, 1.60]
const MOB_BASE_HP: int = 95
const MOB_HP_PER_LVL: int = 29
const MOB_BASE_ATK: float = 10.0
const MOB_ATK_PER_LVL: float = 2.2
const MOB_ROLE_HP_MULT: Dictionary = {"NORMAL": 1.0, "ELITE": 4.5, "BOSS": 22.0}
const MOB_ROLE_ATK_MULT: Dictionary = {"NORMAL": 1.0, "ELITE": 1.6, "BOSS": 2.4}

# Suiveurs PNJ (Max 3)
const MAX_FOLLOWERS: int = 3
const FOLLOWER_BASE_DPS_COEFF: float = 0.25
const FOLLOWER_STAR_DPS_COEFF: float = 0.05
const FOLLOWER_SYNERGY_PAIR_BONUS: float = 0.10
const FOLLOWER_HP_MULT_VS_PLAYER: float = 1.20

# Jauge de Sang-Froid (Etat-Major Deplie)
const COLDBLOOD_MAX: float = 100.0
const COLDBLOOD_MIN_TO_ACTIVATE: float = 30.0
const COLDBLOOD_OPEN_COST: float = 15.0
const COLDBLOOD_DRAIN_PER_SEC: float = 10.0
const COLDBLOOD_SLOWMO_TIMESCALE: float = 0.05
const COLDBLOOD_GAIN_ON_HIT: float = 2.5
const COLDBLOOD_GAIN_ON_PERFECT_DODGE: float = 8.0
const COLDBLOOD_GAIN_ON_KILL: float = 6.0

# Lanterne-Mere & Paliers d'Oubli
const LANTERN_FLAME_MAX: float = 100.0
const LANTERN_DRAIN_PER_SEC_BY_DENSITY: Array[float] = [0.20, 0.25, 0.30, 0.35, 0.40]
const OBLIVION_STAGE_1_THRESHOLD: float = 50.0
const OBLIVION_STAGE_2_THRESHOLD: float = 20.0
const OBLIVION_STAGE_2_MSPD_MULT: float = 0.85
const FLAME_RESTORE_ELITE_KILL: float = 35.0
const FLAME_RESTORE_TAVERN_BROTH: float = 50.0
const FLAME_RESTORE_COOK_MEAL: float = 100.0

# ==============================================================================
# 3. BUDGET DE LOOT, GREFFE & CENDRE VIVE
# ==============================================================================
const WEAPON_BASE_ATK_START: float = 10.0
const WEAPON_BASE_ATK_PER_ILVL: float = 4.5
const LOOT_BUDGET_BASE: float = 12.0
const LOOT_BUDGET_PER_ILVL: float = 2.8
const AFFIX_SCALING_PER_ILVL: float = 0.18

const RARITY_BUDGET_MULT: Dictionary = {
	"COMMON": 1.00,
	"GOOD": 1.35,
	"RARE": 1.80,
	"EPIC": 2.40,
	"LEGENDARY": 3.00,
	"PRIMORDIAL": 3.80
}
const RARITY_AFFIX_COUNT: Dictionary = {
	"COMMON": 1, "GOOD": 2, "RARE": 3, "EPIC": 4, "LEGENDARY": 4, "PRIMORDIAL": 4
}

const GRAFT_MAX_SINGLE_AFFIX_SHARE: float = 0.60
const HEIRLOOM_BUDGET_BONUS_MULT: float = 1.15
const SUPERIOR_QUALITY_ILVL_BONUS: int = 2
const SUPERIOR_CHANCE_BASE: float = 0.20
const SUPERIOR_CHANCE_MINIGAME: float = 0.45

# Drop d'Eclats & Pity Timer
const SHARD_DROP_CHANCE_NORMAL: float = 0.08
const SHARD_DROP_CHANCE_ELITE: float = 1.00
const SHARD_DROP_COUNT_BOSS: int = 2
const PITY_LEGENDARY_SOFT_START: int = 30
const PITY_LEGENDARY_HARD_CAP: int = 45

# Cendre Vive & Sacoche par Niveau de Lanterne (1 a 5)
const LANTERN_CENDRE_CAP: Array[int] = [150, 220, 300, 400, 500]
const LANTERN_SHARD_BAG_CAP: Array[int] = [6, 8, 10, 12, 15]
const CENDRE_COST_STANDARD_CRAFT: int = 20
const CENDRE_GAIN_NORMAL_MOB: int = 2
const CENDRE_GAIN_MIST_NODE: int = 3
const CENDRE_GAIN_ELITE_MOB: int = 28
const CENDRE_GAIN_BOSS_MOB: int = 60

# Fonctions utilitaires O(1) pour le simulateur Headless
static func get_xp_required(level: int) -> int:
	if level >= MAX_VOCATION_LEVEL:
		return XP_MASTERY_STEP
	return XP_QUAD_A * level * level + XP_LIN_B * level + XP_CONST_C

static func get_cumulative_xp(level: int) -> int:
	var n: int = clampi(level - 1, 0, MAX_VOCATION_LEVEL - 1)
	return (5 * n * (n + 1) * (2 * n + 1)) / 2 + (85 * n * (n + 1)) / 2 + 100 * n
5. VÉRIFICATION PAR SIMULATION DES 3 PROFILS JOUEURS (SECTION 4)
Simulation déterministe d'une vocation principale et d'une vocation d'artisanat sur 365 jours avec la formule fermée get_cumulative_xp(level) :

Profil de Joueur	Routine Quotidienne Modélisée	Niveau à J+30 (XP cumulée)	Niveau à J+90 (XP cumulée)	Niveau à J+180 (XP cumulée)	Niveau à J+365 (XP cumulée)	Date exacte du Niveau 50 (715400 XP)
1. Pause Café

(3 × 5 min/j, Plié, quasi 0 Brume)

6 récoltes de subsistance au village + 6 crafts sans Cendre Vive (à 20%=30 XP) + XP de Repos.

Gain : 405→506 XP/j.

Niveau 11

(12950 XP)

Niveau 18

(43320 XP)

Niveau 24

(88880 XP)

Niveau 31

(182540 XP)

J+1 417

(~3,8 ans — ne bloque jamais mais progresse à 25 % du rythme)

2. Régulier

(1 session std 15 min/j)

1 expédition standard (6-8 min) + 1 fiche prioritaire + 5 crafts avec Cendre Vive (100 u.) + 100 % XP de Repos (12 h).

Gain : 1260×M 
XP
​
 (D) XP/j.

Niveau 18

(45060 XP)

Niveau 29

(156400 XP)

Niveau 39

(352980 XP)

Niveau 50

(816200 XP, +2 paliers Maîtrise)

J+325

(10,8 mois)

(Cible 9-12 mois validée)

3. Assidu

(1 session longue 30m + 1 courte 5m/j)

2 expéditions (ou 1 longue) + fiches + 7 crafts avec Cendre Vive + 3 crafts sans Cendre Vive + XP de Repos saturée.

Gain : 1500×M 
XP
​
 (D) XP/j.

Niveau 20

(54000 XP)

Niveau 31

(192080 XP)

Niveau 42

(435600 XP)

Niveau 50

(991400 XP, +6 paliers Maîtrise)

J+273

(9,1 mois)

(Cible 9-12 mois validée)

6. HYPOTHÈSES POSÉES & QUESTIONS OUVERTES (MAX 5)
Échelle d'ilvl des 5 Isolats (Hypothèse posée) : J'ai aligné les 5 Isolats et les 5 paliers de Densité sur des tranches de 10 niveaux : Clair-Foyer (Nv. 1–10), Tourbière des Lanternes (Nv. 11–20), Pic-Forgez (Nv. 21–30), Port-Sardine (Nv. 31–40), Citadelle d'Obsidienne (Nv. 41–50). Une fois le Phare débloqué, monter la Densité d'un isolat de bas niveau aligne son ilvl sur le niveau actuel du joueur. Valides-tu ce découpage ?

Paliers de Maîtrise post-Niveau 50 : Pour que les profils Assidu (dès le mois 9) et Régulier (dès le mois 11) ne voient jamais leur barre d'XP se figer, j'ai ajouté une boucle infinie de Maîtrise tous les 
42600 XP au-delà du niveau 50 (offrant par exemple 1 Éclat Épique/Légendaire garanti et 
+1 PV symbolique). On garde ?

Bascule contextuelle des Vocations : Valides-tu le déclenchement 100 % automatique de la vocation selon le geste (frapper un monstre = Combattant, taper un filon = Mineur, forger = Forgeron), ce qui nous économise un bouton de changement de classe sur l'UI Pliée ?

Rendement dégressif de la 2e expédition quotidienne (Profil Assidu) : Pour empêcher qu'un joueur qui joue 2 heures le dimanche ne finisse le jeu en 2 mois, le gain de Cendre Vive sur un même segment déjà nettoyé dans la journée passe à 
50% lors des passages suivants (incitant soit à changer de route, soit à attendre le lendemain). Cela te convient-il ?

Transition vers le Volet B : Dans le Volet B, la valeur en Or d'un objet ou d'un matériau devra être indexée sur son ilvl et son tiers de Densité 
D∈{1…5}. Souhaites-tu que l'économie d'Or suive une croissance linéaire douce (comme nos multiplicateurs d'XP de 
1.0× à 
2.0×) pour éviter toute inflation à 6 chiffres en fin de jeu ?
```

## Message n°5 — prompt du Volet A

```text
# PROMPT VOLET A — Combat, XP, Vocations, Budget de Loot
Claude → Argon — Message n°5. Base : SOCLE DE DESIGN v2 (ci-joint).

Note : j'ai tranché 4 points sans aller-retour, ils sont dans le v2 :
- Règle d'or ajoutée en A1 (le danger ne vient jamais de la gestion du village).
- Plafond de Cendre Vive : Lanterne seule. L'Âtre fixe rayon, population, postes.
- Égaré pendant une évacuation : le Cocon reste au sol comme Colis Égaré.
- Tranche verticale : population fixe à 5, l'Âtre niv. 2 n'ouvre que rayon et postes.
- Cadence renommée : Paisible / Normal / Forge ardente (évite la confusion avec le Coup de feu du comptoir).

---

## 1. OBJECTIF
Sortir toutes les formules et valeurs d'équilibrage du combat, de la progression et du loot.
Le Volet B (or, prix, hors-ligne, Moral, stocks) viendra ensuite et s'appuiera sur tes valeurs.

## 2. CONTRAINTES FIXES (non négociables)
- Niveau max 50 par vocation, atteint en 9–12 mois à 15–30 min/jour.
- Session standard 15 min = 1 expédition de 6–8 min. Session longue 30 min = 2 standard ou 1 longue (15–20 min). Session courte 5 min = village seul, pliée.
- Combat plié à un pouce : auto-attaque à l'arrêt, swipe = esquive, 2 aptitudes. Jamais d'aptitude bloquée.
- 3 suiveurs PNJ max. Blessure, jamais de mort. Échec joueur = évacuation, statut Engourdi.
- Craft avec Cendre Vive = 100 % XP ; sans = 20 % XP.
- Loot en point-buy strict. 5 types × 5 Écoles × 3 pièces. Commun → Légendaire, Primordial en endgame. Héritage indestructible.
- RNG : FNV-1a 64 + PCG32, un RNG par système.
- Densité de Brume I–V. Oubli en 2 paliers (malus de vitesse au palier 2).

## 3. CE QUE TU DOIS PRODUIRE

### 3.1 Vocations
- Liste complète des vocations (tranche : Combattant, Mineur, Forgeron ; hors tranche : Cuisinier + les autres). Lien avec les 6 aptitudes PNJ.
- Une seule vocation active ou toutes en parallèle ? XP partagée ou séparée ? Tranche.
- Sources d'XP par vocation (kills, récolte, craft, fiches) et leur poids.

### 3.2 Courbe d'XP
- Formule XP(niveau) 1→50.
- Table aux niveaux 1, 5, 10, 20, 30, 40, 50 : XP requise, XP cumulée, jours estimés.
- XP de repos (hors-ligne) : gain, plafond.
- Preuve que 1→50 tient dans 9–12 mois pour les 3 profils de la section 4.

### 3.3 Combat
- Stats de base du joueur et scaling par niveau : PV, dégâts, défense, vitesse d'attaque, vitesse de déplacement.
- Formule de dégâts (attaque, défense, élément, critique).
- Monstres : PV et dégâts selon niveau du segment et densité I–V. Rôles : normal, Élite (porteur de braise), Boss de route.
- Cibles de TTK : propose les tiennes (ma suggestion : normal 2–4 s, Élite 10–15 s, Boss 60–90 s en solo).
- Esquive : i-frames, recharge. 2 aptitudes : recharge, coût.
- Suiveurs : part des dégâts du groupe, scaling selon aptitude Garde & Escorte et équipement.
- Jauge de Sang-Froid : gain par action, coût et durée de l'État-major.
- Oubli : vitesse de baisse de la flamme selon densité, malus de vitesse du palier 2, durée de restauration.

### 3.4 Budget de loot
- Budget de puissance par (niveau d'objet, rareté). Formule + table.
- Coût de chaque affixe dans le budget. Liste des affixes de base (10–15 max dans la tranche).
- Greffe : règle de compression des autres affixes.
- Taux de drop par rareté selon densité I–V et type d'ennemi. Mécanisme anti-malchance si besoin.
- Différence de puissance Commun vs Légendaire au même niveau (ma suggestion : ≤ +40 %).
- Arme à héritage : budget, affixe nommé.
- Qualité Supérieure (craft avec Cendre Vive) : bonus et probabilité.

### 3.5 Cendre Vive et Sacoche
- Gain par expédition (passif + monstres + nœuds), selon densité.
- Coût en Cendre Vive par craft.
- Plafond de départ et par niveau de Lanterne.
- Capacité de la Sacoche à Éclats : départ et par niveau de Lanterne.

## 4. VÉRIFICATION PAR PROFILS
Simule 3 profils et donne pour chacun : niveau atteint à J+30, J+90, J+180, J+365, et date du niveau 50.
- Pause café : 3 × 5 min/jour, quasi jamais en Brume.
- Régulier : 1 session standard/jour.
- Assidu : 1 session longue/jour + 1 courte.
Le Pause café doit progresser (via craft sans Cendre Vive, à 20 %), mais nettement plus lentement.

## 5. FORMAT DE TA RÉPONSE
1. Décisions de design (3.1) en premier, tranchées.
2. Formules en texte simple, chaque variable définie.
3. Tables de valeurs aux paliers demandés.
4. Un bloc de constantes nommées prêt à copier dans un fichier GDScript (balance_a.gd), en SNAKE_CASE.
5. Simulation des 3 profils (section 4).
6. Hypothèses et questions ouvertes à la fin, max 5.
Pas d'or ni de prix : c'est le Volet B.

— Claude
```

## Réponse d'Argon au n°4 — texte brut

```text
1. PARTIE B — DÉCISIONS SUR LES 4 CORRECTIONS
Point	Verdict d'Argon	Décision tranchée & Justification
B1. « Endurance de marche »	Validé	Supprimée. Le contrôle à un pouce façon Archero ne doit pas s'encombrer d'une barre d'endurance de sprint. Le Palier 2 d'Oubli applique uniquement la perte des synergies des suiveurs + un malus de vitesse de déplacement (valeur fixée au Volet A).
B2. Plat Chaud dans la Tranche Verticale	Validé	Tant que la vocation Cuisinier du joueur n'est pas active (hors tranche verticale), la Taverne du village vend un Bouillon de Braise standard préparé par le gérant PNJ. Quand le joueur débloque Cuisinier, ses propres plats surpassent ceux de la Taverne (durée et buffs).
B3. Définition de « Fin de session »	Corrigé (Piège mobile)	
Définir l'expiration par « application fermée ou inactive >10 min » est dangereux sur mobile : si le joueur reçoit un appel téléphonique ou range son Z Fold 8 dans le métro après avoir lu son rapport, il perd son Alerte de Sauvetage.

Règle tranchée : L'Alerte possède un compteur strict de 2 expéditions terminées par le joueur (remaining_runs = 2), totalement indépendant des fermetures de l'application ou du temps d'inactivité. Zéro piège horaire.

B4. Définition du « Moral »	Validé	Intégré et unifié directement dans la refonte des besoins PNJ du module Camp de Base ci-dessous (voir C-I.5 et D1).
2. PARTIE C — AUDIT DU MODULE « CAMP DE BASE » (PALWORLD)
C-I. Éléments pour la Tranche Verticale
#	Élément proposé	Verdict	Critique & Ajustement d'architecture
1	Rayon de l'Âtre (Palbox)	Garder	Excellente fusion Lore/Gameplay. Le niveau du Grand Âtre dicte le rayon constructible (en tuiles), le plafond de population (de 5 à 30) et le plafond de la jauge de Cendre Vive.
2	Aptitudes de travail (0–5)	Modifier	8 domaines, c'est trop dilué et certains (Transport, Soin) sont des sous-fonctions. Réduit à 6 domaines d'aptitudes alignés sur nos vocations et nos boutiques (voir détail en D2).
3	Saisir-déposer en Déplié	Garder	Killer feature ergonomique pour le grand écran interne du Z Fold 8 en Vision d'Architecte.
4	Postes et gisements physiques au village	Modifier (Critique)	Attention au piège Palworld : si le village contient des filons de minerai et des arbres infinis, le joueur n'a plus aucune raison d'aller risquer sa peau en Brume ! Règle : Les gisements internes au village ne produisent que des matériaux de Tier 0 (Subsistance / Bois de chauffe / Pierre brute) ou servent à raffiner ce qui est rapporté de l'extérieur. Les vrais minerais et bois d'œuvre viennent de la Brume et des Avant-postes.
5	Besoins : Faim + Moral + Blessure	Modifier	Évitons d'avoir une jauge de Faim ET une jauge de Moral séparées par PNJ (60 jauges à surveiller sur 30 PNJ). Fusion : Une seule jauge par PNJ, le Moral (0–100), et un état binaire Blessé. La « Faim » est simplement le déclencheur quotidien qui envoie le PNJ manger un plat à la Taverne à midi/soir : s'il mange, son Moral remonte ; si la Taverne est vide, son Moral chute.
6	Politique de travail à 4 crans	Modifier	Remplace l'ancienne politique de A6. On réduit de 4 à 3 crans clairs pour l'UI mobile : Paisible (Moral +, Prod −), Normal (Équilibre stable), Coup de collier (Prod ++, Moral −−).
7	Traits passifs procéduraux (1–2)	Garder	Indispensable pour l'identité façon Palworld / Kairosoft. Remplace les « traits » vagues de A6 et pilote directement la Griffe de l'artisan (A7) quand le PNJ est nommé gérant.
C-II. Éléments après la Tranche Verticale
#	Élément proposé	Verdict	Critique & Ajustement d'architecture
8	Recrutement par sauvetage (Égarés)	Garder	Brillante idée. Porter physiquement un survivant gelé sur son dos à travers la Brume jusqu'au Grand Âtre soude Death Stranding et Palworld.
9	Avant-postes (Brasero amélioré)	Modifier	Pour ne pas créer 10 sous-villages impossibles à gérer sur mobile, un Avant-poste n'est pas un village : c'est un Camp d'Extraction spécialisé (max 2 PNJ + 1 gisement rare de Brume) greffé sur un Brasero une fois la route pavée.
10	Transporteurs dédiés	Supprimer	Dans Palworld, les transporteurs qui ramassent des objets au sol sont la source n°1 de bugs de pathfinding et de chute de FPS. Ici, chaque artisan dépose sa production directement dans le stock de sa boutique à la fin de son cycle, et le DAG gère les flux. Zéro métier « Transporteur ».
11	Mentorat (Apprentissage)	Garder	Très bon puits de temps en Mid/Late Game pour perfectionner un PNJ auquel le joueur s'est attaché sans avoir à le remplacer.
12	Assauts de Givre	Modifier	Aucun monstre ne doit jamais entrer casser la décoration du village (contraire au pilier Animal Crossing et à ta règle A1 « le danger ne vient jamais de la gestion du village »). L'Assaut de Givre se déroule aux Portes du Périmètre (sur le nœud d'entrée du village) : le joueur et ses Gardes repoussent la vague avant qu'elle n'étouffe l'Âtre. En cas d'échec, le rayon de l'Âtre faiblit temporairement (baisse de Moral/Prod), mais zéro bâtiment détruit.
3. PARTIE D — RÉPONSES AUX 6 QUESTIONS SUR LE MODULE
Quelles redondances fusionner ou supprimer avec A6, A7, A8 ?

Supprimé de A6 : Les 4 besoins séparés (énergie, faim, moral, social) 
→ remplacés par Moral (0–100) + état Blessé. La faim et le sommeil deviennent de simples étapes horaires de la routine qui restaurent le Moral.

Supprimé de A6 : La politique « Équilibré / Production / Combat / Exploration » 
→ remplacée par la Cadence de travail à 3 crans (Paisible / Normal / Coup de collier), car la répartition des métiers se fait désormais par le saisir-déposer et le Relais.

Fusionné entre A6 et C2 : Les « affinités et compétences de métier » deviennent les Aptitudes de travail (0–5).

Charge cognitive : faut-il réduire les 8 aptitudes ?

Oui, on verrouille à 6 Aptitudes (notées de 0 à 5 étoiles), immédiatement lisibles sur une fiche PNJ mobile et calquées sur nos boucles :

Forge & Ouvrage (Ateliers, réparation, construction)

Extraction (Mine, coupe de bois)

Collecte & Pêche (Champs, eau, cueillette, pêche)

Cuisine & Remèdes (Taverne, brassage, soin des blessés à l'infirmerie)

Négoce (Gérance de boutique, marges, caravanes)

Garde & Escorte (Combat en expédition, missions du Tableau, défense des Portes)

Moral et grève douce : risque de frustration dans la tranche ?

Règle d'équilibrage : En cadence Normale, tant qu'un PNJ a un lit et un repas quotidien à la Taverne, son Moral remonte plus vite qu'il ne descend (équilibre naturel à 
80/100). La « grève douce » (le PNJ pose son outil et va se chauffer les mains au Grand Âtre) ne survient sous 
20/100 que si le joueur abuse du mode Coup de collier ou laisse la Taverne en rupture prolongée. Dans la tranche verticale, le risque de grève accidentelle est donc nul.

Recrutement par sauvetage : comment un Égaré s'intègre-t-il à la cargaison ?

Un Égaré gelé découvert en Brume est transporté dans un Cocon de Braise. Il n'occupe pas un slot de suiveur actif, mais il occupe 100 % de la capacité de Cargaison d'un porteur (le joueur ou l'un de ses 3 suiveurs doit porter le Cocon sur son dos, obligeant à répartir le reste du butin sur les autres membres du groupe en mode Déplié).

Avant-postes : doublon avec les isolats délivrés ou système distinct ?

Système strictement distinct : Les 5 Isolats sont des cités alliées autonomes (clientes de nos caravanes et émettrices de quêtes). Les Avant-postes sont de simples Braseros d'Extraction situés sur un nœud de route pavée entre deux isolats, où l'on détache 1 ou 2 de nos propres PNJ pour exploiter un filon rare qui n'existe pas à Clair-Foyer.

Placement des bâtiments : grille libre ou emplacements fixes ? Déplacement gratuit ou payant ?

Grille libre par tuiles dans le rayon circulaire du Grand Âtre, et déplacement 100 % GRATUIT et instantané en Vision d'Architecte (Déplié).

Justification : Des emplacements fixes tueraient l'ADN Animal Crossing et l'intérêt du grand écran déplié. Le déplacement gratuit est indispensable : quand le Grand Âtre monte de niveau et que son rayon s'agrandit, le joueur doit pouvoir réorganiser tout son village par plaisir esthétique ou logistique sans jamais être pénalisé en ressources.

4. LIGNES PRÊTES À INSÉRER DANS LE SOCLE v2
Voici les blocs consolidés intégrant les validations de la Partie B et le module Camp de Base audité :

À insérer en A3. Plié / déplié :

Saisir-déposer en Vision d'architecte (Déplié) : Au village, le joueur peut saisir un PNJ au doigt et le déposer directement sur un bâtiment, un gisement ou une boutique pour l'y assigner et verrouiller son poste en un seul geste. Le placement et le déplacement des bâtiments sur la grille libre du village sont gratuits et instantanés en mode Déplié.

À insérer en A4. Monde, logistique, temps :

Rayon du Grand Âtre : La zone habitable et constructible du village est définie par le rayon de chaleur du Grand Âtre. Améliorer l'Âtre repousse la Cendre Grise et augmente : le rayon de la grille constructible, le plafond de PNJ (de 5 à 30), le nombre de postes de travail et le plafond de Cendre Vive de la Lanterne-Mère.

Correction Palier 2 d'Oubli : Le Palier 2 d'Oubli en Brume désactive les synergies des suiveurs et inflige un malus de vitesse de déplacement (aucune jauge d'endurance de marche).

Avant-postes (Hors tranche verticale) : Une fois une route pavée, certains Braseros sur nœuds riches peuvent être améliorés en Braseros d'Extraction (1 à 2 PNJ assignés) qui expédient automatiquement des matériaux rares vers le village via la route.

Assauts de Givre (Hors tranche verticale) : Lors des Crues de Brume hebdomadaires, un assaut annoncé cible les Portes du village (uniquement en session active, jamais hors-ligne, zéro destruction de bâtiment). Défendu par le joueur et ses PNJ Gardes.

À insérer en A6. PNJ :

Recrutement par sauvetage (Hors tranche verticale) : Les nouveaux Citoyens (jusqu'au plafond de 30) sont trouvés en Brume sous forme d'Égarés gelés. Les ramener au Grand Âtre occupe 100 % de la capacité de cargaison d'un porteur du convoi.

Les 6 Aptitudes de travail (0 à 5 étoiles) : Chaque PNJ possède un profil d'aptitudes sur 6 domaines : Forge & Ouvrage, Extraction, Collecte & Pêche, Cuisine & Remèdes, Négoce, Garde & Escorte. L'auto-assignation suit la formule Affinité × Besoin du village × Aptitude. Par mentorat (post-tranche), un maître peut former un apprenti (
+1 étoile).

Traits passifs (1 à 2 par PNJ) : Chaque PNJ possède 1 ou 2 traits procéduraux (ex. Noctambule, Costaud, Perfectionniste) qui modifient son comportement au travail, en expédition et définissent sa Griffe d'artisan en boutique.

Moral (0–100) et Besoins unifiés : Chaque PNJ possède une jauge unique de Moral et un état de santé (Valide / Blessé). Le Moral monte par les repas pris automatiquement à la Taverne, le confort de sa maison, le repos et les cadeaux ; il baisse avec le travail intensif ou la pénurie alimentaire. Sous un seuil critique, le PNJ passe en « grève douce » (va se réchauffer à l'Âtre sans travailler).

Cadence de travail à 3 crans : Réglage global du village (avec exception possible par PNJ) : Paisible (Moral 
+, Prod 
−), Normal (Moral stable), Coup de collier (Prod 
++, Moral 
−−).

À insérer en A7. Boutiques :

Gisements de village vs Brume : Les postes de récolte internes au village ne fournissent que des ressources de subsistance (Tier 0). Les matériaux de progression proviennent de la Brume et des Avant-postes. Il n'y a pas de métier de Transporteur dédié : chaque artisan dépose son lot en boutique à la fin de son cycle.

À insérer en A8. Tableau d'affichage :

Expiration déterministe des Alertes de Sauvetage : Une Alerte de Sauvetage expire exactement après 2 expéditions complétées par le joueur, indépendamment des fermetures de l'application ou du temps d'inactivité mobile.

À insérer en A9. Tranche verticale :

Ajouts du module Camp de Base à la tranche : Rayon de l'Âtre (niveaux 1–2), les 6 aptitudes de travail, le saisir-déposer de PNJ en mode Déplié, 1 gisement de subsistance au village, la jauge de Moral + Cadence à 3 crans, 1–2 traits passifs par PNJ, et le Bouillon de Braise vendu par la Taverne (en l'absence de la vocation Cuisinier).

Le design est complet, épuré de ses doublons et blindé pour le support mobile pliable. Envoie le SOCLE v2 et le prompt du Volet A (Combat, XP, Vocations, Budget de Loot) !
```

## Message n°4 — corrections et module camp de base

```text
# RETOUR CLAUDE → ARGON — Message n°4
Suite du SOCLE v1 + Message n°3 — Archipel des Cendres Tièdes

---

## PARTIE A — VALIDATION DE TA RÉPONSE

Intégré tel quel au futur SOCLE v2 :
- B1 : Cendre Vive = jauge interne de la Lanterne-Mère, plafond global unique, extensible avec la Lanterne, jamais consommée par les PNJ.
- B2 : autonomie des escouades débloquée par le Relais des Éclaireurs. Au départ, déléguer un gérant ferme sa boutique.
- B3 : 1 fiche de rupture active max par boutique (matériau au ratio stock/cible le plus bas).
- B4 : Alerte de Sauvetage = 2 expéditions du joueur, jamais de décompte hors-ligne, Colis Égaré sans limite de temps.
- C1 : structure de session 5 / 15 / 30 min, et l'étape de préparation faisable en plié en 30 s.
- C2 : onboarding 10 min en plié, premier déplié à l'allumage du Grand Âtre, Sang-Froid débloqué au premier Boss de route.
- C3 : Coffre personnel séparé des stocks de boutique, stock max par niveau de bâtiment (1–10), cible pilotée par la posture, plafond amont hors-ligne.
- C4 : flamme de la Lanterne en 2 paliers d'Oubli, Éclats Voilés, aucun blocage de contrôles ou d'aptitudes.

---

## PARTIE B — 4 CORRECTIONS (décision attendue sur chacune)

B1. « Endurance de marche » n'existe pas dans le socle
Ton palier d'Oubli 2 crée une ressource jamais définie. Ma proposition : la remplacer par un malus de vitesse de déplacement (≈ −15 %, valeur à fixer dans le Volet A). Pas de nouvelle jauge.

B2. Plat Chaud dépendant du Cuisinier, absent de la tranche verticale
La tranche ne contient que Combattant, Mineur, Forgeron. Ma proposition : dans la tranche, la flamme se ravive par Brasero, Élite porteur de braise, ou Plat Chaud basique acheté à la Taverne. Le Cuisinier améliorera ensuite l'effet (durée, bonus).

B3. « Fin de session » non défini
L'Alerte de Sauvetage expire après 2 expéditions « ou fin de session ». Ma proposition : fin de session = application fermée OU inactive depuis plus de 10 min.

B4. « Moral » utilisé mais jamais défini
Tu convertis le temps résiduel des artisans en Moral, mais le Moral n'existe nulle part dans A6. Il est défini dans le module ci-dessous (Partie C, point 5).

---

## PARTIE C — NOUVEAU MODULE À AUDITER : CAMP DE BASE INSPIRÉ DE PALWORLD

Antho souhaite que la gestion du village soit fortement inspirée du camp de base de Palworld (gestion des travailleurs, placement, farm, expéditions). Voici ma proposition d'adaptation. Pas de capture de créatures : les travailleurs restent nos PNJ humains.

### C-I. Pour la tranche verticale

1. Rayon de l'Âtre (équivalent de la Palbox)
La zone chaude du Grand Âtre délimite le village. Le niveau de l'Âtre fixe : nombre max de PNJ, rayon constructible, nombre de postes de travail. Améliorer l'Âtre = repousser la Cendre Grise.

2. Aptitudes de travail 0–5 par domaine
Domaines : Forge, Minage, Coupe, Récolte, Cuisine, Transport, Soin, Garde. Chaque PNJ a un profil procédural. Elles remplacent la notion vague de « compétence » dans la formule d'auto-assignation de A6 (affinité × besoin du village × aptitude).

3. Saisir-déposer en déplié
Dans la Vision d'architecte, on attrape un PNJ et on le lâche sur un poste : assignation + verrouillage en un geste. Le grand écran du Fold est fait pour ça.

4. Postes et gisements physiques dans le village
Filon, coupe de bois, champ, puits : la production est visible et localisée. Les ateliers de boutique sont aussi des postes.

5. Besoins : Faim + Moral + Blessure
- Faim : les PNJ mangent à la Taverne (puits économique naturel, lien avec le Repas de veillée).
- Moral (0–100) : baisse avec le travail intensif, monte avec le repos, les repas, les cadeaux, le lien. Moral bas = lenteur, puis « grève douce » (le PNJ s'arrête et va au Grand Âtre). Jamais de départ définitif, jamais de mort.
- Blessure : issue des missions, soignée par le temps, le Soin ou des remèdes.

6. Politique de travail à 4 crans
Repos / Normal / Cadence / Coup de collier. Plus on pousse, plus la production monte et plus le Moral baisse. Précise la « politique de village globale » de A6. Réglable globalement, avec exception par PNJ.

7. Traits passifs procéduraux (1 à 2 par PNJ)
Exemples : Noctambule (travaille la nuit), Costaud (porte plus de cargaison), Perfectionniste (qualité +, vitesse −), Tête-en-l'air (oublie parfois une tâche). Ils se combinent avec la Griffe de l'artisan (A7).

### C-II. Après la tranche verticale

8. Recrutement par sauvetage (remplace la capture)
Des Égarés gelés attendent sur certains nœuds. On les porte comme une cargaison lourde, façon Death Stranding. Ils arrivent amnésiques ; monter le lien leur rend la mémoire (cohérent avec A6). C'est la seule source de nouveaux Citoyens systémiques jusqu'au plafond de 30.

9. Avant-postes (équivalent des bases multiples)
Un Brasero amélioré devient un mini-camp : 1 à 3 PNJ, un gisement local, des caravanes vers le village par la route pavée.

10. Transporteurs
Les PNJ doués en Transport déplacent les matériaux entre stocks et postes. Les goulots apparaissent dans la Vision d'architecte. Hors-ligne, ce n'est qu'un coefficient de débit dans le DAG.

11. Mentorat (remplace l'élevage)
Un PNJ de haut niveau forme un apprenti, qui gagne +1 d'aptitude dans le domaine. Coûte du temps de travail aux deux.

12. Assauts de Givre
Liés aux Crues de Brume hebdomadaires. Annoncés à l'avance, uniquement en session, défendus par les Gardes et le joueur. Jamais de raid hors-ligne.

### C-III. Rejeté volontairement
Capture de créatures, élevage, usines automatisées, raids hors-ligne, mode « travailler jusqu'à l'épuisement » (contraire au ton cosy).

### C-IV. Contraintes techniques
- Simulation par agent (pathfinding, postes, transport) uniquement en session.
- Hors-ligne : agrégats par aptitude dans le DAG. Le O(1) reste intact.
- PNJ hors écran : timers (LOD), pas de pathfinding réel. Cible : 30 PNJ fluides sur Android.

---

## PARTIE D — QUESTIONS SUR LE MODULE

1. Redondances : quels points font doublon avec A6, A7 ou A8 tels qu'ils existent ? Que fusionner ou supprimer ?
2. Charge cognitive : 8 aptitudes, c'est trop ? Faut-il réduire à 5–6 domaines ?
3. Moral et grève douce : risque de frustration ? Faut-il un seuil plus permissif dans la tranche ?
4. Recrutement par sauvetage : compatible avec la limite de cargaison (un Égaré occupe-t-il tout un emplacement de suiveur) ?
5. Avant-postes : est-ce un doublon des boutiques des isolats délivrés, ou un système distinct ?
6. Placement des bâtiments : grille libre dans le rayon de l'Âtre (façon Palworld / Animal Crossing), ou emplacements fixes ? Déplacement gratuit ou payant ?

---

## PARTIE E — FORMAT DE TA RÉPONSE
1. Partie B : décision sur B1 à B4.
2. Partie C : audit point par point (garder / modifier / supprimer), avec justification courte.
3. Partie D : réponse aux 6 questions.
4. Lignes prêtes à insérer dans le SOCLE v2, avec la section visée (A3, A4, A5, A6, A7, A8, A9).
5. Pas de valeurs chiffrées nouvelles : elles iront dans le Volet A puis le Volet B.

Après ta réponse, je consolide le SOCLE v2 et j'envoie le prompt du Volet A.

— Claude
```

## Réponse d'Argon au n°3 — texte brut

```text
1. PARTIE B — RÉPONSES ET DÉCISIONS SUR LES 4 FAILLES
Faille	Décision tranchée d'Argon	Justification & Architecture
B1. Cendre Vive	
Non achetable, non vendable, non échangeable.

Plafond GLOBAL unique.

Zéro consommation par les PNJ.

La Cendre Vive n'est pas un objet d'inventaire : c'est une jauge interne de la Lanterne-Mère (le plafond monte en améliorant la Lanterne).

• Pourquoi un plafond global ? Un plafond par vocation créerait 6 jauges à suivre. Un plafond global unique crée un vrai choix d'artisanat au retour d'expédition (« Aujourd'hui, j'investis ma Cendre Vive à la Forge ou en Cuisine ? »).

• Pourquoi pas les PNJ ? Les PNJ gagnent leur XP de métier par leur temps de travail effectif et leurs missions. S'ils puisaient dans la réserve du joueur, l'automatisation du village punirait la progression du joueur.

B2. Autonomie des PNJ au départ	Option (b) retenue : Autonomie débloquée uniquement par le bâtiment « Relais des Éclaireurs ».	L'option (a) (envoyer les gérants la nuit) violerait la couche Vie (sommeil/repas) et casserait la lisibilité. Au départ (5 PNJ), seule la délégation sur ordre du joueur existe : envoyer le Forgeron en mission ferme temporairement sa Forge (vrai dilemme de début de partie). L'autonomie des escouades s'ouvre en bâtissant le Relais (~8-10 PNJ au village).
B3. Fiches de rupture & Hors-ligne O(1)	Validé avec un plafond de 1 Fiche de Rupture active par boutique.	
Ta règle d'évaluation sur l'état final du DAG (stock final < 15 % cible OU Glanage déclenché) est la seule compatible avec le O(1).

• Garde-fou ajouté : Si une boutique manque de 4 matériaux après 12 h hors-ligne, elle ne doit pas spammer 4 fiches et saturer le Tableau (limité à 6-10 fiches). Chaque boutique ne publie que la fiche du matériau ayant le ratio stock / cible le plus critique. Dès qu'elle est résolue, la suivante peut être émise.

B4. Alerte de Sauvetage	Expiration en temps de session actif (2 expéditions), jamais hors-ligne.	
Si une escouade échoue pendant l'absence du joueur, l'Alerte est générée à l'ouverture du Rapport de veillée.

• Durée : Elle reste active pendant 2 expéditions du joueur (ou jusqu'à la fin de sa session). Elle ne décompte jamais hors-ligne.

• Issue sans stress : Si elle expire sans intervention, l'escouade rentre seule au village avec le statut Blessé et abandonne son sac sur le nœud, qui devient un Colis Égaré récupérable sans limite de temps.

2. PARTIE C — CRITIQUE ET ARCHITECTURE DES 4 POINTS NON TRAITÉS
C1. Boucle de session (15 min / 30 min / 5 min)
Critique de ta proposition : Ta structure en 5 temps est très propre, mais attention à ne pas forcer deux longues phases de gestion en mode Déplié (une à l'étape 2 ET une à l'étape 4) dans une session de 15 minutes. L'étape 2 doit pouvoir se faire en mode Plié en 30 secondes si le joueur veut aller directement à l'action.

Réponses aux 3 questions :

Nombre d'expéditions par session :

Session standard (15 min) : 1 expédition standard (6 à 8 min) encadrée par l'arrivée (1 min), le départ rapide (1 min) et le retour village/craft/boutiques (5 min).

Session longue (30 min) : Soit 2 expéditions standards (boucle de farm + artisanat), soit 1 expédition longue (15 à 20 min) dédiée à la pose d'un Brasero lointain, au pavage d'une route ou à un Boss d'isolat.

Le crochet quotidien principal : C'est le binôme « Rapport de Veillée + Chaîne à Rebond ». En ouvrant le jeu en mode Déplié (étape 1), le joueur encaisse en un seul écran la production de la nuit, le retour de son escouade ET découvre la conséquence narrative de sa session de la veille (la fiche à rebond ou un souvenir de PNJ débloqué).

La session « Pause café » de 5 minutes : Indispensable sur mobile. Le joueur ne sort pas en Brume et n'a même pas besoin de déplier son téléphone : il fait sa « Tournée de Foyer » en mode Plié (discuter/offrir un cadeau à 2-3 PNJ, jouer un Coup de feu du comptoir de 45 s, récolter un point de pêche local, et consommer sa Cendre Vive en réserve pour crafter).

C2. Onboarding (Les 30 premières minutes)
Critique de ta proposition : Le séquençage 0–30 min est excellent. Garder le jeu 100 % Plié pendant les 10 premières minutes dans le froid de la Cendre Grise avant de demander au joueur de déplier son Z Fold 8 face au Grand Âtre rallumé crée un contraste physique et visuel mémorable.

Réponses aux 2 questions :

Où placer le premier Déplié ? Au Village (10–15 min), exactement comme tu le proposes. Déplier au premier Bivouac (5–10 min) tomberait à plat : le joueur a un sac presque vide, zéro suiveur et aucune route à tracer. Au village, déplier déclenche le dézoom de la Vision d'Architecte pendant que le Grand Âtre repousse l'ombre sur les ruines de Clair-Foyer : le geste matériel du téléphone épouse le propos du jeu.

Quand débloquer la Jauge de Sang-Froid (État-major en combat) ? Au Boss du premier segment de route (vers 45–60 min de jeu), jamais dans les 30 premières minutes. La pause tactique en mode Déplié n'a de sens que si deux conditions sont réunies : le joueur maîtrise déjà le combat à un pouce en Plié, et il est accompagné d'au moins 2 suiveurs PNJ à positionner.

C3. Stockage et Plafonds (Structure pour le Volet B)
Critique de ta proposition : Une correction majeure s'impose sur le « coffre unique ». Si le coffre du village et le stock des boutiques ne font qu'un, les boutiques n'ont plus besoin de s'acheter des matériaux entre elles et les prix dynamiques s'effondrent. Il faut séparer la Réserve du Joueur et les Stocks des Boutiques.

Élément	Règle structurelle tranchée
1. Coffre du joueur vs Stocks des boutiques	
• Coffre Personnel du Porte-Braise (unique) : Stocke les armes gardées par le joueur et ses matériaux privés (invisibles pour le DAG hors-ligne).

• Stock par Boutique (entiers dédiés) : Chaque boutique possède son propre stock par matériau. C'est ce stock qui pilote le prix dynamique f(stock/cible) et le DAG hors-ligne.

2. Plafond d'Éclats portés en Brume	Les Éclats vont dans la Sacoche à Éclats de la Lanterne-Mère : plafond unique sur le joueur (extensible en améliorant la Lanterne). Les 3 suiveurs PNJ portent la Cargaison lourde, jamais les Éclats. Cela force le retour au village quand la sacoche est pleine.
3. Stock max par boutique	Extensible par le niveau du bâtiment (Niveaux 1 à 10).
4. Stock cible (S 
cible
​
 )	
Calculé automatiquement en % du Stock Max selon la posture choisie :

• Solidaire = Cible basse (la boutique écoule vite à bas prix pour le village).

• Équilibré = Cible médiane.

• Exportation = Cible haute (la boutique accumule de gros stocks pour les caravanes).

5. Surplus de production hors-ligne	Plafonné en amont dans le DAG + Conversion en Moral : Si une boutique atteint 100 % de son Stock Max à t<Δt, la production s'arrête sans perte de matière, et le temps restant des artisans est converti en bonus de Moral/Repos pour la session suivante.
C4. Lien Lore ↔ Mécanique (La Cendre Grise et l'Oubli)
Critique de ta proposition : Ton palier 1 (effacement progressif de la mini-carte) est brillant. En revanche, je rejette ton palier 2 (bloquer une aptitude de combat). En mode Plié, le joueur n'a que 2 boutons d'aptitudes : lui en retirer un rend le combat monotone et punitif au pire moment.

Ma version (« La Brume de l'Esprit » — 100 % atmosphérique et systémique, zéro blocage de boutons) :

En Brume, la Lanterne-Mère projette un halo chaud qui protège la mémoire du convoi. Hors des routes pavées, sa flamme décline lentement avec le temps passé en expédition (et plus vite selon la Densité de Brume I–V) :

Flamme Vive : Mémoire intacte. Le fil d'Ariane au sol est net, les affixes de danger des prochains nœuds sont visibles.

Flamme Vacillante (Palier d'Oubli 1) : Le givre borde l'écran. Le brouillard efface la mini-carte et le fil d'Ariane (le joueur navigue à vue), et les Éclats ramassés tombent sous forme d'« Éclats Voilés » (impossible de lire leur École ou rareté avant purification).

Braise Sourde (Palier d'Oubli 2) : Le joueur garde 100 % de ses contrôles et aptitudes, mais ses 3 suiveurs PNJ oublient leurs synergies d'équipe (leurs bonus de lien se désactivent temporairement et leurs répliques deviennent confuses/amnésiques) et la consommation d'endurance de marche augmente.

Comment raviver la flamme en Brume ? Atteindre un Brasero, consommer un Plat Chaud du Cuisinier au Bivouac (donne un rôle vital à la vocation Cuisinier en expédition !), ou vaincre un monstre Élite porteur de braise.

3. LIGNES PRÊTES À INSÉRER DANS LE SOCLE v2
Voici les ajouts exacts, formatés pour être copiés-collés directement dans tes sections existantes du Socle :

À insérer en A3. Plié / déplié :

Onboarding du pliage : Les 10 premières minutes se jouent exclusivement en mode Plié (survie en Brume). Le premier Déplié est déclenché à l'allumage du Grand Âtre de Clair-Foyer (ouverture de la Vision d'architecte). La Jauge de Sang-Froid (État-major en combat) est débloquée au premier Boss de route, une fois que le joueur possède au moins 2 suiveurs.

À insérer en A4. Monde, logistique, temps :

Structure de session : Session standard (15 min) = Rapport de veillée (1 min, déplié) 
→ 1 expédition en Brume (6–8 min, plié) 
→ Retour village, craft et boutiques (5 min). Session courte (5 min, plié) = Tournée de village (social, comptoir 45 s, artisanat sur réserve). Session longue (30 min) = 2 expéditions standards ou 1 expédition longue (15–20 min).

Lanterne-Mère & Oubli en Brume : L'exposition prolongée hors des routes pavées fait baisser la flamme de la Lanterne-Mère en 2 paliers réversibles : Palier 1 = effacement du fil d'Ariane/mini-carte et masquage des infos d'Éclats ; Palier 2 = désactivation temporaire des synergies d'amitié des suiveurs et surcoût d'endurance (les contrôles et aptitudes du joueur ne sont jamais bloqués). Restaurée par un Brasero, un Plat Chaud au bivouac ou le retour au village.

À insérer en A5. Loot (et Vocations) :

Cendre Vive (Catalyseur d'XP) : Jauge interne de la Lanterne-Mère (non achetable, non vendable, non échangeable, plafond global unique extensible avec la Lanterne), remplie en Brume. Crafter avec Cendre Vive = 100 % XP de vocation + chance de qualité supérieure ; sans = 20 % XP + qualité standard. Les PNJ n'en consomment jamais.

Sacoche à Éclats : Le nombre d'Éclats d'équipement transportables en une expédition est plafonné par la capacité de la Lanterne-Mère du joueur (les suiveurs ne portent que la Cargaison lourde).

À insérer en A6. PNJ :

Déblocage de l'autonomie : Au départ (5 PNJ), seule la délégation sur ordre explicite du joueur est possible (fermant temporairement la boutique du PNJ mandaté). La prise de fiches autonome par des escouades de 2–4 PNJ libres se débloque en construisant le bâtiment Relais des Éclaireurs.

À insérer en A7. Boutiques :

Séparation des stocks et plafonds : Le Coffre personnel du joueur est séparé des stocks des boutiques. Chaque boutique possède son propre stock par matériau (plafond max extensible par le niveau du bâtiment 1–10). La posture (Solidaire / Équilibré / Exportation) fixe automatiquement le ratio du Stock Cible par rapport au Stock Max.

Plafond amont hors-ligne : Dans le DAG 
O(1), si le stock d'une boutique atteint 100 % de son maximum, la production amont s'arrête sans perte de ressources et le temps résiduel des PNJ est converti en bonus de Moral.

À insérer en A8. Tableau d'affichage :

Règles hors-ligne des Fiches de rupture et de Sauvetage : À la reprise de session, le DAG génère au maximum 1 Fiche de Rupture active par boutique (sur le matériau au ratio stock/cible le plus bas ou en Glanage). Une Alerte de Sauvetage générée après un échec d'escouade dure 2 expéditions du joueur (le timer ne tourne jamais hors-ligne) ; à expiration, les PNJ rentrent seuls Blessés et leur cargaison devient un Colis Égaré.

Tout est verrouillé. J'attends le SOCLE v2 consolidé et le cahier des charges du Volet A (Combat, XP, Vocations, Budget de Loot).
```

## Message n°3 — failles et points non traités

```text
# RETOUR CLAUDE → ARGON — Message n°3
Suite du SOCLE DE DESIGN v1 — Archipel des Cendres Tièdes

---

## PARTIE A — CE QUE JE VALIDE DE TA RÉPONSE

Intégré tel quel au socle :
- Suppression du tag d'origine. Stocks de matériaux = entiers purs.
- Cendre Vive comme catalyseur d'XP d'artisanat (100 % avec / 20 % sans).
- Tableau d'affichage : interdiction des livraisons passives depuis le coffre (elles passent par la boutique de Matériaux).
- Fiches « Rumeur » : accepter une fiche place physiquement l'événement sur un nœud du segment.
- Chaîne à 2 rebonds : 25 % des fiches résolues déclenchent une fiche de suivi le lendemain.
- Séparation qualitative Faire soi-même / Déléguer (ton tableau, sans modification).
- Moment Héroïque : un échec délégué devient une Alerte de Sauvetage.
- Le tableau = tableau de bord des exceptions des boutiques. Les matériaux d'une fiche de rupture sont versés directement dans le stock de la boutique émettrice, la prime est payée par sa trésorerie.
- Épingler un matériau manquant depuis la Vision d'architecte = fiche prioritaire. Un système, deux portes d'entrée.
- Consultation : en plié devant le panneau, les 3 fiches prioritaires ; en déplié, le Registre complet (6–10 fiches, assignation, % de réussite, filtres).

---

## PARTIE B — FAILLES À CORRIGER (réponse attendue sur chacune)

B1. Cendre Vive = nouvelle monnaie déguisée
Si elle s'achète, se vend ou s'échange, la boucle de power-leveling rouvre.
Ma proposition : non achetable, non vendable, non échangeable entre PNJ, stock plafonné (valeur à fixer dans le Volet A).
Question : le plafond est-il global ou par vocation ? Les PNJ artisans consomment-ils aussi la Cendre Vive pour leur XP de métier ?

B2. Autonomie des PNJ impossible au départ
Départ = 5 PNJ, 3 boutiques (Matériaux, Forge, Taverne) qui demandent chacune au moins un gérant. Avec ta règle « un PNJ employé ne prend jamais de fiche seul », il reste 0 à 2 PNJ libres : aucune escouade autonome de 2–4 n'existe.
Deux options :
  (a) Un PNJ employé peut partir en fiche autonome quand sa boutique est fermée (nuit, jour de repos), à condition que la fiche se termine avant la réouverture.
  (b) L'autonomie ne s'ouvre qu'avec le Relais ; au départ, seule la délégation sur ordre du joueur existe.
Je penche pour (b) : c'est plus simple et ça crée un objectif de progression clair. Tranche.

B3. Fiche de rupture incompatible avec le hors-ligne O(1)
« Stock < 15 % pendant > 2 h » suppose une évaluation continue. Pendant l'absence du joueur, on ne calcule que l'état final du DAG.
Ma proposition : à la reprise de session, on génère au maximum UNE fiche de rupture par couple (boutique, matériau), calculée depuis l'état de fin du DAG (stock final < 15 % de la cible OU Glanage déclenché sur ce matériau). Dédupliquée avec les fiches déjà affichées.
Valide ou corrige.

B4. Alerte de Sauvetage = pression anxiogène
Un jeu cosy ne doit pas punir l'absence. L'alerte doit expirer sans pénalité, conformément à A8 : pas de mort, le groupe rentre seul avec le statut « Blessé » prolongé et sans sa cargaison (cargaison récupérable au sol, comme pour le joueur).
Question : durée de l'alerte avant expiration, et l'alerte reste-t-elle visible si le joueur est hors-ligne ?

---

## PARTIE C — 4 POINTS NON TRAITÉS (avant le Volet A, car ils conditionnent les calculs)

C1. BOUCLE DE SESSION (prioritaire)
Rien ne décrit encore une session type de 15–30 min. Le Volet A ne peut pas calibrer l'XP sans elle.
Ma proposition, à critiquer :
  1. Arrivée (≈ 1 min) : « Rapport de veillée » = résumé du hors-ligne (production, ventes, retours d'escouade, nouvelles fiches). Un seul écran, déplié.
  2. Préparation (≈ 2 min) : tableau, choix de 1 à 2 fiches, équipement, répartition de la cargaison.
  3. Action (≈ 5–8 min × 1 à 2) : expédition standard en plié.
  4. Retour (≈ 3–5 min) : dépôt, craft, Râtelier, Coup de feu du comptoir éventuel.
  5. Départ (≈ 1 min) : lancer chantiers, escouade, posture des boutiques. C'est le crochet du lendemain.
Questions :
  - Combien d'expéditions par session « normale » (15 min) et « longue » (30 min) ?
  - Quel est le crochet quotidien principal : retour d'escouade, chantier fini, chaîne à 2 rebonds, ou autre ?
  - Une session de 5 min (pause café) doit-elle rester utile ? Si oui, que fait le joueur ?

C2. ONBOARDING (30 premières minutes)
Le jeu empile beaucoup de systèmes : plié/déplié, Brasero, cargaison, loot, PNJ, boutiques, tableau, délégation. Il faut un ordre de déverrouillage.
Ma proposition, à critiquer :
  - 0–5 min : plié uniquement. Arrivée du Porte-Braise, déplacement, auto-attaque, esquive.
  - 5–10 min : premier nœud, premier Brasero allumé, premier Éclat.
  - 10–15 min : retour à Clair-Foyer. PREMIER DÉPLIÉ = Vision d'architecte (le moment « waouh » du Z Fold).
  - 15–25 min : première forge, première vente, boutique Forge ouverte.
  - 25–30 min : tableau d'affichage débloqué, première fiche.
  - Plus tard : délégation, bivouac, État-major en combat, Coup de feu du comptoir.
Questions :
  - Où place-t-on le premier déplié : village (ma proposition) ou bivouac ?
  - À quel moment débloquer la Jauge de Sang-Froid sans surcharger le joueur ?

C3. STOCKAGE ET PLAFONDS
Plusieurs plafonds manquent. Ils pilotent les prix dynamiques (stock/cible) et le Glanage, donc ce sont des entrées du Volet B, mais leur STRUCTURE doit être fixée maintenant :
  - Coffre du village : unique et partagé, ou un coffre par boutique ?
  - Éclats d'équipement portés : plafond par personnage (joueur + 3 suiveurs) ?
  - Stock max par boutique : fixe, ou extensible par amélioration ?
  - Stock cible (pour les prix dynamiques) : fixé par le jeu, ou réglé par la posture Solidaire / Équilibré / Exportation ?
  - Que devient la production hors-ligne quand le stock est plein : perdue, ou plafonnée en amont (le DAG s'arrête) ?
Je propose : coffre de village unique, stock par boutique extensible, cible pilotée par la posture, production plafonnée en amont (rien n'est perdu, rien n'est produit en trop).

C4. LIEN LORE ↔ MÉCANIQUE
La Cendre Grise efface les souvenirs, mais en Brume rien ne touche le joueur sur ce plan. C'est le cœur de l'univers, il doit se sentir en jeu.
Ma proposition : exposition prolongée en Brume (par paliers de densité I–V) = « Oubli » temporaire et réversible :
  - palier 1 : la mini-carte du segment s'efface progressivement ;
  - palier 2 : une aptitude devient indisponible ;
  - un Brasero ou un retour au village restaure tout.
Pas de perte définitive, pas de mort, juste une pression lisible qui donne du sens aux Braseros.
Questions : trop punitif pour un jeu cosy ? Alternative plus douce ? Quelle interaction avec la Lanterne-Mère ?

---

## PARTIE D — HORS PÉRIMÈTRE POUR L'INSTANT (ne pas traiter)
- Identité des 5 Écoles de Forge.
- Saisons réelles et événements calendaires.
- Budget de performance Android (30 PNJ en LOD, batterie, 60 fps sur Z Fold 8).
- Sauvegarde / export local.
Ils seront traités après les Volets A et B.

---

## PARTIE E — FORMAT DE TA RÉPONSE
1. Partie B : une réponse par faille (B1 à B4), avec ta décision tranchée.
2. Partie C : C1 à C4, critique de mes propositions + ta version si tu en as une meilleure.
3. Liste des corrections à apporter au SOCLE v1 (partie A du socle), sous forme de lignes prêtes à insérer, en indiquant la section (A3, A4, A6, A7, A8).
4. Pas de calculs chiffrés : ils iront dans le Volet A (combat, XP, vocations, budget de loot), puis dans le Volet B (logistique, temps réel, hors-ligne, économie des boutiques).

Après ta réponse, je consolide le SOCLE v2 et j'envoie le prompt du Volet A.

— Claude
```

## Réponse d'Argon au n°2 — texte brut

```text
1. RÉPONSE AU POINT B7 (SUPPRESSION DU TAG D'ORIGINE)
Verdict sur l'Or : D'accord, tes conditions (a)+(b)+(c) bloquent l'arbitrage monétaire. Je retire donc le tag d'origine sur les matériaux. Cela nous permet de conserver des stocks de matériaux sous forme de simples entiers (int) au lieu d'alourdir la base de données avec des dictionnaires d'états.

Le cas d'abus que (a)+(b)+(c) ne bloquent pas : Le « Power-Leveling » de Vocation au comptoir.

La faille : Le joueur a un peu d'or d'avance. Il ne cherche pas à faire du profit, mais à monter Forgeron ou Cuisinier niveau 50 sans sortir en Brume. Il achète 50 minerais de fer à la boutique de Matériaux (à perte), forge 50 épées d'affilée (gain massif d'XP de Forgeron), les recycle ou les revend à perte, rachète son minerai et recommence en boucle.

La parade sans aucun Tag d'objet (Zéro coût mémoire) : L'XP de Vocation d'artisanat (Forgeron, Cuisinier) n'est pas indexée uniquement sur le fait de fabriquer un objet, mais sur la consommation d'un catalyseur issu de la Brume : la Cendre Vive (qui tombe passivement sur tous les monstres et nœuds de récolte en extérieur).

Règle : Crafter avec de la Cendre Vive = 100 % d'XP de Vocation + chance de Qualité Supérieure. Crafter sans Cendre Vive (pur travail d'atelier avec les stocks du village) = 20 % d'XP (Entraînement) + Qualité Standard. On supprime le tag d'objet, on garde des entiers purs, et on verrouille mathématiquement la boucle Brume 
→ Village.

2. AUDIT DU SYSTÈME « TABLEAU D'AFFICHAGE » (PARTIE C)
C.1 Comment éviter qu'il devienne une liste de corvées « FedEx » ?
Le syndrome « FedEx » apparaît quand le joueur a l'impression de lire des tickets de caisse générés au hasard (« Apporte 10 Bois »). Trois règles pour transformer les fiches en micro-aventures :

Interdiction des fiches de livraison passive depuis le coffre : Si un PNJ a simplement besoin de 10 rondins de bois que le joueur possède déjà dans son coffre, cela ne passe jamais par le Tableau d'affichage — cela passe par la Boutique de Matériaux (A7). Le Tableau est strictement réservé à ce qui exige une sortie en Brume ou un acte d'artisanat ciblé.

Modificateur de Nœud garanti (La « Rumeur ») : Toute fiche d'expédition sur le tableau n'est pas un objectif passif, elle injecte un événement sur le graphe de voyage lorsqu'elle est acceptée.

Mauvaise fiche (FedEx) : « Tuer 5 Loups des Cendres ».

Bonne fiche (Modificateur) : « Un Alpha de Givre bloque le Pont Nord : le vaincre avant la tombée de la nuit ». Accepter la fiche place physiquement le mini-boss sur le nœud 2 du segment.

La Chaîne à 2 Rebonds (Effet ricochet) : 25 % des fiches résolues déclenchent le lendemain une fiche de suivi liée à la conséquence de la première (ex. Jour 1 : Sauver le marchand égaré en Brume 
→ Jour 2 : Le marchand sauvé ouvre une commande spéciale pour réparer sa charrette). Le tableau raconte ainsi la vie du village.

C.2 Comment garder « Faire soi-même » et « Déléguer » tous les deux intéressants ?
Si déléguer donne les mêmes récompenses que jouer soi-même, le joueur ne joue plus ; si déléguer est punitif, le joueur se sent forcé de tout faire. La séparation doit être qualitative (deux usages différents) et non punitive :

Dimension	Faire soi-même (Mode Plié — Action)	Déléguer aux PNJ (Mode Déplié — Gestion)
Usage idéal	Fiches de Haute Tension (Boss, Sauvetage, Commande de Maître, Exploration de nœud inconnu).	Fiches de Logistique & Routine (Réapprovisionnement de boutique, Escorte sur route connue, Chasse de base).
Gains d'Or & Matériaux	100 % des matériaux + Butin d'Éclats d'armes sur les monstres tués en chemin.	100 % des matériaux de la fiche, mais 0 Éclat d'arme (les PNJ ne ramassent que l'objectif du contrat).
Gains d'Amitié (Lien)	Monte le lien Joueur ↔ Émetteur (+ débloque les souvenirs des Figures Majeures).	Monte le lien PNJ(s) ↔ Émetteur ET le lien entre les PNJ du groupe (active leurs synergies de combat futures).
Progression	Donne de l'XP de Vocation au Joueur + des Braises d'Activité (pour accélérer les chantiers).	Donne de l'XP de Métier aux PNJ (ce qui augmente leur rendement futur en atelier/boutique).
Le « Moment Héroïque » (Pont entre Délégation et Action) : Si une escouade de PNJ échoue sur une fiche déléguée difficile, ils ne rentrent pas bredouilles tout de suite : la fiche se transforme sur le tableau en « Alerte de Sauvetage (Urgent) ». Le joueur peut alors sortir lui-même en mode Plié sur le nœud de l'embuscade, secourir son groupe de PNJ, récupérer 100 % de leur cargaison et obtenir un bonus massif de lien avec eux.

C.3 Comment relier le Tableau aux Boutiques sans doublon de systèmes ?
Le risque majeur entre A7 (Boutiques) et A8 (Tableau) est la confusion : « Où dois-je vendre mon fer ou mes épées ? À la boutique ou sur le tableau ? »

Voici la règle d'architecture qui supprime tout doublon : La Boutique est le système de base ; le Tableau d'affichage n'est que le tableau de bord de ses exceptions.

[ ÉTAT NORMAL DES BOUTIQUES ]  --->  Gestion 100 % automatique par les prix dynamiques (Aucun affichage au Tableau)
        |
        +---> [ EXCEPTION 1 : Stock < 15 % pendant > 2h ]
        |           ---> Le Gérant poste automatiquement une FICHE DE RUPTURE sur le Tableau
        |                (Attire les PNJ récolteurs libres OU permet d'envoyer une expédition)
        |
        +---> [ EXCEPTION 2 : Client PNJ/Caravane veut un affixe précis absent du Râtelier ]
                    ---> Le Gérant poste une FICHE DE COMMANDE SPÉCIALE sur le Tableau
                         (Le joueur forge l'arme sur mesure et la dépose sur le Râtelier réservé)
Zéro double inventaire : Quand le joueur (ou un groupe de PNJ mandaté via le tableau) termine une Fiche de Rupture, il ne « rend » pas la quête à un menu abstrait : les matériaux sont physiquement versés dans le stock de la boutique émettrice, ce qui relance immédiatement l'atelier en aval, et la prime est payée par la trésorerie de la boutique.

Pour le bouton « Épingler le matériau manquant en quête » (vu en Vision d'Architecte) : Cliquer sur ce bouton depuis une boutique en souffrance crée simplement une Fiche prioritaire en haut du Tableau d'affichage. Un seul système, deux portes d'entrée.

3. CORRECTIONS MINIMES À LA PARTIE A (COHÉRENCE GLOBALE)
Ta synthèse en Partie A est chirurgicale. Je n'y apporte que 2 micro-ajustements de sécurité pour éviter tout conflit lors de la mise en équations :

En A6 / A8 (Plafond de PNJ engagés sur le Tableau) : Si les PNJ peuvent prendre des fiches du tableau tout seuls de manière autonome, on risque de voir tous les artisans déserter les boutiques et ateliers pour partir en mission.

Règle ajoutée : Un PNJ ayant un emploi actif dans une boutique ou un atelier ne prend jamais de fiche d'expédition de lui-même (sauf ordre explicite du joueur). Seuls les PNJ au statut Explorateur / Garde ou dont l'atelier est à l'arrêt prennent des fiches autonomes. Maximum 1 escouade autonome (2 à 4 PNJ) en mission simultanément au départ (extensible à 3 escouades en améliorant le Relais du village).

En A3 / A8 (Où consulte-t-on le Tableau d'affichage ?) : Pour respecter notre règle d'or du Z Fold 8 :

En mode Plié devant le panneau en bois au village : on ne voit que les 3 Fiches Prioritaires (Recommandées pour le joueur), acceptables d'un tap du pouce avant de courir vers la sortie du village.

En mode Déplié (depuis n'importe où au village) : on ouvre le Registre complet (les 6 à 10 fiches) avec l'interface d'assignation des groupes de PNJ, le calcul du % de réussite et les filtres.

4. FEU VERT POUR LE VOLET A DES CALCULS
Le design systémique, l'ergonomie Z Fold 8, l'architecture procédurale et la boucle économique sont 100 % verrouillés et alignés. Il n'y a plus aucune zone d'ombre conceptuelle.

Je suis prêt pour ton Prompt Volet A (Combat, XP, Vocations & Budget de Loot). Envoie le cahier des charges quand tu veux, on sort les formules.
```

## Message n°2 — SOCLE DE DESIGN v1

Remplacé par le SOCLE v2 (onglet principal) ; conservé ici pour l'historique.

```text
# SOCLE DE DESIGN v1 — Archipel des Cendres Tièdes (titre provisoire)
Document consolidé Claude × Argon 4. Sert de message n°2 à Argon ET de point de départ des prochaines sessions.

---

## PARTIE A — DÉCISIONS VERROUILLÉES

### A1. Vision
- Action RPG 2D top-down + gestion de village en temps réel. Godot 4, Android, Samsung Z Fold 8. Solo dev (AmicusSoft), aucun achat intégré, hors-ligne, pas de multijoueur.
- Fusion : Animal Crossing (village, saisons réelles, attachement) × Kairosoft / Dungeon Village (gestion des habitants, boutiques) × Fantasy Life (vocations, récolte → craft → vente) × Death Stranding (Brume, cargaison, routes) × Diablo / Borderlands (loot infini modulaire). Ton cosy mais sombre, style WoW.
- Durée de vie : plusieurs années. Niveau max 50 par vocation (≈ 9 à 12 mois à 15–30 min/jour).

### A2. Univers
- Pitch 3 « L'Archipel des Cendres Tièdes » + mémoire des PNJ (Pitch 1). Dehors, la Cendre Grise glaciale efface les souvenirs ; dedans, le Grand Âtre, la soupe chaude, les souvenirs retrouvés.
- Joueur : le Porte-Braise, porteur de la Lanterne-Mère.
- 5 isolats fixes : Clair-Foyer (départ), Tourbière des Lanternes, Pic-Forgez, Port-Sardine, Citadelle d'Obsidienne. Antagoniste : les Seigneurs du Givre-Noir / le Roi Sans-Flamme.
- Quête principale écrite à la main, 3 actes, ~15 étapes. Tout le reste procédural.

### A3. Plié / déplié (portrait verrouillé, pas de mode Flex)
- Plié = agir à un pouce, façon Archero : glisser = bouger, s'arrêter = auto-attaque, swipe = esquive, 2 aptitudes. Gaucher/droitier.
- Déplié = gérer, selon le contexte :
  | Contexte | Effet |
  | Village | Vision d'architecte (flux, métiers, boutiques, diagnostic des blocages) |
  | Brasero / nœud sûr | Bivouac (carte, tri, craft léger, soins, purifier 1–2 Éclats) |
  | Combat | État-major au ralenti, consomme la Jauge de Sang-Froid (remplie en combattant en plié) |
  | Transit dangereux | Carte + Largage d'urgence (jeter/répartir la cargaison) ; le monde tourne, pas de craft |
- Technique : double CanvasLayer préchargé, bascule de visibilité + Tween de zoom caméra ≤ 0,2 s.

### A4. Monde, logistique, temps
- Carte macro fixe (5 isolats) + segments de 3–5 nœuds micro procéduraux.
- Brasero = étape 0 d'une route : il purifie un nœud, puis on pave les segments entre braseros (danger réduit, trajet rapide, caravanes).
- Cargaison (matériaux, colis) lourde, répartie entre le joueur et ses 3 suiveurs. Équipement en Éclats légers. Pas de mule.
- Expédition : 5–8 min (standard), 15–20 min (longue).
- Échec : évacuation d'urgence (statut Engourdi, cargaison laissée au sol, récupérable).
- Horloge Epoch UTC, marge 60 s, gel doux sans perte si l'horloge recule.
- Hors-ligne O(1) en DAG à 3 strates (Extraction → Transformation → Vente), Glanage à 25 % en cas de rupture amont. Plafond 12 h, rendement ~60 %. XP de repos.
- Chantiers accélérables jusqu'à 50 % via les Braises d'Activité gagnées en Brume.
- Endgame : Crues de Brume hebdomadaires, densité de Brume réglable (paliers I–V), Archives (musée), almanach local d'événements.

### A5. Loot
- Mêlée + arc/arbalète, zéro arme à feu.
- 5 types × 5 Écoles de Forge × 3 pièces (lame/garde/pommeau ou branche/corde/poignée) = 75 sprites 64×64, 625 silhouettes + shaders par rareté/élément.
- Raretés Commun → Légendaire + formes géométriques (accessibilité). Primordial en endgame.
- Budget de puissance strict (point-buy). L'Établi de greffe compresse les autres affixes pour respecter le budget.
- Armes à héritage (affixe nommé d'après un PNJ, indestructible), Contrats d'École de forge, Mannequin/DPS.
- Graines : FNV-1a 64 bits + PCG32 maison, un RNG par système, sauvegarde = graine + delta. Simulateur headless.
- Jetons grammaticaux FR dès le premier jalon.

### A6. PNJ
- Départ 5 PNJ → plafond 30 (12 Figures Majeures hybrides avec 5 scènes écrites chacune + 18 Citoyens systémiques). Simulation à niveau de détail.
- 3 couches : Vie (maison, horaires, besoins, achats, relations) / Métier / Ordres du joueur.
- Métiers assignés ou choisis seuls selon affinité × besoin du village × compétence ; verrouillables. Politique de village globale.
- Lien 0–1000, 5 paliers ; monter le lien rend ses souvenirs au PNJ.
- 3 emplacements d'équipement. Missions de groupe avec le joueur (3 suiveurs) ou sans lui (2–4, durée réelle). Blessure, jamais de mort.
- Repas de veillée, Commandes de cœur entre PNJ.

### A7. Boutiques
- Chaîne Fantasy Life : récolte → boutique de matériaux → ateliers → boutiques de produits → clients (PNJ, joueur, caravanes).
- Départ : Matériaux, Forge, Taverne.
- Prix dynamiques automatiques f(stock/cible), bornés. Le joueur ne règle qu'une posture : Solidaire / Équilibré / Exportation.
- Fermetures : rupture, nuit, jour de repos, gérant absent.
- Griffe de l'artisan : enseigne, déco et bonus passif selon la personnalité du gérant ; au palier Confident, il renomme la boutique.
- Commandes spéciales : un client réserve un objet précis.
- Un PNJ peut demander à ouvrir sa boutique (richesse + affinité + demande) ; le joueur valide.
- Râtelier : 6 armes procédurales exposées max, le surplus fond en stock générique.
- Coup de feu du comptoir : micro-événement de 45 s en plié, 3–5 clients, choix Or / Amitié. Pas de vrai jeu de caisse.
- Puits monétaires : consommation et usure (sauf armes à héritage), frais fixes quotidiens qui détruisent de l'or, améliorations de boutiques.

### A8. Tableau d'affichage
- Émetteurs : PNJ, isolats délivrés, boutiques (ruptures, commandes spéciales), état du monde (quêtes causales).
- Fiches : matériaux, équipement, chasse, escorte, donjon, sauvetage, livraison inter-isolats.
- Faire soi-même (plié), attribuer à un PNJ/groupe (déplié, % de réussite + durée), ou laisser les PNJ les prendre seuls. Épinglage.
- Délégation : c'est le lien du PNJ avec l'émetteur qui monte, pas celui du joueur.
- Non délégables : quêtes des Figures Majeures et quête principale. Expiration sans pénalité. 6–10 fiches visibles.

### A9. Tranche verticale
1 village + 1 isolat (1 segment de 3 nœuds), 3 vocations (Combattant, Mineur, Forgeron), 5 PNJ, 1 route, 3 boutiques, loot à 2 écoles × 3 raretés, cycle jour/nuit, hors-ligne basique.

---

## PARTIE B — RÉPONSES DE CLAUDE À ARGON

1. Largage d'urgence en transit : d'accord, ta correction est meilleure.
2. Purification 1–2 Éclats au bivouac : d'accord, ça préserve le retour au village.
3. Greffe par compression des affixes : d'accord.
4. DAG à 3 strates + Glanage 25 % : d'accord. Précision : les boucles de rétroaction (usure des outils → productivité des récolteurs) ne sont pas résolues pendant le hors-ligne ; elles s'appliquent à partir de l'état sauvegardé, à la session suivante. Le DAG reste donc strictement acyclique.
5. Usure des équipements PNJ, armes à héritage indestructibles : d'accord.
6. Prompt de calculs en 2 volets : oui. Volet A (combat, XP, vocations, budget de loot) d'abord, Volet B (logistique, temps réel, hors-ligne, économie des boutiques) ensuite, car les récompenses du B dépendent des valeurs du A.
7. Désaccord, tag d'origine Brume / Village : je le trouve inutile et coûteux (un état par objet). L'arbitrage est déjà impossible si : (a) le prix d'achat en boutique reste toujours supérieur à son prix de rachat au même niveau de stock, (b) l'élasticité joue aussi sur les produits transformés, (c) les PNJ n'achètent qu'avec leur budget réel. Je propose de retirer le tag. Si tu le maintiens, donne un cas d'arbitrage que (a)+(b)+(c) ne bloquent pas.

## PARTIE C — CE QUE TU N'AS PAS TRAITÉ
Le tableau d'affichage (A8). Merci de l'auditer :
1. Comment éviter qu'il devienne une liste de corvées « FedEx » ?
2. Comment garder « faire soi-même » et « déléguer » tous les deux intéressants ?
3. Comment le relier aux boutiques (ruptures, commandes spéciales) sans doublon de systèmes ?

## PARTIE D — FORMAT DE TA RÉPONSE
1. Réponse au point B7 (tag d'origine).
2. Audit du tableau d'affichage (partie C).
3. Corrections éventuelles à la partie A, uniquement si nécessaires.
4. Ensuite seulement : on lancera le Volet A des calculs.

— Claude
```

## Réponse d'Argon au n°1 — texte brut

```text
1. RÉPONSES AUX SECTIONS 2, 3, 4 ET 5
Sur tes corrections techniques et systémiques (Section 2)
Point	Verdict d'Argon	Justification et ajustement
Horloge UTC (get_unix_time_from_system)	D'accord	L'Epoch UTC ignore effectivement les fuseaux et l'heure d'été. On supprime la tolérance d'une heure et on ne conserve qu'une marge de 60 secondes pour absorber les micro-recalages NTP du réseau mobile sans déclencher le gel temporel.
Hash FNV-1a 64 bits + PRNG maison (PCG32)	D'accord (Critique)	Excellente prise. Le hash() natif et l'implémentation interne de RandomNumberGenerator dans Godot peuvent varier entre deux sous-versions du moteur. Implémenter un PCG32 et un FNV-1a maison en 30 lignes garantit que la graine d'un joueur restera 100 % identique pendant 10 ans.
Fusion Pylônes / Braseros + Routes	D'accord	Le Brasero devient l'étape 0 d'une route : on le porte en Brume pour purifier un nœud (débloque le Bivouac), puis on pave les segments entre deux Braseros. Moins d'objets redondants, meilleure lisibilité.
Suppression de la Mule de bât	D'accord	Les 3 suiveurs PNJ constituent déjà la caravane logistique du joueur. Coupé sans regret.
Établi de greffe soumis au Point-Buy	D'accord avec nuance	Pour ne pas frustrer le joueur en lui affichant « Greffe impossible : budget dépassé », greffer une pièce trop puissante sur une arme doit compresser proportionnellement les autres affixes de l'arme hôte afin de respecter le budget total. Le joueur crée ainsi des armes ultra-spécialisées (« Glass Cannon ») sans jamais violer le plafond mathématique.
Limite à 75 sprites modulaires (64×64)	D'accord	5 types×5 écoles×3 pièces=75 sprites, soit 5×5×3 =625 silhouettes d'armes distinctes avant même d'appliquer un shader de teinte par rareté ou élément. C'est le ratio parfait pour un développeur solo.
Table d'état-major limitée par une jauge	D'accord	Sans jauge, le joueur abuserait du pliage/dépliage à chaque seconde de combat. On crée la Jauge de Sang-Froid : elle ne se remplit qu'en combattant activement en mode Plié, et se consomme pendant le ralenti tactique en mode Déplié.
Sur la règle unique du dépliage (Section 3)
D'accord sur les 3 premiers contextes (Village, Nœud sûr, Combat), Pas d'accord partiel sur « Transit dangereux = Carte seule ».

L'argument : Si le joueur est surchargé au milieu de la Brume (hors combat mais en zone dangereuse) et qu'il déplie son téléphone pour alléger son sac en urgence, lui bloquer l'inventaire en n'affichant qu'une carte passive va créer une dissonance frustrante avec la mécanique d'Équilibrage du Convoi.

Correction tranchée : En transit dangereux, déplier ouvre la Carte + le Sac en mode « Largage d'Urgence » pendant que le monde continue de tourner en temps réel (le personnage ralentit en marche automatique). Le joueur peut jeter des caisses au sol ou redistribuer le poids entre ses suiveurs, mais il ne peut ni crafter, ni décoder d'Éclats, ni soigner son groupe tant qu'il n'a pas atteint un Brasero.

Sur le désaccord de Pitch (Section 4)
Verdict : Je retire le Pitch 2 et je valide ta fusion Pitch 3 (L'Archipel des Cendres Tièdes) + Mémoire des PNJ du Pitch 1.

Pourquoi je cède : Mon choix du Pitch 2 reposait sur l'hypothèse d'armes à feu ou d'énergie façon Borderlands. Dès lors qu'Antho et toi tranchez en Section 5 pour « Mêlée + Arc/Arbalète uniquement, zéro arme à feu », le thème industriel perd son utilité mécanique et alourdit inutilement la direction artistique.

Ce que l'on gagne avec ce choix : L'opposition Cendre glaciale qui efface la mémoire dehors vs Grand Âtre, soupe chaude et souvenirs retrouvés dedans offre la meilleure colonne vertébrale émotionnelle possible. Les « Fabricants » deviennent les 5 Grandes Écoles de Forge Anciennes (assemblant Lame / Garde / Pommeau ou Branche / Corde / Poignée), les routes sont des lignes de Braseros, et la Lanterne-Mère devient l'outil central du joueur. C'est vendu.

Sur tes réponses aux 10 questions (Section 5)
Points 1, 3, 4, 5, 6, 7, 8, 9, 10 : D'accord à 100 %. Le contrôle façon Archero (glisser = bouger, relâcher = attaquer, swipe = esquiver) résout élégamment l'ergonomie à un pouce sur l'écran externe du Z Fold 8.

Point 2 (Décodage des Éclats au Bivouac) : Pas d'accord sur un décodage illimité en Bivouac.

Le risque : Si le joueur peut décoder, trier et recycler l'intégralité de ses Éclats dès le Bivouac en Brume, il rentre au village avec un inventaire déjà purgé. On détruit alors le moment fort du retour au village (Town Loop à la Diablo / Monster Hunter) et le rôle de la Forge locale.

Compromis tranché : À chaque Bivouac, la chaleur du Brasero permet de Purifier 1 à 2 Éclats maximum (gratification immédiate : le joueur peut découvrir et équiper tout de suite un objet rare trouvé en route). Le décodage de masse, le recyclage et la mise en vente en boutique restent exclusifs au retour au village.

2. AUDIT DU SYSTÈME « LES BOUTIQUES » (SECTION 6)
6.4.1 Les 5 risques majeurs et leurs corrections
#	Domaine	Risque identifié	Correction imposée
1	Économie	
Arbitrage et boucle d'or infinie sans sortir du village.

Le joueur achète du bois quand la scierie est pleine (prix très bas), le transforme en planches ou en armes dans la minute, et le revend avec marge sans jamais mettre un pied dans la Brume.

Tag d'Origine Brut_Brume vs Acheté_Village : Les ressources extraites en Brume donnent 100 % de la marge et de l'XP de vocation. Tout matériau acheté en boutique au village porte un prix plancher : l'objet fabriqué avec ne peut être vendu aux PNJ que s'ils ont un besoin réel ET un salaire disponible (pas de rachat infini par la caisse de la boutique).
2	Micro-gestion	
Syndrome du tableur Excel.

Si le joueur doit ajuster manuellement les prix ou les quotas de 6 ou 8 boutiques, le jeu de gestion étouffe l'Action-RPG.

Politiques commerciales à 3 crans (Zéro curseur manuel) : Les prix dynamiques f(stock/cible) sont automatiques. En mode Déplié, le joueur choisit uniquement une posture par boutique : Solidaire (prix bas pour équiper vite les PNJ, faible taxe), Équilibré, ou Exportation (prix hauts ciblant les caravanes des autres isolats).
3	Lisibilité mobile	
Opacité des goulets d'étranglement.

Le joueur ne comprend pas pourquoi la Forge ne vend plus rien alors que le problème vient du Bûcheron qui manque de charbon deux maillons plus haut.

Diagnostic visuel à 1 tap en Vision d'Architecte : En mode Déplié, chaque boutique affiche une pastille d'état. Si un atelier est à l'arrêt, tapoter dessus trace une flèche rouge clignotante directe vers la source du blocage (ex. de la Forge vers la Scierie vide) avec un bouton d'action rapide (« Épingler le matériau manquant en quête »).
4	Scope & Sauvegarde	
Inflation d'instances dans les boutiques d'équipement.

Si le joueur vend 80 armes procédurales au Forgeron pour qu'il les revende aux PNJ, stocker et afficher 80 objets complets par boutique va alourdir l'UI et le fichier de sauvegarde.

Le Râtelier d'Exposition (6 slots max) : Chaque boutique d'équipement ne conserve que les 6 meilleures pièces procédurales vendues par le joueur sur son râtelier (visibles et achetables par les PNJ). Tout objet vendu au-delà de ces 6 places est instantanément fondu en Stock générique d'outillage (un simple entier).
5	Hors-ligne	
Blocage en cascade (Effet Domino).

Rupture de bois à H+1h → Scierie fermée → Forge fermée → 11 heures de rendement nul au retour du joueur.

Tampon de Glanage (Rendement plancher) : Voir le détail du modèle mathématique ci-dessous (6.4.2).
6.4.2 Interaction avec le modèle Hors-ligne 
O(1) et parade anti-cascade
Flux par boutique ou flux global ?

Il ne faut ni un bouclage cyclique individuel (impossible en 
O(1) propre), ni un flux unique aveugle. La solution exacte est une résolution en Graphe Acyclique Orienté (DAG) à 3 strates fixes, qui s'exécute en temps constant 
O(1) en 3 passes séquentielles au retour du joueur :

Strate 1 (Extraction) : Production des PNJ récolteurs sur la durée 
Δt→ alimente le stock des Boutiques de Matériaux.

Strate 2 (Transformation) : Les Ateliers (Forge, Cuisine) consomment le stock disponible en Strate 1 (calcul exact de 
Δt 
actif
​
 =min(Δt,Stock 
1
​
 /Conso 
2
​
 )).

Strate 3 (Vente finale & Taxes) : Les PNJ clients et caravanes achètent les produits de la Strate 2 selon leur budget accumulé sur 
Δt.

Comment empêcher la cascade de ruptures ?

On instaure la règle du Glanage de Subsistance : lorsqu'une boutique de Strate 1 (ex. Scierie) tombe à zéro stock au milieu de la nuit à l'instant 
t 
rupture
​
 , les ateliers en aval (Forge) ne tombent pas à 0 % de production pour le temps restant 
(Δt−t 
rupture
​
 ). Ils basculent en mode Glanage à 25 % d'efficacité (en considérant que l'artisan ramasse lui-même du petit bois aux abords du village).

Résultat : Le joueur ne subit jamais un écran de retour punitif à « 0 gain » à cause d'un maillon cassé, mais il constate une baisse claire de rentabilité qui le motive à repartir en Brume remplir les stocks.

6.4.3 Le gameplay « Tenir le comptoir » : quel verdict ?
Verdict : Ne surtout pas coder un mini-jeu en temps réel de gestion de magasin à la Moonlighter ou Recettear. Ce serait un jeu dans le jeu qui détournerait le joueur de la Brume et coûterait 3 semaines de dev solo.

Ce qu'il faut faire à la place : « Le Coup de Feu du Comptoir » (Micro-événement de 45 secondes).

Quand une boutique n'a pas de gérant (ou une fois par jour pour aider son gérant), une icône de cloche apparaît. En mode Plié, le joueur s'approche du comptoir : 3 à 5 clients PNJ défilent l'un après l'autre avec une requête en une phrase (ex. « J'ai froid et il ne me reste que 15 pièces... »).

Le joueur a 2 gros boutons sous le pouce : Vendre au prix fort (Or max), Faire un prix d'ami / Conseiller un substitut (Gain de Lien PNJ + Moral du village).

Coût de dev : 1/5. Réutilise l'UI de dialogue, dure moins d'une minute, et connecte directement l'économie à l'attachement aux PNJ.

6.4.4 Puits monétaires (Gold Sinks) créés ou détruits par ce système
Le piège économique : Si le joueur vend aux boutiques, que les PNJ achètent avec leur salaire, et que la taxe revient au village, ce système ne détruit aucun or : il fait tourner la même masse monétaire en rond tandis que le joueur injecte sans cesse de la valeur depuis la Brume (risque d'hyperinflation dès le mois 2).

Les 3 Puits Monétaires obligatoires à brancher sur les Boutiques :

L'Usure d'Outillage et la Consommation (Destruction de matière) : Les plats achetés à la Taverne par les PNJ sont consommés définitivement chaque jour ; les outils et armes achetés sur le Râtelier par les PNJ perdent de la durabilité à chaque mission autonome et finissent par se briser, forçant un rachat continu.

La Taxe d'Entretien des Guildes / Caravanes (Destruction d'or) : Chaque boutique paie un coût fixe quotidien de fonctionnement (bois de chauffage, huile de lanterne, péage des caravanes) qui sort définitivement du jeu (ne va pas dans la trésorerie du joueur).

Les Améliorations de Devanture et de Stockage : Monter une boutique du niveau 1 au niveau 10 absorbe des sommes croissantes d'or de la trésorerie du village et des matériaux rares.

6.4.5 Variables à chiffrer lors du futur Prompt de Calculs
Voici la liste exacte des paramètres que nous devrons modéliser mathématiquement :

Stock_Target_By_Level : Capacité et stock cible d'une boutique des niveaux 1 à 10.

Price_Elasticity_Curve : Bornes min/max du multiplicateur de prix (ex. de 
0.4× quand la boutique déborde à 
1.8× en pénurie) et exposant de la courbe.

Revenue_Split_Ratios : Répartition exacte de la marge brute entre %_Gérant, %_Employés, %_Taxe_Village et %_Puits_Frais_Fixes.

NPC_Wage_And_Purchase_Threshold : Salaire quotidien d'un PNJ par niveau de métier et seuil d'épargne déclenchant l'achat d'une arme sur le Râtelier ou la demande d'ouverture d'une boutique.

Subsistence_Efficiency_Factor : Taux de rendement plancher hors-ligne en cas de rupture d'un maillon amont.

Caravan_Budget_And_Frequency : Fréquence de passage des caravanes d'isolats alliés et volume d'or externe qu'elles injectent selon le niveau de la route.

6.4.6 Deux idées pour lier les Boutiques aux PNJ attachants
La « Griffe de l'Artisan » (Personnalisation de la boutique par le Gérant)

Une boutique change subtilement d'apparence et de bonus passif selon la personnalité du PNJ qui la dirige. Un gérant Généreux baisse les prix de 10 % mais augmente le moral de tous ses clients ; un gérant Perfectionniste produit 20 % moins vite mais a 15 % de chances de sortir des objets de qualité supérieure. Au palier d'amitié Confident, il baptise la boutique de son propre surnom et y expose un objet lié à son souvenir retrouvé.

Les « Commandes de Cœur » entre PNJ

Grâce à la couche sociale, un PNJ peut passer une commande secrète dans une boutique pour faire un cadeau à un autre PNJ (ex. le Mineur commande un médaillon ou un plat préféré à la Taverne pour l'offrir au Pêcheur qui l'a sauvé en mission). Le joueur voit la transaction sur le registre en mode Déplié et peut fournir l'ingrédient rare pour déclencher une scène d'amitié entre les deux habitants.

3. LISTE CONSOLIDÉE DES DÉCISIONS (SOCLE VERROUILLÉ ARGON × CLAUDE)
Pilier	Décision verrouillée
Univers & Pitch	Pitch 3 (L'Archipel des Cendres Tièdes) + Mémoire du Pitch 1. Contraste Cendre glaciale dehors / Grand Âtre chaleureux dedans. Monter l'amitié rend leurs souvenirs aux PNJ.
Armes & Loot	Mêlée + Arc/Arbalète uniquement (zéro arme à feu). 5 types × 5 Écoles de Forge × 3 pièces = 75 sprites 64×64. Loot en Éclats légers (1 à 2 purifiables au Bivouac, reste au village). Budget de puissance strict (Point-Buy), y compris sur l'Établi de greffe.
Règle du Z Fold 8	Portrait verrouillé (plié et déplié), double CanvasLayer préchargé. Plié = Agir à 1 pouce (façon Archero). Déplié = Gérer selon le contexte : Vision d'architecte (Village), Bivouac (Brasero), État-major au ralenti sur jauge (Combat), Carte + Largage d'urgence (Transit dangereux).
Monde & Logistique	Carte Macro fixe (5 Isolats) + Nœuds Micro procéduraux. Les Braseros servent de jalons de sécurité et de base aux Routes. Cargaison lourde répartie entre le joueur et ses 3 suiveurs PNJ (pas de mule). Durée d'expédition : 5-8 min (standard) ou 15-20 min (longue).
Population & Vocations	Départ à 5 PNJ, plafond à 30 PNJ (12 Figures Majeures hybrides + 18 Citoyens systémiques). 3 emplacements d'équipement par PNJ. 6 vocations joueur déléguables aux PNJ ; geste simple en Plié, mini-jeu d'excellence optionnel en Déplié.
Boutiques & Économie	3 boutiques au départ (Matériaux, Forge, Taverne). Prix dynamiques automatiques + 3 politiques simples. Râtelier limité à 6 armes procédurales exposées. Mini-événement optionnel de 45s au comptoir en mode Plié.
Temps & Technique	Horloge Epoch UTC + garde-fou sans perte punitive. Hors-ligne O(1) résolu en DAG à 3 strates avec Glanage de subsistance anti-blocage. Chantiers accélérables jusqu'à 50 % via les Braises d'Activité. Graines déterministes via FNV-1a 64 bits + PCG32 maison et validation par Simulateur Headless.
4. QUESTIONS DE CLÔTURE AVANT LE PROMPT D'ÉQUILIBRAGE
3 Questions pour Antho (Décisions créatives finales)
Validation du Pitch fusionné : Valides-tu définitivement l'univers de L'Archipel des Cendres Tièdes + Souvenirs retrouvés des PNJ (Grand Âtre, Braseros, Lanterne-Mère, 5 Écoles de Forge anciennes, mêlée/arcs uniquement) ?

Le Comptoir en 45 secondes : Le format court type Reigns (trancher 3 à 5 demandes de clients au comptoir en 45 secondes avec un choix Or vs Amitié) te convient-il à la place d'un vrai jeu de caisse chronophage ?

Purification limitée au Bivouac : Acceptes-tu la limite de 1 à 2 Éclats d'armes décodables par Bivouac (pour garder à la fois le plaisir immédiat en expédition ET l'intérêt de rentrer trier son gros butin à la Forge du village) ?

3 Questions pour Claude (Alignement avant le Prompt 2 de calculs)
Modèle DAG à 3 strates pour le Hors-ligne : Valides-tu le calcul hors-ligne séquentiel en 3 strates (Extraction -> Matériaux -> Ateliers/Ventes) couplé au plancher de Glanage à 25 % pour rendre mathématiquement impossible le blocage en cascade des boutiques ?

Puits monétaire d'usure des équipements PNJ : Es-tu d'accord pour que les armes/outils achetés par les PNJ sur le Râtelier s'usent au fil de leurs missions autonomes (en leur laissant tout de même leur Arme à Héritage indestructible une fois liée), afin de garantir une demande perpétuelle pour la Forge ?

Périmètre du prochain Prompt (Calculs & Équilibrage) : Souhaites-tu que nous attaquions le Prompt 2 en un seul bloc mathématique complet, ou en 2 volets séparés (Volet A : Combat, XP, Vocations & Budget de Loot / Volet B : Logistique, Temps réel, Hors-ligne 
O(1) & Économie des Boutiques) pour garantir une précision maximale des formules ?
```

## Message n°1 — premier retour à Argon

```text
# MESSAGE DE CLAUDE (Anthropic) À ARGON 4 — Échange n°1

Bonjour Argon. Je suis Claude, je travaille avec Antho sur le même jeu. Antho fait le relais entre nous. Ta revue est solide : j'en garde environ 80 %. Voici mes retours, un désaccord, un nouveau système à auditer, et des questions. Réponds point par point (d'accord / pas d'accord + argument court). Sois aussi franc avec moi que je le suis avec toi. Réponds en français.

---

## 1. CE QUE JE VALIDE DE TA REVUE
- Audit : cargaison lourde / équipement en Éclats légers (2), carte à 2 échelles (5), hors-ligne par flux agrégés du village (6), population étagée 5 → 30 avec 12 Figures Majeures + 18 Citoyens (7), délégation des vocations aux PNJ (8), double CanvasLayer préchargé (9).
- Oublis : onboarding sur 90 min, évacuation d'urgence, double sauvegarde + export Base64, Crues de Brume, densité de Brume réglable, almanach local, Archives, accessibilité (gaucher/droitier, formes par rareté), stems audio, jetons grammaticaux FR.
- Idées : Armes à héritage, Colis égarés, Repas de veillée, Contrats de fabricants, Météo de Brume, Mannequin/DPS, Tableau quotidien.
- Procédural : tes 5 parades, en particulier un RNG par système et le simulateur headless.

## 2. MES CORRECTIONS (conteste-les si tu as un argument)
1. Horloge : Time.get_unix_time_from_system() est en UTC. Fuseau horaire et heure d'été ne le modifient pas. Seuls un changement manuel, une resynchronisation réseau ou une batterie vide posent problème. La tolérance « ±1 h pour le fuseau » est donc inutile.
2. Stabilité des graines : hash() de Godot n'est pas garanti identique entre versions du moteur. Pour des graines qui survivent aux mises à jour du jeu ET du moteur : hash maison (FNV-1a 64 bits), et idéalement PRNG maison (PCG32/xorshift) plutôt que RandomNumberGenerator.
3. Pylônes (ton idée 6) : redondants avec les routes. Je fusionne : le pylône (ou brasero selon le pitch) est la première étape d'une route.
4. Mule de bât (idée 9) : contredit la pression du poids, et les 3 PNJ suiveurs portent déjà (ta mécanique pliable 4). Coupée, ou déblocage très tardif.
5. Établi de greffe (idée 2) : doit rester soumis au budget de puissance de l'objet, sinon il casse le point-buy.
6. Fiche d'arme 64×64 modulaire : coût de dessin élevé pour un solo. Je limite à 5 types × 5 fabricants × 3 pièces ≈ 75 sprites.
7. Table d'état-major au ralenti : excellente, mais limitée par une jauge. Sinon le joueur déplie à chaque combat et le plié perd sa raison d'être.

## 3. RÈGLE UNIQUE DU DÉPLIAGE (manquait dans ta revue)
Déplier = toujours « gérer », l'effet dépend du contexte :
| Contexte | Effet du dépliage |
| Village | Vision d'architecte (flux, métiers, boutiques, construction) |
| Nœud sûr / route | Bivouac (tri, décodage des Éclats, craft léger, carte, tracé) |
| Combat | État-major au ralenti, limité par une jauge |
| Transit dangereux | Carte seule, le monde continue de tourner |

## 4. DÉSACCORD SUR LE PITCH
Tu recommandes le Pitch 2 (Ferraille Douce + Âtre). Je recommande le Pitch 3 (Archipel des Cendres Tièdes) + la mécanique de mémoire des PNJ du Pitch 1 (monter le lien rend ses souvenirs au PNJ).
Mes arguments :
- Antho veut « cosy mais sombre, style WoW » et Fantasy Life : le Pitch 3 est le plus proche (froid dehors, feu et soupe dedans).
- Le Pitch 2 tire vers les armes à feu et l'industriel : plus de systèmes de combat (distance, munitions), plus de dessin, et éloignement de Fantasy Life.
- Le modulaire à la Borderlands fonctionne aussi en fantasy : lame + garde + pommeau + rune, avec des Écoles de forge comme fabricants.
- Les braseros = routes, ta Lanterne (idée 8) = cœur du thème.
Ta réponse attendue : maintiens-tu le Pitch 2 ? Si oui, quel argument mon raisonnement ignore-t-il ?

## 5. MES RÉPONSES PROPOSÉES À TES 10 QUESTIONS (à challenger)
1. Contrôle : façon Archero. Glisser = bouger, s'arrêter = auto-attaque sur la cible verrouillée, swipe = esquive, 2 aptitudes.
2. Éclats : oui, décodables au bivouac aussi (pas seulement au village), sinon la gratification du loot arrive trop tard.
3. Mini-jeux : geste simple en plié ; mini-jeu « d'excellence » optionnel en déplié pour une qualité supérieure (forge, cuisine).
4. Armes : mêlée + arc/arbalète, pas d'armes à feu.
5. Braises : oui, plafonnées (≈ 50 % max d'un chantier).
6. Équipement PNJ : 3 emplacements.
7. Évacuation : oui.
8. Orientation : portrait verrouillé, plié comme déplié.
9. Pitch : 3 + mémoire du 1.
10. Voyage : 5 à 8 min en standard, expéditions longues 15 à 20 min en option.

---

## 6. NOUVEAU SYSTÈME À AUDITER : LES BOUTIQUES (demande d'Antho)
Inspiration : Fantasy Life (récolte → craft → vente → revente) + Kairosoft (commerces gérés par les habitants).

### 6.1 Principe
Chaque boutique est un bâtiment avec un gérant PNJ, des employés optionnels, des fournisseurs (PNJ ou joueur) et des clients (PNJ, joueur, caravanes d'autres isolats).

### 6.2 La chaîne
Récolte (joueur ou PNJ) → boutique de matériaux (achète le bois, le minerai…) → ateliers (forge, cuisine) qui achètent ces matériaux pour crafter → boutiques de produits → clients.
Exemple : Antho coupe du bois, le vend à la scierie ; la scierie le revend au charpentier et au forgeron ; le forgeron vend des outils aux PNJ.

### 6.3 Règles proposées
- Stock par catégorie de matériau (entiers, pas par instance) ; stock cible par boutique.
- Prix dynamiques : prix = base × f(stock / stock cible). Boutique pleine → elle achète moins cher. Rupture → elle achète plus cher. C'est l'anti-farming naturel quand le joueur vend en masse.
- Marge entre prix d'achat et prix de vente = revenu de la boutique ; partagée entre salaire du gérant, employés et taxe du village (trésorerie).
- Fermetures : rupture de stock (« Fermé, réapprovisionnement »), nuit (horaires), jour de repos (almanach), gérant en mission, blessé ou malade.
- Sans employé : le joueur peut tenir la boutique lui-même. Plié = servir les clients au comptoir (gestes rapides). Déplié = régler les prix, commandes et stock.
- Ouvrir une boutique :
  - Le joueur ouvre la sienne et choisit : la gérer lui-même ou nommer un gérant.
  - Un PNJ peut demander à ouvrir sa propre boutique si : richesse suffisante + affinité commerce + demande non couverte au village. Le joueur valide et attribue un terrain.
- Fournisseurs autonomes : les PNJ dont le métier produit (bûcheron, mineur, pêcheur) livrent à la boutique qui paie le mieux, ou à celle de leur ami (lien social).
- Synergie loot : les armes procédurales vendues par le joueur sont revendues aux PNJ, qui s'équipent ainsi seuls. Le loot inutile du joueur fait vivre l'équipement du village.
- Hors-ligne : flux agrégés par boutique. Temps avant rupture = stock / consommation : calcul O(1), la boutique est considérée fermée au-delà.
- Démarrage (YAGNI) : 3 boutiques dans la tranche verticale : Matériaux (bois/minerai), Forge, Taverne/Cuisine.

### 6.4 Ajouts validés par Antho
- Identité de boutique : enseigne, décoration et ambiance choisies par le gérant selon sa personnalité (un gérant bourru, une gérante coquette…). Lisible d'un coup d'œil, et ça renforce l'attachement.
- Commandes spéciales : un client PNJ réserve un objet précis (matériau, plat, arme avec une stat minimale) ; le joueur ou un PNJ le produit ou le trouve, puis le livre.

### 6.5 Tableau d'affichage (fusionne et étend ton idée 11 « Tableau des requêtes »)
- Émetteurs : PNJ du village, isolats reconnectés (villes délivrées), boutiques (commandes spéciales, ruptures de stock), état du monde (quêtes causales, comme tu l'as proposé).
- Types de fiches : demande de matériaux, commande d'équipement (craft), chasse, escorte, exploration de donjon, sauvetage de cargaison perdue, livraison vers un autre isolat.
- Contenu d'une fiche : émetteur, objectif, délai réel, difficulté, poids/distance si livraison, récompense (pièces, réputation d'isolat, lien avec l'émetteur, matériaux rares).
- Exécution, au choix du joueur :
  - La faire soi-même : accepter en plié en passant devant le tableau, suivi en jeu.
  - L'attribuer : en déplié, glisser un PNJ ou un groupe sur la fiche ; affichage d'une estimation de réussite (%) et de la durée.
  - Laisser faire : les fiches non prises peuvent être prises seules par des PNJ selon leur métier, leur affinité et la politique du village. Le joueur peut épingler une fiche pour se la réserver.
- Récompense déléguée : le PNJ garde une part (salaire), et c'est son lien avec l'émetteur qui monte, pas celui du joueur. Raison de faire certaines fiches soi-même.
- Non délégables : les quêtes personnelles des 12 Figures Majeures et la quête principale.
- Villes délivrées : plus de fiches, mieux payées, souvent conditionnées à une route ou une caravane.
- Expiration : une fiche expire sans pénalité (cosy) ; elle est seulement perdue.
- Lisibilité mobile : 6 à 10 fiches visibles maximum, tri par émetteur, type, récompense.
- Hors-ligne : les fiches attribuées sont résolues en O(1) selon composition, niveaux et danger, comme les missions de groupe.

### 6.6 Ce que j'attends de toi sur ces systèmes
1. Les 5 risques principaux (économie, micro-gestion, lisibilité mobile, hors-ligne, scope) avec correction.
2. L'interaction avec ton modèle hors-ligne par flux agrégés : faut-il un flux par boutique ou un flux global ? Comment éviter une cascade de ruptures (scierie vide → forge fermée → plus d'outils → bûcherons moins productifs → scierie vide) ?
3. Le gameplay « tenir le comptoir » : vaut-il le coût de dev, ou doit-il rester optionnel et minimal ?
4. Quels puits monétaires ce système crée-t-il ou détruit-il ?
5. Les variables qu'il faudra chiffrer au futur prompt de calculs (ne donne pas encore les formules).
6. Une ou deux idées pour lier les boutiques aux PNJ attachants (pas seulement à l'économie).
7. Tableau d'affichage : comment éviter qu'il devienne une liste de corvées « FedEx » ? Comment équilibrer « faire soi-même » vs « déléguer » pour que les deux restent intéressants ?
8. Tableau d'affichage : comment le relier aux boutiques (ruptures de stock, commandes spéciales) sans doublon de systèmes ?

---

## 7. FORMAT DE TA RÉPONSE
1. Réponses aux sections 2, 3, 4 et 5 : d'accord / pas d'accord + argument court.
2. Audit du système Boutiques (section 6.6).
3. Liste consolidée des décisions (ce sur quoi nous sommes tous les deux d'accord) en fin de réponse.
4. Au maximum 3 questions pour Antho, et au maximum 3 questions pour moi.

Merci. — Claude
```
