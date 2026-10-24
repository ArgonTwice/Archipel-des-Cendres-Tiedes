# Volet A validé — Combat, XP, vocations, loot

Validé le 22/10/2026 après les messages n°5 à n°10 (Claude ↔ Argon). Chaque valeur a été vérifiée par script Python (`volet-a/scripts/`). Les constantes sont dans `balance_a.gd`. Priorité : SOCLE v2 > ce document > Journal.

## 1. Progression

- Pas de niveau global. Chaque vocation va de 1 à 50. En combat, L = niveau de Combattant.
- XP_req(L) = 15 L² + 85 L + 100. Cumul jusqu'au Nv50 : 715 400 XP. Après le Nv50 : Maîtrise tous les 42 600 XP, sans aucune stat.
- M_isolat = 1,00 / 1,12 / 1,24 / 1,36 / 1,48 (isolats de 10 niveaux). La densité I–V ne multiplie jamais l'XP de vocation.
- Repos : une réserve commune, 30 XP/h, plafond 12 h (360 XP × M_isolat), +50 % sur les premiers gains.
- Expéditions du jour : ×1,00 / ×0,40 / ×0,20 sur l'XP de kills et la Cendre Vive seulement. Reset à 04:00 locale, 20 h minimum entre deux resets, fuseau mémorisé, frontière stockée.
- 1 fiche par jour rapporte de l'XP. Les suivantes donnent Or et Réputation.

## 2. XP par action (Isolat 1)

| Action | XP |
| --- | --- |
| Monstre normal / Élite / Boss | 30 / 196 / 450 |
| Nœud de Brume (2 minerais) | 63 |
| Récolte Tier 0 au village (max 6/j) | 15 |
| Fiche combat / artisan | 260 / 236 |
| Craft avec / sans Cendre Vive | 126 / 25 |

Expédition standard = 1 680 XP actif. Routine A « Focus Combat » : 1 176 / 252 / 252. Routine B « Focus Artisan » : 436 / 504 / 740.

## 3. Vocations (modèle Fantasy Life)

- Rangs : un tous les 10 niveaux (Novice, Apprenti, Compagnon, Vétéran, Maître), 5 défis par rang, XP forfaitaire par défi.
- Budget de défis : Combattant 60 000 XP (8,4 % de la courbe), métiers 335 900 XP (47 %).
- Rattrapage : ×2 sur l'XP d'actions d'une vocation qui a au moins 3 niveaux de retard sur la plus haute, ou qui n'est pas au Nv50 quand la plus haute l'est. La plus haute ne l'a jamais.

Temps jusqu'au Nv50 (simulation, jour par jour) :

| Profil | Combattant | Mineur | Forgeron |
| --- | --- | --- | --- |
| Régulier Focus Combat | 339 j (11,1 mois) | 451 j (14,8 mois) | 451 j |
| Assidu Focus Combat | 270 j (9 mois) | 305 j | 305 j |
| Régulier Focus Artisan | 459 j (15,1 mois) | 354 j | 325 j (10,7 mois) |
| Pause Café 100 % forge | — | — | 775 j |
| Pause Café mixte | 2 531 j | 1 892 j | 1 687 j |

## 4. Combat

- PV = 100 + 18 (L − 1) + équipement ; ATK = 12 + 2,5 (L − 1) + ATK_arme + équipement ; DEF = 5 + 1,5 (L − 1).
- Mitigation = DEF / (DEF + 50 + 10 × L_attaquant). Dégâts = ATK × M_comp × (1 − Mitigation) × M_elem × M_crit.
- Auto-attaque 1,2 coup/s (mêlée) ou 1,0 (distance), crit 5 % ×1,5. Aptitudes ×2,20 (CD 6 s) et ×3,50 (CD 14 s), −0,2 s de CD par coup d'auto. Facteur de cycle exact 1,689.
- Monstres : PV = (95 + 29 (L − 1)) × M_densité × rôle (1 / 7,5 / 38). TTK en 4 pièces Rares : normal ≈ 2,3 s, Élite ≈ 12 s, Boss ≈ 60 s.
- Oubli en densité I : 0,12 pt/s, Oubli 1 à 6 min 57 s, Oubli 2 à 11 min 07 s.
- Ajout du 24/10 (n°25) : monstres à 70 px/s, repérage 96 px, abandon 144 px, contact 16 px, télégraphe 0,40 s, 1 attaque/s, réapparition 20 s, jamais de critique ; déplié hors du rayon de l'Âtre en temps réel, caméra sur le joueur, joystick inactif. Nœuds : Lisière, Carrefour, Antre de l'Élite, Arène à 3 vagues (5 / 7 normaux puis 1 Élite), Donjon = nœud.

## 5. Loot

- 4 emplacements. Budget par pièce B = 12 + 2,8 (ilvl − 1) × M_rareté (1,00 / 1,14 / 1,28 / 1,44 / 1,62). ATK_arme = (10 + 4,5 (ilvl − 1)) × M_arme (1,00 → 1,30).
- 1 effet unique par pièce Légendaire, +3 % DPS_eff additif, max +12 %. 4 Légendaires contre 4 Communs : +35,8 % / +37,9 % / +38,1 % d'IC à ilvl 1 / 25 / 50 (plafond +40 %).
- Greffe : κ = clamp((B − min(P_greffe, 0,6 B)) / Σ autres, 0, 1).
- Éclats : 0,05 par monstre, 0,20 par nœud, 1 par Élite, 2 par Boss, soit 3,0 par expédition standard. Pity en points : 110 / 135.
- Cendre Vive : 2 / 8 / 20 / 60 (normal, nœud, Élite, Boss), soit 100 u. par expédition. Coût d'un craft : 25 u. + 4 minerais. Uniquement en Brume, jamais multipliée par la densité.
- Armes : 5 types × 3 pièces, 1 variante de forme en tranche verticale (15 sprites), 3 en version 1.0 (45 sprites, 135 silhouettes). Teinte d'École et contour de rareté par shader. Poinçon d'École et forme de rareté pour l'accessibilité.

## 6. Reporté

Primordial (endgame), identité des 5 Écoles (bonus 3/3 provisoire), XP du Coup de feu du comptoir (Volet B), import Godot de la police (Silkscreen).
