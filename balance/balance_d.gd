class_name BalanceD
extends RefCounted

const _BalanceA = preload("res://balance/balance_a.gd")
const _BalanceB = preload("res://balance/balance_b.gd")

# Volet D valide le 23/10/2026 (messages Claude <-> Argon n°22 a n°24, audits par script).
# Base : balance_d.gd d'Argon (reponse au n°22), Griffe du n°23, consolide par Claude :
# couts de l'Atre au-dela du Nv2 nommes dans D, prix des Griffes calcules par scripts/economy.gd.
# Constantes uniquement. Aucune chaine accentuee : les textes affiches sont des cles TR_* (data/).

# ==============================================================================
# 1. LIEN (0 A 1000, 5 PALIERS) ET FUSION DE LA REPUTATION
# ==============================================================================
const BOND_MIN: int = 0
const BOND_MAX: int = 1000
const BOND_DECAY_OFFLINE: int = 0
const BOND_DECAY_SESSION: int = 0
const REPUTATION_MERGED_INTO_BOND: bool = true

enum BondTier {
	STRANGER = 0,
	ACQUAINTANCE = 1,
	COMPANION = 2,
	FRIEND = 3,
	CONFIDANT = 4,
	SWORN_HEARTH = 5
}

const BOND_TIER_THRESHOLDS: Array[int] = [100, 250, 450, 700, 1000]

const BOND_TIER_DATA: Dictionary = {
	BondTier.STRANGER: {"key": "TR_BOND_STRANGER", "min_bond": 0, "memory_scene_index": 0, "counts_for_synergy": false, "renames_shop": false, "unlocks_heritage_name": false},
	BondTier.ACQUAINTANCE: {"key": "TR_BOND_ACQUAINTANCE", "min_bond": 100, "memory_scene_index": 1, "counts_for_synergy": false, "renames_shop": false, "unlocks_heritage_name": false},
	BondTier.COMPANION: {"key": "TR_BOND_COMPANION", "min_bond": 250, "memory_scene_index": 2, "counts_for_synergy": true, "renames_shop": false, "unlocks_heritage_name": false},
	BondTier.FRIEND: {"key": "TR_BOND_FRIEND", "min_bond": 450, "memory_scene_index": 3, "counts_for_synergy": true, "renames_shop": false, "unlocks_heritage_name": false},
	BondTier.CONFIDANT: {"key": "TR_BOND_CONFIDANT", "min_bond": 700, "memory_scene_index": 4, "counts_for_synergy": true, "renames_shop": true, "unlocks_heritage_name": false},
	BondTier.SWORN_HEARTH: {"key": "TR_BOND_SWORN_HEARTH", "min_bond": 1000, "memory_scene_index": 5, "counts_for_synergy": true, "renames_shop": true, "unlocks_heritage_name": true}
}

# Paire active pour N_liens : les 2 suiveurs ont au moins COMPANION (250), flamme >= OBLIVION_STAGE_2_THRESHOLD
const FOLLOWER_SYNERGY_MIN_BOND_TIER: int = BondTier.COMPANION
const FOLLOWER_SYNERGY_MIN_BOND_VALUE: int = 250

# Equivalence Or <-> Lien : 1,50 Or nominal = 1 pt de Lien
# Choix Or au comptoir (18 Or) <-> choix Amitie (12 Lien) ; Cadeau EQUIP_FORGE (rachat max 36 Or) <-> 24 Lien
const GOLD_TO_BOND_BASE_RATIO: float = 1.50
const BOND_GAIN_COUNTER_AMITIE: int = 12
const COUNTER_EVENT_DAILY_CAP: int = 1

const BOND_GAIN_GIFT: int = 24 # cooldown : BalanceB.GIFT_MORAL_COOLDOWN_DAYS
const BOND_GAIN_EXPEDITION_FOLLOWER: int = 8
const BOND_GAIN_DELEGATED_MISSION: int = 4
const BOND_EXPEDITION_DAILY_CAP_RUNS: int = 2

const BOND_GAIN_BOARD_FICHE: int = 10
const BOND_DELEGATED_FICHE_MULT: float = 0.50
const BOND_FICHE_DAILY_CAP: int = 2
const BOND_GAIN_HEROIC_RESCUE: int = 30

