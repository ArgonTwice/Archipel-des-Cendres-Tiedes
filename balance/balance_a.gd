class_name BalanceA
extends RefCounted

# Volet A validé le 22/10/2026 (messages Claude ↔ Argon n°5 à n°10, audits par script).
# Constantes uniquement. Toute modification passe par un nouvel échange audité.

# ==============================================================================
# 1. PROGRESSION, XP, VOCATIONS
# ==============================================================================
const MAX_VOCATION_LEVEL: int = 50
# XP_req(L) = 15 L² + 85 L + 100 ; cumul jusqu'au Nv50 = 715 400 XP
const XP_QUAD_A: int = 15
const XP_LIN_B: int = 85
const XP_CONST_C: int = 100
const XP_MASTERY_STEP: int = 42600
const MASTERY_GRANTS_COMBAT_STATS: bool = false

# Isolats : progression. La densité ne multiplie jamais l'XP de vocation.
const ISOLAT_LEVEL_RANGES: Array[Vector2i] = [Vector2i(1, 10), Vector2i(11, 20), Vector2i(21, 30), Vector2i(31, 40), Vector2i(41, 50)]
const ISOLAT_XP_MULTIPLIERS: Array[float] = [1.00, 1.12, 1.24, 1.36, 1.48]

# XP par action (base Isolat 1, avant M_isolat et repos). 1 expédition standard = 1 680 XP actif.
const XP_KILL_NORMAL: int = 30
const XP_KILL_ELITE: int = 196
const XP_KILL_BOSS: int = 450
const XP_GATHER_MIST_NODE: int = 63 # 2 minerais par nœud
const XP_GATHER_VILLAGE_SUBSISTENCE: int = 15
const XP_VILLAGE_SUBSISTENCE_DAILY_CAP: int = 6
const XP_BOARD_FICHE_COMBAT: int = 260
const XP_BOARD_FICHE_ARTISAN: int = 236
const DAILY_FICHE_XP_CAP: int = 1 # fiches suivantes : Or et Réputation, 0 XP
const XP_CRAFT_WITH_CENDRE: int = 126
const XP_CRAFT_NO_CENDRE: int = 25 # floor(126 × 0,20), SOCLE : 20 %
const XP_CRAFT_EXCELLENCE_BONUS: float = 1.20
const XP_VILLAGE_COUNTER_EVENT: int = 87 # à revoir au Volet B (événement de boutique)

# Repos : réserve commune à toutes les vocations, +50 % sur les premiers gains
const RESTED_XP_POOL_SHARED: bool = true
const RESTED_XP_PER_HOUR_BASE: float = 30.0
const RESTED_XP_MAX_HOURS: float = 12.0
const RESTED_XP_BONUS_RATE: float = 0.50

# Expéditions du jour : multiplicateur sur l'XP de kills et la Cendre Vive uniquement
const DAILY_RUN_XP_MULT: Array[float] = [1.00, 0.40, 0.20]
const DAILY_RESET_HOUR_LOCAL: int = 4
const DAILY_RESET_MIN_INTERVAL_UTC_SEC: int = 72000 # 20 h
# Sauvegarde : saved_tz_offset_sec, last_reset_day_index, last_reset_boundary_utc

# Rattrapage (modèle Fantasy Life) : ×2 sur l'XP d'actions d'une vocation en retard
const CATCHUP_LEVEL_GAP_MIN: int = 3
const CATCHUP_ACTION_XP_MULT: float = 2.00

# Rangs par défis : 1 rang tous les 10 niveaux, 5 défis par rang, XP forfaitaire par défi
const CHALLENGES_PER_RANK: int = 5
const CHALLENGE_XP_COMBAT_BY_RANK: Array[int] = [195, 860, 2035, 3715, 5195] # total 60 000
const CHALLENGE_XP_CRAFT_GATHER_BY_RANK: Array[int] = [1100, 4800, 11400, 20800, 29080] # total 335 900

# ==============================================================================
# 2. COMBAT, JOUEUR, MONSTRES, SUIVEURS, LANTERNE
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

const WEAPON_BASE_ATTACK_SPEED_MELEE: float = 1.20
const WEAPON_BASE_ATTACK_SPEED_RANGED: float = 1.00

# Esquive (swipe) et aptitudes
const DODGE_DURATION_SEC: float = 0.25
const DODGE_IFRAME_SEC: float = 0.20
const DODGE_COOLDOWN_SEC: float = 1.80
const DODGE_DISTANCE_PX: float = 48.0
const SKILL_1_COOLDOWN_SEC: float = 6.0
const SKILL_1_DMG_MULT: float = 2.20
const SKILL_2_COOLDOWN_SEC: float = 14.0
const SKILL_2_DMG_MULT: float = 3.50
const AUTO_HIT_CD_REDUCTION_SEC: float = 0.20 # une aptitude occupe un créneau d'auto-attaque

