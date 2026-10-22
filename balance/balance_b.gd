class_name BalanceB
extends RefCounted

const _BalanceA = preload("res://balance/balance_a.gd")

# ==============================================================================
# 1. MATERIAUX, POIDS (KG), VALEURS DE BASE EN OR (P_BASE) & INDEXATION D'ISOLAT
# ==============================================================================
const ISOLAT_GOLD_MULTIPLIERS: Array[float] = _BalanceA.ISOLAT_XP_MULTIPLIERS # une seule source

const ITEM_WEIGHT_KG: Dictionary = {
	"FERRAILLE_BRUTE": 0.5,
	"BOIS_CHAUFFE": 0.5,
	"HERBE_CENDRE": 0.5,
	"CHARBON_ARDENT": 0.5,
	"MINERAI_FER_BRAISE": 1.0,
	"BOUILLON_BRAISE": 0.5,
	"OUTIL_SIMPLE": 1.0,
	"EQUIP_FORGE": 2.0,
	"COLIS_LIVRAISON": 10.0,
	"KIT_BRASERO": 15.0
}

const ITEM_BASE_GOLD: Dictionary = {
	"FERRAILLE_BRUTE": 2,
	"BOIS_CHAUFFE": 2,
	"HERBE_CENDRE": 2,
	"CHARBON_ARDENT": 6,
	"MINERAI_FER_BRAISE": 8,
	"BOUILLON_BRAISE": 8,
	"OUTIL_SIMPLE": 12,
	"EQUIP_FORGE": 48,
	"COLIS_LIVRAISON": 60,
	"KIT_BRASERO": 120
}

const CRAFT_MAT_COST_SIMPLE_TOOL: int = 2
const CRAFT_MAT_COST_BROTH: int = 2
const CRAFT_MINERAL_COST_EQUIPMENT: int = 4
const NO_CENDRE_CRAFT_GOLD_VALUE_MULT: float = 0.6667
const SHARD_RAW_SELLABLE: bool = false

# ==============================================================================
# 2. PRODUCTION DES PNJ, APTITUDES, CADENCES ET USURE
# ==============================================================================
const STARTING_NPC_MAIN_APTITUDE_STARS: int = 2

const PROD_BASE_EXTRACTION_PER_HOUR: float = 5.0
const PROD_BASE_FORGE_PER_HOUR: float = 2.5
const PROD_BASE_TAVERN_PER_HOUR: float = 3.0

const APTITUDE_MULT_BASE: float = 0.60
const APTITUDE_MULT_PER_STAR: float = 0.20

const CADENCE_PROD_MULT: Dictionary = {
	"PAISIBLE": 0.80,
	"NORMAL": 1.00,
	"FORGE_ARDENTE": 1.30
}

const MORAL_PROD_MULT_STRIKE: float = 0.00
const MORAL_PROD_MULT_LOW: float = 0.75
const MORAL_PROD_MULT_NORMAL: float = 1.00
const MORAL_PROD_MULT_HIGH: float = 1.15

const TOOL_DURABILITY_MAX: float = 100.0
const TOOL_WEAR_PER_WORK_HOUR: float = 2.0
const TOOL_WEAR_PER_MISSION: float = 15.0
const TOOL_BROKEN_PROD_MULT: float = 0.60
const HEIRLOOM_TOOL_WEAR_RATE: float = 0.0

# ==============================================================================
# 3. DAG HORS-LIGNE O(1), STASE DOUCE & GARDE-FOU HORLOGE
# ==============================================================================
const CLOCK_DRIFT_TOLERANCE_SEC: int = 60
const OFFLINE_MAX_HOURS: float = 12.0
const OFFLINE_EFFICIENCY_FACTOR: float = 0.60
const OFFLINE_GLANAGE_EFFICIENCY_FACTOR: float = 0.25
const OFFLINE_FULL_STOCK_MORAL_PER_HOUR: float = 2.0
const VILLAGE_FREEZE_BEYOND_OFFLINE_CAP: bool = true
const STRATE1_TAVERNE_PRIORITY_MAX_MEALS: int = 6
const RUPTURE_FICHE_STOCK_RATIO_THRESHOLD: float = 0.15
const MAX_ACTIVE_RUPTURE_FICHES_PER_SHOP: int = 1

# ==============================================================================
# 4. BOUTIQUES, STOCKS, PRIX DYNAMIQUES, BUDGETS CLIENTS ET PUITS D'OR
# ==============================================================================
const SHOP_INITIAL_TREASURY_GOLD: int = 150
const SHOP_STOCK_MAX_MAT_BASE: int = 60
const SHOP_STOCK_MAX_MAT_PER_LVL: int = 40
const SHOP_STOCK_MAX_PROD_BASE: int = 30
const SHOP_STOCK_MAX_PROD_PER_LVL: int = 20
const FORGE_RACK_MAX_WEAPONS: int = 6
const RACK_OVERFLOW_SIMPLE_TOOLS_YIELD: int = 2

const POSTURE_TARGET_STOCK_RATIO: Dictionary = {
	"SOLIDAIRE": 0.40,
	"EQUILIBRE": 0.60,
	"EXPORTATION": 0.85
}

const POSTURE_VILLAGE_TAX_RATE: Dictionary = {
	"SOLIDAIRE": 0.10,
	"EQUILIBRE": 0.20,
	"EXPORTATION": 0.30
}

const PRICE_ELASTICITY_INTERCEPT: float = 1.25
const PRICE_ELASTICITY_SLOPE: float = 0.25
const PRICE_MULT_MIN: float = 0.75
const PRICE_MULT_MAX: float = 1.25
const SHOP_BUYBACK_DISCOUNT_RATIO: float = 0.60
const PLAYER_PURCHASE_GENERATES_TAX: bool = false