const BOND_GAIN_VEILLEE: int = 10 # cooldown : BalanceB.VEILLEE_COOLDOWN_DAYS

# ==============================================================================
# 2. TRAITS DES PNJ (1 A 2 PAR PNJ, PROCEDURAUX, DETERMINISTES HORS-LIGNE)
# ==============================================================================
const NPC_MIN_TRAITS: int = 1
const NPC_MAX_TRAITS: int = 2
const TRAIT_COUNT_WEIGHTS: Dictionary = {1: 50, 2: 50}
const TRAIT_PROD_MULT_NEUTRAL: float = 1.00

enum TraitId {
	NOCTAMBULE = 0,
	COSTAUD = 1,
	PERFECTIONNISTE = 2,
	TETE_EN_L_AIR = 3,
	BOSSEUR = 4,
	BOUT_EN_TRAIN = 5
}

# Poids de tirage (somme = 100)
const TRAIT_DRAW_WEIGHTS: Dictionary = {
	TraitId.NOCTAMBULE: 15,
	TraitId.COSTAUD: 20,
	TraitId.PERFECTIONNISTE: 15,
	TraitId.TETE_EN_L_AIR: 15,
	TraitId.BOSSEUR: 20,
	TraitId.BOUT_EN_TRAIN: 15
}

# Incompatibilites symetriques : deux modificateurs de cadence ne se cumulent jamais
const TRAIT_INCOMPATIBILITIES: Dictionary = {
	TraitId.NOCTAMBULE: [],
	TraitId.COSTAUD: [],
	TraitId.PERFECTIONNISTE: [TraitId.TETE_EN_L_AIR, TraitId.BOSSEUR],
	TraitId.TETE_EN_L_AIR: [TraitId.PERFECTIONNISTE, TraitId.BOSSEUR],
	TraitId.BOSSEUR: [TraitId.PERFECTIONNISTE, TraitId.TETE_EN_L_AIR],
	TraitId.BOUT_EN_TRAIN: []
}

const TRAIT_ABSENT_MINDED_SKIP_PROB: float = 0.10 # en session ; hors-ligne O(1) : esperance, prod_mult 0,90

# Effets par trait (aucun effet sur IC, ilvl, SUPERIOR_CHANCE_*, XP, Cendre Vive ou creation d'Or)
const TRAIT_DEFS: Dictionary = {
	TraitId.NOCTAMBULE: {"key": "TR_TRAIT_NOCTAMBULE", "prod_mult": 1.00, "moral_daily_delta": 0.0, "cargo_mult": 1.00, "tool_wear_mult": 1.00, "works_at_night": true},
	TraitId.COSTAUD: {"key": "TR_TRAIT_COSTAUD", "prod_mult": 1.05, "moral_daily_delta": 0.0, "cargo_mult": _BalanceA.TRAIT_STURDY_CARGO_MULT, "tool_wear_mult": 1.00, "works_at_night": false},
	TraitId.PERFECTIONNISTE: {"key": "TR_TRAIT_PERFECTIONNISTE", "prod_mult": 0.90, "moral_daily_delta": 1.0, "cargo_mult": 1.00, "tool_wear_mult": 0.75, "works_at_night": false},
	TraitId.TETE_EN_L_AIR: {"key": "TR_TRAIT_TETE_EN_L_AIR", "prod_mult": 0.90, "moral_daily_delta": 2.0, "cargo_mult": 1.00, "tool_wear_mult": 1.00, "works_at_night": false},
	TraitId.BOSSEUR: {"key": "TR_TRAIT_BOSSEUR", "prod_mult": 1.10, "moral_daily_delta": -1.0, "cargo_mult": 1.00, "tool_wear_mult": 1.00, "works_at_night": false},
	TraitId.BOUT_EN_TRAIN: {"key": "TR_TRAIT_BOUT_EN_TRAIN", "prod_mult": 1.00, "moral_daily_delta": 2.0, "cargo_mult": 1.00, "tool_wear_mult": 1.00, "works_at_night": false}
}