# Mitigation = DEF / (DEF + ARMOR_K_BASE + ARMOR_K_PER_LVL × L_attaquant)
const ARMOR_K_BASE: float = 50.0
const ARMOR_K_PER_LVL: float = 10.0
const ELEM_ADVANTAGE_MULT: float = 1.25
const ELEM_RESIST_MULT: float = 0.80

# Monstres (L_m = niveau du segment, densité D = 1..5)
const DENSITY_STAT_MULTIPLIERS: Array[float] = [1.00, 1.15, 1.30, 1.45, 1.60]
const MOB_BASE_HP: int = 95
const MOB_HP_PER_LVL: int = 29
const MOB_BASE_ATK: float = 10.0
const MOB_ATK_PER_LVL: float = 2.2
const MOB_BASE_DEF: float = 4.0
const MOB_DEF_PER_LVL: float = 1.2
const MOB_ROLE_HP_MULT: Dictionary = {"NORMAL": 1.0, "ELITE": 7.5, "BOSS": 38.0} # TTK Élite ≈ 12 s, Boss ≈ 60 s (4 pièces Rares)
const MOB_ROLE_ATK_MULT: Dictionary = {"NORMAL": 1.0, "ELITE": 1.6, "BOSS": 2.4}

# Suiveurs PNJ : HP = HP_max_joueur × (0,90 + 0,06 E) ; DPS × (0,25 + 0,05 E) × (1 + 0,10 N_liens)
const MAX_FOLLOWERS: int = 3
const FOLLOWER_HP_BASE_MULT: float = 0.90
const FOLLOWER_HP_STAR_MULT: float = 0.06
const FOLLOWER_BASE_DPS_COEFF: float = 0.25
const FOLLOWER_STAR_DPS_COEFF: float = 0.05
const FOLLOWER_SYNERGY_PAIR_BONUS: float = 0.10
const MIN_SUIVEUR_PAIRS: int = 0
const MAX_SUIVEUR_PAIRS: int = 3

# Jauge de Sang-Froid (État-major déplié)
const COLDBLOOD_MAX: float = 100.0
const COLDBLOOD_MIN_TO_ACTIVATE: float = 30.0
const COLDBLOOD_OPEN_COST: float = 15.0
const COLDBLOOD_DRAIN_PER_SEC: float = 10.0
const COLDBLOOD_SLOWMO_TIMESCALE: float = 0.05
const COLDBLOOD_GAIN_ON_HIT: float = 2.5
const COLDBLOOD_GAIN_ON_PERFECT_DODGE: float = 8.0
const COLDBLOOD_GAIN_ON_KILL: float = 6.0

# Lanterne-Mère et Oubli (densité I : Oubli 1 à 6 min 57 s, Oubli 2 à 11 min 07 s)
const LANTERN_FLAME_MAX: float = 100.0 # non modifiée par le niveau de Lanterne
const LANTERN_DRAIN_PER_SEC_BY_DENSITY: Array[float] = [0.12, 0.17, 0.22, 0.27, 0.32]
const OBLIVION_STAGE_1_THRESHOLD: float = 50.0
const OBLIVION_STAGE_2_THRESHOLD: float = 20.0
const OBLIVION_STAGE_2_MSPD_MULT: float = 0.85
const FLAME_RESTORE_ELITE_KILL: float = 35.0
const FLAME_RESTORE_TAVERN_BROTH: float = 50.0
const FLAME_RESTORE_COOK_MEAL: float = 100.0

# Cargaison (kg, granularité 0,5 kg)
const PLAYER_BASE_CARGO_KG: float = 25.0
const PLAYER_CARGO_KG_PER_MINER_LVL: float = 0.20
const FOLLOWER_BASE_CARGO_KG: float = 15.0
const FOLLOWER_CARGO_KG_PER_STAR: float = 2.0
const TRAIT_STURDY_CARGO_MULT: float = 1.30
const LOST_SURVIVOR_COCOON_CARGO_SHARE: float = 1.00

# ==============================================================================
# 3. LOOT, GREFFE, ÉCLATS, CENDRE VIVE
# ==============================================================================
const PLAYER_EQUIPMENT_SLOTS_COUNT: int = 4 # Arme, Casque, Plastron, Bottes
const WEAPON_BASE_ATK_START: float = 10.0
const WEAPON_BASE_ATK_PER_ILVL: float = 4.5
const LOOT_BUDGET_BASE: float = 12.0
const LOOT_BUDGET_PER_ILVL: float = 2.8
const AFFIX_SCALING_PER_ILVL: float = 0.18

# IC(4 Légendaires) / IC(4 Communs) = 1,358 / 1,379 / 1,381 à ilvl 1 / 25 / 50 (plafond 1,40)
const RARITY_BUDGET_MULT: Dictionary = {"COMMON": 1.00, "GOOD": 1.14, "RARE": 1.28, "EPIC": 1.44, "LEGENDARY": 1.62}
const WEAPON_RARITY_ATK_MULT: Dictionary = {"COMMON": 1.00, "GOOD": 1.05, "RARE": 1.12, "EPIC": 1.20, "LEGENDARY": 1.30}
const RARITY_AFFIX_COUNT: Dictionary = {"COMMON": 1, "GOOD": 2, "RARE": 3, "EPIC": 4, "LEGENDARY": 4}
const LEGENDARY_UNIQUE_BONUS_PER_PIECE: float = 0.03 # +3 % DPS_eff additif, effet unique plafonné à cet équivalent
const LEGENDARY_MAX_EQUIPPED_UNIQUES: int = 4
# Primordial : reporté à l'endgame