const SHOP_REVENUE_NPC_WAGE_SHARE: float = 0.45
const NPC_BASE_DAILY_STIPEND_GOLD: int = 10
const NPC_NEW_SHOP_SAVINGS_THRESHOLD: int = 400 # inactif en tranche

const CARAVAN_INTERVAL_UTC_SEC: int = 172800
const CARAVAN_BASE_BUDGET_GOLD: int = 160
const CARAVAN_PAVED_ROUTE_BONUS_RATIO: float = 0.20

const DAILY_CLIENT_BUDGET_BASE_GOLD: Dictionary = {
	"MATERIAUX": 8,
	"FORGE": 144,
	"TAVERNE": 48,
	"COMPTOIR": 18
}

const FICHE_BASE_GOLD_REWARD: int = 22
const COUNTER_EVENT_DURATION_SEC: float = 45.0
const COUNTER_EVENT_GOLD_REWARD_AVG: int = 18

const SHOP_DAILY_FIXED_SINK_PER_LVL: int = 8
const SHOP_BUILD_LVL1_COST_GOLD: int = 100
const SHOP_UPGRADE_COST_QUAD_BASE: int = 250
const SHOP_TIER0_UPGRADE_MAT_PER_LVL: int = 15
const ATRE_UPGRADE_COST_QUAD_BASE: int = 600
const ATRE_LVL2_MINERAL_COST: int = 40
const ATRE_LVL2_TIER0_MAT_COST: int = 40
const ROUTE_PAVE_COST_GOLD: int = 500
const GRAFT_GOLD_COST_PER_ILVL: int = 25

# ==============================================================================
# 5. MORAL DES PNJ (0 A 100), GREVE DOUCE, VEILLEE ET BESOINS
# ==============================================================================
const MORAL_MAX_TICKS_PER_DAY_INDEX: int = 1
const MORAL_MIN: float = 0.0
const MORAL_MAX: float = 100.0
const MORAL_EQUILIBRIUM_TARGET: float = 80.0
const MORAL_ATRE_MEAN_REVERSION_RATE: float = 0.25

const MORAL_STRIKE_ENTER_THRESHOLD: float = 20.0
const MORAL_STRIKE_EXIT_THRESHOLD: float = 50.0
const MORAL_STRIKE_EXIT_CAP_VALUE: float = 50.0
const MORAL_STRIKE_DAILY_ATRE_GAIN: float = 40.0
const MORAL_LOW_PENALTY_THRESHOLD: float = 50.0
const MORAL_HIGH_BONUS_THRESHOLD: float = 85.0

const MORAL_WORK_HOURS_PER_DAY: float = 10.0
const MORAL_DRAIN_PER_WORK_HOUR: Dictionary = {
	"PAISIBLE": 0.60,
	"NORMAL": 1.20,
	"FORGE_ARDENTE": 2.40
}

const MORAL_GAIN_DAILY_MEAL: float = 6.0
const MORAL_PENALTY_NO_MEAL: float = -8.0
const MORAL_GAIN_OFFLINE_MISSING_MEAL: float = 0.0
const MORAL_GAIN_SLEEP_BASE: float = 6.0
const MORAL_GAIN_SLEEP_PER_HOUSE_LVL: float = 2.0

const MORAL_GAIN_VEILLEE_MEAL: float = 10.0
const VEILLEE_BROTH_COST_COUNT: int = 5
const VEILLEE_COAL_COST_COUNT: int = 2
const VEILLEE_MAX_NPCS_AFFECTED: int = 5
const VEILLEE_COOLDOWN_DAYS: int = 3

const MORAL_GAIN_GIFT: float = 12.0
const GIFT_MORAL_COOLDOWN_DAYS: int = 3

# ==============================================================================
# 6. LOGISTIQUE, MISSIONS DELEGUEES, BRAISES D'ACTIVITE ET CHANTIERS
# ==============================================================================
const MISSION_SQUAD_MIN_SIZE: int = 2
const MISSION_SQUAD_MAX_SIZE: int = 4
const DELEGATED_MISSION_PAVED_MIN: float = 45.0
const DELEGATED_MISSION_UNPAVED_MIN: float = 90.0

const MISSION_INDIV_POWER_BASE: float = 0.40
const MISSION_INDIV_POWER_PER_STAR: float = 0.20
const MISSION_SCORE_REQ_STANDARD: float = 1.60
const MISSION_SCORE_REQ_HARD: float = 3.20
const MISSION_SUCCESS_BASE: float = 0.60
const MISSION_SUCCESS_SLOPE: float = 0.25
const MISSION_SUCCESS_MIN: float = 0.15
const MISSION_SUCCESS_MAX: float = 0.95
const MISSION_SUCCESS_CARGO_RETURN_RATIO: float = 1.00
const MISSION_FAILURE_CARGO_RETURN_RATIO: float = 0.00
const DELEGATED_MINING_MISSION_MINERAL_YIELD: int = 4
const INJURED_RECOVERY_DURATION_SEC: float = 7200.0

const BRAISE_GAIN_STD_RUN: int = 15
const BRAISE_GAIN_BOSS_BONUS: int = 5
const BRAISE_GAIN_LONG_RUN: int = 35
const BRAISE_GAIN_EVACUATION: int = 5
const BRAISE_TIME_REDUCTION_MIN: float = 2.0
const CHANTIER_MAX_SKIP_RATIO: float = 0.50

const CHANTIER_SHOP_LVL1_MIN: float = 30.0
const CHANTIER_UPGRADE_QUAD_BASE_MIN: float = 60.0
const CHANTIER_ATRE_LVL2_MIN: float = 240.0
const CHANTIER_ROUTE_PAVE_MIN: float = 60.0
const CHANTIER_MAX_DURATION_MIN: float = 1440.0