# ==============================================================================
# 3. GRIFFE DE L'ARTISAN (TRAIT PRINCIPAL DU GERANT, n°23 : SANS OR, SANS DAG, SANS XP)
# ==============================================================================
const GRIFFE_USES_PRIMARY_TRAIT_ONLY: bool = true
const GRIFFE_NOCTAMBULE_OPEN_24_7: bool = true
const GRIFFE_NOCTAMBULE_FICHE_BOND_BONUS: int = 3
const GRIFFE_COSTAUD_STOCK_MAX_MULT: float = 1.15
const GRIFFE_PERFECTIONNISTE_GIFT_BOND_BONUS: int = 4
const GRIFFE_TETE_EN_L_AIR_PRICE_MULT_MAX: float = 1.15 # plafond 1,25 -> 1,15 : gain d'arbitrage max -1 (5 isolats)
const GRIFFE_BOSSEUR_COUNTER_BOND_BONUS: int = 3
const GRIFFE_BOUT_EN_TRAIN_CLIENT_MORAL_BONUS: float = 2.0
const GRIFFE_CLIENT_MORAL_MAX_BONUS: float = 2.0

const GRIFFE_DEFS: Dictionary = {
	TraitId.NOCTAMBULE: {"sign_key": "TR_SIGN_NIGHT_WATCH", "decor_key": "TR_DECOR_LANTERN_CHAIN", "open_24_7": GRIFFE_NOCTAMBULE_OPEN_24_7, "fiche_bond_bonus": GRIFFE_NOCTAMBULE_FICHE_BOND_BONUS, "gift_bond_bonus": 0, "stock_max_mult": 1.00, "price_mult_max_override": _BalanceB.PRICE_MULT_MAX, "counter_bond_bonus": 0, "client_moral_bonus": 0.0},
	TraitId.COSTAUD: {"sign_key": "TR_SIGN_HEAVY_BEAM", "decor_key": "TR_DECOR_OAK_CRATES", "open_24_7": false, "fiche_bond_bonus": 0, "gift_bond_bonus": 0, "stock_max_mult": GRIFFE_COSTAUD_STOCK_MAX_MULT, "price_mult_max_override": _BalanceB.PRICE_MULT_MAX, "counter_bond_bonus": 0, "client_moral_bonus": 0.0},
	TraitId.PERFECTIONNISTE: {"sign_key": "TR_SIGN_GILDED_COMPASS", "decor_key": "TR_DECOR_ORDERED_RACKS", "open_24_7": false, "fiche_bond_bonus": 0, "gift_bond_bonus": GRIFFE_PERFECTIONNISTE_GIFT_BOND_BONUS, "stock_max_mult": 1.00, "price_mult_max_override": _BalanceB.PRICE_MULT_MAX, "counter_bond_bonus": 0, "client_moral_bonus": 0.0},
	TraitId.TETE_EN_L_AIR: {"sign_key": "TR_SIGN_CROOKED_BELL", "decor_key": "TR_DECOR_SCATTERED_SCROLLS", "open_24_7": false, "fiche_bond_bonus": 0, "gift_bond_bonus": 0, "stock_max_mult": 1.00, "price_mult_max_override": GRIFFE_TETE_EN_L_AIR_PRICE_MULT_MAX, "counter_bond_bonus": 0, "client_moral_bonus": 0.0},
	TraitId.BOSSEUR: {"sign_key": "TR_SIGN_STRIKING_HAMMER", "decor_key": "TR_DECOR_DOUBLE_COUNTER", "open_24_7": false, "fiche_bond_bonus": 0, "gift_bond_bonus": 0, "stock_max_mult": 1.00, "price_mult_max_override": _BalanceB.PRICE_MULT_MAX, "counter_bond_bonus": GRIFFE_BOSSEUR_COUNTER_BOND_BONUS, "client_moral_bonus": 0.0},
	TraitId.BOUT_EN_TRAIN: {"sign_key": "TR_SIGN_SMILING_MUG", "decor_key": "TR_DECOR_WARM_GARLANDS", "open_24_7": false, "fiche_bond_bonus": 0, "gift_bond_bonus": 0, "stock_max_mult": 1.00, "price_mult_max_override": _BalanceB.PRICE_MULT_MAX, "counter_bond_bonus": 0, "client_moral_bonus": GRIFFE_BOUT_EN_TRAIN_CLIENT_MORAL_BONUS}
}