const GRAFT_MAX_SINGLE_AFFIX_SHARE: float = 0.60
const HEIRLOOM_BUDGET_BONUS_MULT: float = 1.15
const SUPERIOR_QUALITY_ILVL_BONUS: int = 2
const SUPERIOR_CHANCE_BASE: float = 0.20
const SUPERIOR_CHANCE_MINIGAME: float = 0.45

# Éclats : 3,0 par expédition standard (routines A et B), 5,0 avec un Boss
const SHARD_DROP_CHANCE_NORMAL: float = 0.05
const SHARD_DROP_CHANCE_MIST_NODE: float = 0.20
const SHARD_DROP_CHANCE_ELITE: float = 1.00
const SHARD_DROP_COUNT_BOSS: int = 2
# Pity unique en points (poids selon la densité d'origine de l'Éclat)
const PITY_POINTS_PER_SHARD_BY_DENSITY: Array[float] = [1.0, 1.35, 1.9, 2.7, 3.8]
const PITY_LEGENDARY_SOFT_POINTS: float = 110.0
const PITY_LEGENDARY_HARD_CAP_POINTS: float = 135.0

# Densité : matériaux bruts et XP de Maîtrise uniquement (ni XP de vocation, ni Éclats, ni Cendre Vive)
const DENSITY_YIELD_MULTIPLIERS: Array[float] = [1.00, 1.25, 1.50, 1.80, 2.20]

# Cendre Vive : 100 u. par expédition standard, uniquement en Brume
const LANTERN_CENDRE_CAP: Array[int] = [150, 220, 300, 400, 500]
const LANTERN_SHARD_BAG_CAP: Array[int] = [6, 8, 10, 12, 15]
const CENDRE_COST_STANDARD_CRAFT: int = 25 # + 4 minerais
const CENDRE_GAIN_NORMAL_MOB: int = 2
const CENDRE_GAIN_MIST_NODE: int = 8
const CENDRE_GAIN_ELITE_MOB: int = 20
const CENDRE_GAIN_BOSS_MOB: int = 60
const CENDRE_AFFECTED_BY_DENSITY: bool = false

# Armes : 5 types × 3 pièces × variantes de forme, teintées par shader (École, rareté, élément)
const WEAPON_TYPES_COUNT: int = 5
const WEAPON_PARTS_PER_TYPE: int = 3
const WEAPON_SHAPE_VARIANTS_VERTICAL_SLICE: int = 1 # 15 sprites
const WEAPON_SHAPE_VARIANTS_FULL_GAME: int = 3 # 45 sprites, 135 silhouettes
const WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS: float = 0.05 # provisoire : dépend de l'identité des Écoles

# ==============================================================================
# 4. FONCTIONS O(1) (simulateur headless)
# ==============================================================================
static func get_xp_required(level: int) -> int:
	if level >= MAX_VOCATION_LEVEL:
		return XP_MASTERY_STEP
	return XP_QUAD_A * level * level + XP_LIN_B * level + XP_CONST_C

static func get_cumulative_xp(level: int) -> int:
	var n: int = clampi(level - 1, 0, MAX_VOCATION_LEVEL - 1)
	return (5 * n * (n + 1) * (2 * n + 1)) / 2 + (85 * n * (n + 1)) / 2 + 100 * n

static func get_action_xp_catchup_mult(voc_level: int, max_voc_level: int) -> float:
	if voc_level >= MAX_VOCATION_LEVEL or voc_level >= max_voc_level:
		return 1.00
	if max_voc_level - voc_level >= CATCHUP_LEVEL_GAP_MIN or max_voc_level == MAX_VOCATION_LEVEL:
		return CATCHUP_ACTION_XP_MULT
	return 1.00

# κ borné : les autres affixes ne gonflent jamais
static func get_graft_kappa(b_hote: float, p_greffe: float, somme_p_autres: float) -> float:
	if somme_p_autres <= 0.0:
		return 1.0
	var p_greffe_eff: float = minf(p_greffe, floorf(GRAFT_MAX_SINGLE_AFFIX_SHARE * b_hote))
	return clampf((b_hote - p_greffe_eff) / somme_p_autres, 0.0, 1.0)

# Jour de jeu : frontière à 04:00 locale, fuseau mémorisé dans la sauvegarde
static func get_daily_reset_day_index(unix_utc: int, saved_tz_offset_sec: int) -> int:
	return floori(float(unix_utc + saved_tz_offset_sec - DAILY_RESET_HOUR_LOCAL * 3600) / 86400.0)
