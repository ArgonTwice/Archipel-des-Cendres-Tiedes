# Volet E validé — Combat en session, segment de Brume, arène

Validé le 24/10/2026 après les échanges n°25 à n°27 (Claude ↔ Argon), calculs vérifiés par script. Constantes dans balance_a.gd §2. Priorité : SOCLE v2 > Volets A à D > ce document > Journal.

## 1. Rythme des monstres (testé sur le Fold 8, jalon 10)
- 70 px/s (moitié du joueur), repérage 96 px, abandon 144 px, contact 16 px.
- Télégraphe immobile de 0,40 s puis coup, 1 attaque/s, réapparition 20 s, jamais de critique.
- Nv 1 : 5 coups pour tuer un monstre (3,3 s) ; il en faut 12 pour tuer le joueur nu (survie 11,4 / 5,4 / 3,4 s contre 1 / 2 / 3 monstres).

## 2. Déplié en combat (avant la Jauge de Sang-Froid)
- Hors du rayon de l'Âtre : temps réel (aucune pause), caméra sur le joueur, joystick inactif. Le ralenti ×0,05 arrive avec la Jauge.

## 3. Segment de la tranche (3 nœuds)
- Lisière (6 normaux, 4 nœuds de Brume), Carrefour avec Brasero (6 normaux, 4 nœuds), Antre de l'Élite (12 normaux + 1 Élite porteur de braise). Variantes du nœud 3 : arène à vagues, donjon (fiche du tableau).
- Routines A et B = profils du simulateur (SIM_ROUTINE_*), pas le contenu du monde.
- Saturation de Brume : 80 u. de Cendre Vive au plus avant l'Élite. Une action n'est disponible que si son gain tient dans le reste ; au-delà, nœuds vitrifiés et normaux dissipés, l'Élite s'éveille (+20 u.). Éclats toujours 3,0 ; XP 1 656 à 1 704 selon les choix (Volet A : 1 680). Les tables de jours du Volet A tiennent.

## 4. Arène à vagues (nœud 3)
- 3 vagues de 30 s : 5 normaux à [0, 3, 8, 14, 20 s], 7 à [0, 3, 7, 11, 15, 19, 23 s], puis 1 Élite (n°29, provisoire).
- Répit de 5 s entre les vagues, +25 % des PV max (n°29, provisoire ; +50 % au n°27).
- Joueur attendu : Combattant 2, 154 PV, ATK 30, DEF 13. Survie : 24 PV restants en esquivant 1 coup sur 2 (auto seule), 12 PV en esquive modérée avec aptitudes. Sans esquive : mort en vague 2.

## 5. Intégration (Claude Code)
- Les aptitudes doivent exister avant l'arène et l'Élite (sinon seul le régime d'esquive maximal passe).
- SEGMENT_STD_RUN_CENDRE_CAP = SEGMENT_PRE_ELITE_CENDRE_BUDGET + CENDRE_GAIN_ELITE_MOB : vérifié par un test.

## 6. Combat en marche (n°29, après le jalon 11 bis)
- SOCLE §A3 modifié par Antho : auto-attaque à l'arrêt et en marche, jamais en esquive ; récolte à l'arrêt. Aucun malus en marche.
- Portées (balance_c.gd) : Épée & Écu 24 px, Hache-Couperet 28, Glaive 36, Arc 80, Arbalète 92 (sous le repérage de 96 px).
- Arène recalée sur le combat en marche : valeurs provisoires, à mesurer quand l'arène sera codée.

## 7. Fauchage de Braise (n°31, après le jalon 12)
- L'Élite s'arrête et déclenche son télégraphe dès 36 px (ELITE_ATTACK_TRIGGER_RANGE_PX, n°32 : la plus longue mêlée, fixe côté monstre) et frappe tout dans un rayon de 40 px (ELITE_MELEE_AOE_RADIUS_PX) au bout des 0,40 s. Stats, cadence et télégraphe inchangés.
- Pour l'éviter : sortir à plus de 40 px (Épée & Écu 16 px, Hache d'Entaille 12 px, Vouge d'Éclaireur 4 px) ou esquiver (48 px, 0,20 s d'invulnérabilité).
- Arc (80 px) et Arbalète (92 px) hors de la zone : voulu, contrepartie de leur cadence de 1,00 coup/s (−16,7 %).