# ==============================================================================
# 4. CYCLE JOUR/NUIT ET HORAIRES DES PNJ (HEURE LOCALE REELLE)
# ==============================================================================
const USE_REAL_LOCAL_TIME: bool = true

enum DayPhase {
	DAWN = 0,  # 06:00 - 08:00
	DAY = 1,   # 08:00 - 19:00
	DUSK = 2,  # 19:00 - 22:00
	NIGHT = 3  # 22:00 - 06:00
}

const PHASE_START_HOUR_LOCAL: Dictionary = {DayPhase.DAWN: 6, DayPhase.DAY: 8, DayPhase.DUSK: 19, DayPhase.NIGHT: 22}

# 5 h + 5 h = BalanceB.MORAL_WORK_HOURS_PER_DAY
const SCHEDULE_DIURNAL: Dictionary = {"work_block_1": Vector2i(8, 13), "meal_break": Vector2i(13, 14), "work_block_2": Vector2i(14, 19), "social_veillee": Vector2i(19, 22), "sleep": Vector2i(22, 8)}
const SCHEDULE_NOCTURNAL: Dictionary = {"work_block_1": Vector2i(20, 1), "meal_break": Vector2i(1, 2), "work_block_2": Vector2i(2, 7), "social_veillee": Vector2i(7, 10), "sleep": Vector2i(10, 20)}

const SHOP_OPEN_HOUR_LOCAL: int = 8
const SHOP_CLOSE_HOUR_LOCAL: int = 22
const BOARD_OPEN_24_7: bool = true

# Cloche de Garde : boutique fermee la nuit = comptoir ouvert au joueur, sans malus ni surcout
const NIGHT_BELL_ENABLED: bool = true
const NIGHT_BELL_MORAL_COST: float = 0.0
const NIGHT_BELL_PRICE_MULT: float = 1.00
const NIGHT_BELL_ALLOWS_COUNTER_EVENT: bool = true

# ==============================================================================
# 5. LANTERNE-MERE (NIVEAUX 1 A 5, 0 OR, SANS IMPACT SUR L'XP NI LES TEMPS DU VOLET A)
# ==============================================================================
const LANTERN_MAX_LEVEL: int = 5
const VERTICAL_SLICE_MAX_LANTERN_LEVEL: int = 2

# Index 0 = Niveau 1 (depart) .. Index 4 = Niveau 5
const LANTERN_REQ_ISOLAT: Array[int] = [1, 1, 2, 3, 4]
const LANTERN_REQ_MAX_VOC_LEVEL: Array[int] = [1, 5, 15, 25, 35]
const LANTERN_UPGRADE_BRAISE_COST: Array[int] = [0, 90, 300, 600, 1050]
const LANTERN_UPGRADE_COAL_COST: Array[int] = [0, 10, 25, 50, 80]
const LANTERN_UPGRADE_GOLD_COST: Array[int] = [0, 0, 0, 0, 0]

# ==============================================================================
# 6. GRAND ATRE (NIVEAUX 1 A 5, RAYON, POSTES, PLAFOND PNJ, AUTO-ASSIGNATION)
# ==============================================================================
const ATRE_MAX_LEVEL: int = 5
const VERTICAL_SLICE_MAX_ATRE_LEVEL: int = 2
const VERTICAL_SLICE_NPC_CAP: int = 5
const TILE_SIZE_PX: int = 16

# Index 0 = Niveau 1 .. Index 4 = Niveau 5
const ATRE_RADIUS_TILES: Array[int] = [12, 18, 24, 30, 36]
const ATRE_WORK_POSTS_CAP: Array[int] = [6, 10, 16, 23, 30]
const ATRE_NPC_CAP: Array[int] = [5, 10, 16, 23, 30]

# Or : BalanceB.ATRE_UPGRADE_COST_QUAD_BASE x L_depart^2. Minerais et Tier 0 : le cout du Nv2 x L_depart.
const ATRE_UPGRADE_MINERAL_COST_PER_LVL: int = _BalanceB.ATRE_LVL2_MINERAL_COST
const ATRE_UPGRADE_TIER0_COST_PER_LVL: int = _BalanceB.ATRE_LVL2_TIER0_MAT_COST

# Auto-assignation = Affinite x Besoin du village x Aptitude (en session seulement)
const AUTO_ASSIGN_SESSION_ONLY: bool = true
const AFFINITY_BASE: float = 1.00
const AFFINITY_FAVORITE_JOB_BONUS: float = 0.15
const AFFINITY_TRAIT_MATCH_BONUS: float = 0.10
const AFFINITY_MIN: float = 0.80
const AFFINITY_MAX: float = 1.25

const VILLAGE_NEED_MAX: float = 2.00
const VILLAGE_NEED_MIN_ACTIVE: float = 0.50
const VILLAGE_NEED_FULL_STOCK_MIN: float = 0.10
const VILLAGE_NEED_GUARD_DEFAULT: float = 1.00

enum JobPostType {
	EXTRACTION = 0,
	FORGE = 1,
	TAVERN = 2,
	GATHER = 3,
	MERCHANT = 4,
	GUARD = 5
}

const TRAIT_FAVORED_POSTS: Dictionary = {
	TraitId.NOCTAMBULE: [JobPostType.GUARD, JobPostType.TAVERN],
	TraitId.COSTAUD: [JobPostType.EXTRACTION, JobPostType.GUARD],
	TraitId.PERFECTIONNISTE: [JobPostType.FORGE],
	TraitId.TETE_EN_L_AIR: [JobPostType.GATHER],
	TraitId.BOSSEUR: [JobPostType.EXTRACTION, JobPostType.FORGE],
	TraitId.BOUT_EN_TRAIN: [JobPostType.TAVERN, JobPostType.MERCHANT]
}

# Delta du n°38 (Argon, validé par Claude le 28/10/2026, audit-n38.md) : à ajouter tel quel à balance_d.gd, § 6.
# Aptitudes secondaires des 5 PNJ de depart (principale = BalanceB.STARTING_NPC_MAIN_APTITUDE_STARS = 2)
const APTITUDE_STARS_MIN: int = 0
const APTITUDE_STARS_MAX: int = 5
const SECONDARY_APTITUDE_MAX_OFFSET_FROM_MAIN: int = -1
const STARTING_NPC_SECONDARY_MAX_STARS: int = _BalanceB.STARTING_NPC_MAIN_APTITUDE_STARS + SECONDARY_APTITUDE_MAX_OFFSET_FROM_MAIN # 1 etoile max
const STARTING_NPC_SECONDARY_STAR_WEIGHTS: Dictionary = {0: 60, 1: 40} # somme = 100

# Metier favori : poste de depart du PNJ (coincide avec son aptitude principale a 2 etoiles)
const FAVORITE_JOB_FROM_STARTING_POST: bool = true

# Postes ouverts en tranche verticale (GATHER et MERCHANT sont grises : ni flux ni boutique en tranche)
const VERTICAL_SLICE_ACTIVE_JOB_POSTS: Array[int] = [
	JobPostType.EXTRACTION,
	JobPostType.FORGE,
	JobPostType.TAVERN,
	JobPostType.GUARD
]

# Plafond de postes par type selon le niveau de l'Atre en tranche (sommes = 6 au Nv1, 10 au Nv2 = ATRE_WORK_POSTS_CAP)
const VERTICAL_SLICE_POST_SLOTS_BY_ATRE_LVL: Dictionary = {
	1: {JobPostType.EXTRACTION: 2, JobPostType.FORGE: 1, JobPostType.TAVERN: 1, JobPostType.GUARD: 2, JobPostType.GATHER: 0, JobPostType.MERCHANT: 0},
	2: {JobPostType.EXTRACTION: 3, JobPostType.FORGE: 2, JobPostType.TAVERN: 2, JobPostType.GUARD: 3, JobPostType.GATHER: 0, JobPostType.MERCHANT: 0}
}

# Gerance, cout de changement de poste et garde-fous d'auto-assignation / tick quotidien (jalons 18-19)
const MANAGER_RETAINS_OWNERSHIP_ON_MOVE: bool = true
const STOCK_OVERFLOW_KEEP_ON_MAX_DROP: bool = true
const POST_CHANGE_GOLD_COST: int = 0
const POST_CHANGE_MORAL_COST: float = 0.0
const POST_CHANGE_PROD_PENALTY: float = 0.0
const POST_CHANGE_EXTRA_TOOL_WEAR: float = 0.0

const AUTO_ASSIGN_DEFERRED_TO_NEXT_TICK: bool = true
const AUTO_ASSIGN_MIN_SCORE_GAIN: float = 0.25
const AUTO_ASSIGN_MAX_CHANGES_PER_DAY_INDEX: int = 1
const DEFER_CADENCE_AND_POSTURE_TO_NEXT_TICK: bool = true
const GUARD_USES_NORMAL_CADENCE_DRAIN: bool = true

# ==============================================================================
# 7. FONCTIONS (les prix avec Griffe passent par scripts/economy.gd et price_mult_max_override)
# ==============================================================================
static func get_bond_tier(bond_value: int) -> int:
	var b: int = clampi(bond_value, BOND_MIN, BOND_MAX)
	for i in range(BOND_TIER_THRESHOLDS.size() - 1, -1, -1):
		if b >= BOND_TIER_THRESHOLDS[i]:
			return i + 1
	return BondTier.STRANGER

static func count_active_follower_synergy_pairs(follower_bonds: Array[int], lantern_flame: float) -> int:
	if lantern_flame < _BalanceA.OBLIVION_STAGE_2_THRESHOLD:
		return 0
	var eligible_count: int = 0
	for i in mini(follower_bonds.size(), _BalanceA.MAX_FOLLOWERS):
		if follower_bonds[i] >= FOLLOWER_SYNERGY_MIN_BOND_VALUE:
			eligible_count += 1
	return clampi(eligible_count * (eligible_count - 1) / 2, _BalanceA.MIN_SUIVEUR_PAIRS, _BalanceA.MAX_SUIVEUR_PAIRS)

static func get_npc_trait_prod_mult(trait_ids: Array[int]) -> float:
	var mult: float = TRAIT_PROD_MULT_NEUTRAL
	for t_id in trait_ids:
		mult *= float(TRAIT_DEFS[t_id]["prod_mult"])
	return mult

static func get_npc_trait_moral_delta(trait_ids: Array[int]) -> float:
	var delta: float = 0.0
	for t_id in trait_ids:
		delta += float(TRAIT_DEFS[t_id]["moral_daily_delta"])
	return delta

static func compute_atre_upgrade_gold_cost(from_level: int) -> int:
	var lvl: int = clampi(from_level, 1, ATRE_MAX_LEVEL - 1)
	return _BalanceB.ATRE_UPGRADE_COST_QUAD_BASE * lvl * lvl

static func compute_atre_upgrade_mineral_cost(from_level: int) -> int:
	return ATRE_UPGRADE_MINERAL_COST_PER_LVL * clampi(from_level, 1, ATRE_MAX_LEVEL - 1)

static func compute_atre_upgrade_tier0_cost(from_level: int) -> int:
	return ATRE_UPGRADE_TIER0_COST_PER_LVL * clampi(from_level, 1, ATRE_MAX_LEVEL - 1)

static func compute_village_need(stock_current: int, stock_max: int, is_guard_post: bool) -> float:
	if is_guard_post or stock_max <= 0:
		return VILLAGE_NEED_GUARD_DEFAULT
	if stock_current >= stock_max:
		return VILLAGE_NEED_FULL_STOCK_MIN
	var s: float = clampf(float(stock_current) / float(stock_max), 0.0, 1.0)
	return VILLAGE_NEED_MAX - (VILLAGE_NEED_MAX - VILLAGE_NEED_MIN_ACTIVE) * s

static func compute_auto_assign_score(stars: int, is_favorite_job: bool, has_matching_trait: bool, stock_current: int, stock_max: int, is_guard_post: bool) -> float:
	var aptitude: float = _BalanceB.APTITUDE_MULT_BASE + _BalanceB.APTITUDE_MULT_PER_STAR * float(clampi(stars, 0, 5))
	var affinity: float = AFFINITY_BASE
	if is_favorite_job:
		affinity += AFFINITY_FAVORITE_JOB_BONUS
	if has_matching_trait:
		affinity += AFFINITY_TRAIT_MATCH_BONUS
	affinity = clampf(affinity, AFFINITY_MIN, AFFINITY_MAX)
	return affinity * compute_village_need(stock_current, stock_max, is_guard_post) * aptitude
