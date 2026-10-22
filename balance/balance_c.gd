class_name BalanceC
extends RefCounted

const _BalanceA = preload("res://balance/balance_a.gd")

# Volet C valide le 22/10/2026 (messages Claude <-> Argon n°16 a n°21, audits par script).
# Base : balance_c.gd d'Argon (reponse au n°19), avec les valeurs du n°16 pour les poids de drop
# et les 5 types d'arme, et des fonctions branchees sur les constantes de BalanceA (sans floor).
# Constantes uniquement. Aucune chaine accentuee : les textes affiches sont des cles TR_* (data/).

# ==============================================================================
# 1. LES 5 ECOLES DE FORGE (ARMES UNIQUEMENT)
# ==============================================================================
enum SchoolId {
	NONE = 0,
	FOYER = 1,      # Isolat 1 : Clair-Foyer - Neutre
	SPORE = 2,      # Isolat 2 : Tourbiere des Lanternes - Neutre
	BRASIER = 3,    # Isolat 3 : Pic-Forgez - Braise
	ABYSSE = 4,     # Isolat 4 : Port-Sardine - Givre
	OBSIDIENNE = 5  # Isolat 5 : Citadelle d'Obsidienne - Neutre
}

# Okabe-Ito, contraste sur #3A3D42 : 4,84 / 3,19 / 4,18 / 4,73 / 3,56
const SCHOOL_DATA: Dictionary = {
	SchoolId.FOYER: {"key": "ECOLE_FOYER", "origin_isolat": 1, "color_hex": "#E69F00", "stamp": "STAMP_ANVIL", "implicit_element": "NEUTRAL", "offensive_share": 0.50, "unlocked_day_one": true},
	SchoolId.SPORE: {"key": "ECOLE_SPORE", "origin_isolat": 2, "color_hex": "#009E73", "stamp": "STAMP_SPORE_FLASK", "implicit_element": "NEUTRAL", "offensive_share": 0.55, "unlocked_day_one": false},
	SchoolId.BRASIER: {"key": "ECOLE_BRASIER", "origin_isolat": 3, "color_hex": "#FF7A1A", "stamp": "STAMP_TWIN_FLAME", "implicit_element": "EMBER", "offensive_share": 0.60, "unlocked_day_one": false},
	SchoolId.ABYSSE: {"key": "ECOLE_ABYSSE", "origin_isolat": 4, "color_hex": "#56B4E9", "stamp": "STAMP_BARBED_HARPOON", "implicit_element": "FROST", "offensive_share": 0.65, "unlocked_day_one": false},
	SchoolId.OBSIDIENNE: {"key": "ECOLE_OBSIDIENNE", "origin_isolat": 5, "color_hex": "#CC79A7", "stamp": "STAMP_KEYSTONE_ARCH", "implicit_element": "NEUTRAL", "offensive_share": 0.40, "unlocked_day_one": false}
}

# Tranche verticale : Foyer + Brasier, raretes Commun / Bon / Rare
const VERTICAL_SLICE_SCHOOLS: Array[int] = [SchoolId.FOYER, SchoolId.BRASIER]
const VERTICAL_SLICE_MAX_RARITY_INDEX: int = 2

# ==============================================================================
# 2. BONUS 3/3 ET POIDS DE DROP
# ==============================================================================
# Source unique (remplace WEAPON_SAME_SCHOOL_3PIECE_AFFINITY_BONUS de balance_a.gd). Pas de palier 2/3.
const SCHOOL_SET_2_BONUS: float = 0.000
const SCHOOL_SET_3_WEAPON_ATK_BONUS: float = 0.035

# Garde et Pommeau tirent l'Ecole de la Lame avec cette probabilite (0,70^2 = 49 % de 3/3)
const DROP_PART_SAME_SCHOOL_PROB: float = 0.70

# Ecole de la Lame par isolat (n°16), somme = 100
const ISOLAT_SCHOOL_DROP_WEIGHTS: Dictionary = {
	1: {SchoolId.FOYER: 55, SchoolId.BRASIER: 20, SchoolId.SPORE: 15, SchoolId.ABYSSE: 5, SchoolId.OBSIDIENNE: 5},
	2: {SchoolId.FOYER: 20, SchoolId.BRASIER: 10, SchoolId.SPORE: 55, SchoolId.ABYSSE: 10, SchoolId.OBSIDIENNE: 5},
	3: {SchoolId.FOYER: 15, SchoolId.BRASIER: 55, SchoolId.SPORE: 10, SchoolId.ABYSSE: 10, SchoolId.OBSIDIENNE: 10},
	4: {SchoolId.FOYER: 10, SchoolId.BRASIER: 10, SchoolId.SPORE: 15, SchoolId.ABYSSE: 55, SchoolId.OBSIDIENNE: 10},
	5: {SchoolId.FOYER: 10, SchoolId.BRASIER: 10, SchoolId.SPORE: 10, SchoolId.ABYSSE: 15, SchoolId.OBSIDIENNE: 55}
}

const VERTICAL_SLICE_DROP_WEIGHTS: Dictionary = {SchoolId.FOYER: 70, SchoolId.BRASIER: 30}

# ==============================================================================
# 3. LES 5 TYPES D'ARME (SOCLE A5 : MELEE + ARC / ARBALETE) ET 3 PIECES
# ==============================================================================
enum WeaponType {
	SWORD_SHIELD = 0,   # Epee & Ecu
	CLEAVER_AXE = 1,    # Hache d'Entaille
	SCOUT_GLAIVE = 2,   # Vouge d'Eclaireur
	HUNTING_BOW = 3,    # Arc de Chasse
	WINCH_CROSSBOW = 4  # Arbalete a Treuil
}

enum WeaponPartSlot {
	PART_BLADE = 0,  # 60 % ATK_arme + element implicite + slots d'affixe 1 et 4
	PART_GUARD = 1,  # 25 % ATK_arme + slot 2
	PART_POMMEL = 2  # 15 % ATK_arme + slot 3
}

const WEAPON_PART_ATK_SHARE: Array[float] = [0.60, 0.25, 0.15]

# Piece porteuse de l'affixe d'indice 0..3 (1 / 2 / 3 / 4 / 4 affixes selon la rarete, Volet A)
const AFFIX_SLOT_TO_PART_MAP: Array[int] = [WeaponPartSlot.PART_BLADE, WeaponPartSlot.PART_GUARD, WeaponPartSlot.PART_POMMEL, WeaponPartSlot.PART_BLADE]

# Vitesses lues dans BalanceA, portees du n°16, genre et elision pour les jetons grammaticaux
const WEAPON_SPECS: Dictionary = {
	WeaponType.SWORD_SHIELD: {"key": "WEAPON_SWORD_SHIELD", "is_ranged": false, "range_px": 40.0, "gender": "F", "elision": true, "favored_school": SchoolId.FOYER},
	WeaponType.CLEAVER_AXE: {"key": "WEAPON_CLEAVER_AXE", "is_ranged": false, "range_px": 44.0, "gender": "F", "elision": false, "favored_school": SchoolId.BRASIER},
	WeaponType.SCOUT_GLAIVE: {"key": "WEAPON_SCOUT_GLAIVE", "is_ranged": false, "range_px": 52.0, "gender": "F", "elision": false, "favored_school": SchoolId.OBSIDIENNE},
	WeaponType.HUNTING_BOW: {"key": "WEAPON_HUNTING_BOW", "is_ranged": true, "range_px": 160.0, "gender": "M", "elision": true, "favored_school": SchoolId.SPORE},
	WeaponType.WINCH_CROSSBOW: {"key": "WEAPON_WINCH_CROSSBOW", "is_ranged": true, "range_px": 180.0, "gender": "F", "elision": true, "favored_school": SchoolId.ABYSSE}
}

# ==============================================================================
# 4. LES 12 AFFIXES (1 IMPLICITE + 7 COMBAT + 4 UTILITAIRES)
# ==============================================================================
# Part max de B par affixe selon le nombre d'affixes de la piece (Commun / Bon / Rare / Epique et Legendaire)
const MAX_AFFIX_BUDGET_SHARE_BY_COUNT: Dictionary = {1: 1.00, 2: 0.60, 3: 0.50, 4: 0.45}

enum AffixVisualFamily {BRUTAL = 0, SWIFT = 1, BASTION = 2}

# Cout en points : base_cost par unite, multiplie par S(ilvl) si scales_with_s
const AFFIX_DEFS: Dictionary = {
	"FLAT_ATK": {"category": "OFFENSIVE", "visual_family": AffixVisualFamily.BRUTAL, "unit_value": 0.50, "base_cost": 1.00, "scales_with_s": false, "cap_per_piece_units": 9999.0, "cap_global_units": 9999.0},
	"PCT_ATK": {"category": "OFFENSIVE", "visual_family": AffixVisualFamily.BRUTAL, "unit_value": 0.01, "base_cost": 0.46, "scales_with_s": true, "cap_per_piece_units": 6.0, "cap_global_units": 20.0}, # % d'ATK_arme
	"PCT_ASPD": {"category": "OFFENSIVE", "visual_family": AffixVisualFamily.SWIFT, "unit_value": 0.01, "base_cost": 0.90, "scales_with_s": true, "cap_per_piece_units": 4.0, "cap_global_units": 12.0},
	"PCT_CRIT_CHANCE": {"category": "OFFENSIVE", "visual_family": AffixVisualFamily.SWIFT, "unit_value": 0.01, "base_cost": 0.55, "scales_with_s": true, "cap_per_piece_units": 4.0, "cap_global_units": 12.0},
	"PCT_CRIT_DMG": {"category": "OFFENSIVE", "visual_family": AffixVisualFamily.SWIFT, "unit_value": 0.01, "base_cost": 0.18, "scales_with_s": true, "cap_per_piece_units": 10.0, "cap_global_units": 30.0},
	"FLAT_HP": {"category": "DEFENSIVE", "visual_family": AffixVisualFamily.BASTION, "unit_value": 3.00, "base_cost": 1.00, "scales_with_s": false, "cap_per_piece_units": 9999.0, "cap_global_units": 9999.0},
	"FLAT_DEF": {"category": "DEFENSIVE", "visual_family": AffixVisualFamily.BASTION, "unit_value": 0.55, "base_cost": 1.00, "scales_with_s": false, "cap_per_piece_units": 9999.0, "cap_global_units": 9999.0},
	"ELEM_DMG": {"category": "IMPLICIT_BLADE", "visual_family": AffixVisualFamily.BRUTAL, "unit_value": 1.00, "base_cost": 0.00, "scales_with_s": false, "cap_per_piece_units": 1.0, "cap_global_units": 1.0},
	"MOVE_SPEED": {"category": "UTILITY", "visual_family": AffixVisualFamily.SWIFT, "unit_value": 0.01, "base_cost": 0.30, "scales_with_s": true, "cap_per_piece_units": 4.0, "cap_global_units": 12.0},
	"CARGO_CAP": {"category": "UTILITY", "visual_family": AffixVisualFamily.BASTION, "unit_value": 1.00, "base_cost": 0.35, "scales_with_s": true, "cap_per_piece_units": 2.0, "cap_global_units": 6.0}, # kg
	"MINE_YIELD": {"category": "UTILITY", "visual_family": AffixVisualFamily.BRUTAL, "unit_value": 0.01, "base_cost": 0.40, "scales_with_s": true, "cap_per_piece_units": 5.0, "cap_global_units": 15.0}, # minage manuel en expedition seulement
	"GATHER_YIELD": {"category": "UTILITY", "visual_family": AffixVisualFamily.SWIFT, "unit_value": 0.01, "base_cost": 0.40, "scales_with_s": true, "cap_per_piece_units": 5.0, "cap_global_units": 15.0} # inactif en tranche
}

# Poids de tirage des affixes de combat par Ecole (somme = 100)
const SCHOOL_COMBAT_AFFIX_WEIGHTS: Dictionary = {
	SchoolId.FOYER: {"FLAT_ATK": 20, "PCT_ATK": 10, "PCT_ASPD": 10, "PCT_CRIT_CHANCE": 5, "PCT_CRIT_DMG": 5, "FLAT_HP": 28, "FLAT_DEF": 22},
	SchoolId.SPORE: {"FLAT_ATK": 14, "PCT_ATK": 8, "PCT_ASPD": 20, "PCT_CRIT_CHANCE": 8, "PCT_CRIT_DMG": 5, "FLAT_HP": 27, "FLAT_DEF": 18},
	SchoolId.BRASIER: {"FLAT_ATK": 26, "PCT_ATK": 18, "PCT_ASPD": 6, "PCT_CRIT_CHANCE": 5, "PCT_CRIT_DMG": 5, "FLAT_HP": 22, "FLAT_DEF": 18},
	SchoolId.ABYSSE: {"FLAT_ATK": 12, "PCT_ATK": 8, "PCT_ASPD": 10, "PCT_CRIT_CHANCE": 18, "PCT_CRIT_DMG": 17, "FLAT_HP": 20, "FLAT_DEF": 15},
	SchoolId.OBSIDIENNE: {"FLAT_ATK": 18, "PCT_ATK": 10, "PCT_ASPD": 4, "PCT_CRIT_CHANCE": 4, "PCT_CRIT_DMG": 4, "FLAT_HP": 32, "FLAT_DEF": 28}
}

# Armures (sans Ecole)
const ARMOR_COMBAT_AFFIX_WEIGHTS: Dictionary = {"FLAT_ATK": 20, "PCT_ATK": 10, "PCT_ASPD": 8, "PCT_CRIT_CHANCE": 6, "PCT_CRIT_DMG": 6, "FLAT_HP": 28, "FLAT_DEF": 22}

# ==============================================================================
# 5. HERITAGE (AFFIXE NOMME D'APRES UN PNJ, HORS IC)
# ==============================================================================
const HERITAGE_UTILITY_BUDGET_MULT: float = 1.15
const HERITAGE_MIN_RARITY_INDEX: int = 2 # Rare, Epique, Legendaire
const HERITAGE_ELIGIBLE_UTILITY_AFFIXES: Array[String] = ["MOVE_SPEED", "CARGO_CAP", "MINE_YIELD", "GATHER_YIELD"]

# ==============================================================================
# 6. ELEMENTS DES MONSTRES PAR ISOLAT ET CHANGEMENT D'ARME
# ==============================================================================
# Isolats 2 a 5 : E(M_elem) = 0,50 + 0,25 x 1,25 + 0,25 x 0,80 = 1,0125 pour une arme elementaire
const ISOLAT_MONSTER_ELEMENT_WEIGHTS: Dictionary = {
	1: {"NEUTRAL": 100, "FROST_BOUND": 0, "EMBER_BOUND": 0},
	2: {"NEUTRAL": 50, "FROST_BOUND": 25, "EMBER_BOUND": 25},
	3: {"NEUTRAL": 50, "FROST_BOUND": 25, "EMBER_BOUND": 25},
	4: {"NEUTRAL": 50, "FROST_BOUND": 25, "EMBER_BOUND": 25},
	5: {"NEUTRAL": 50, "FROST_BOUND": 25, "EMBER_BOUND": 25}
}

const ALLOW_WEAPON_SWAP_IN_COMBAT: bool = false
const ALLOW_WEAPON_SWAP_IN_TRANSIT: bool = false
const ALLOW_WEAPON_SWAP_AT_BRAZIER: bool = true

# ==============================================================================
# 7. REMONTAGE DE PIECE (DISTINCT DE LA GREFFE D'AFFIXE DU VOLET A)
# ==============================================================================
# Garde ou Pommeau seulement. L'arme receveuse garde ses affixes et son budget. Or detruit (puits).
const PART_SWAP_ALLOWED_SLOTS: Array[int] = [WeaponPartSlot.PART_GUARD, WeaponPartSlot.PART_POMMEL]
const PART_SWAP_BASE_GOLD_COST: int = 24 # x M_isolat
const PART_SWAP_GOLD_IS_PURE_SINK: bool = true
const PART_SWAP_ORE_COST: int = 2
const PART_SWAP_CENDRE_COST: int = 0
const PART_SWAP_RANK5_COST_MULT: float = 0.50

# ==============================================================================
# 8. CONTRATS D'ECOLE (SANS PITY NI MORAL)
# ==============================================================================
const CONTRACT_PTS_PER_CRAFT: int = 10
const CONTRACT_PTS_PER_SALVAGE: int = 5
const CONTRACT_PTS_PER_SHOP_SALE: int = 5
const CONTRACT_RANK_THRESHOLDS: Array[int] = [100, 300, 700, 1300, 2200]
const CONTRACT_RANK_REWARDS: Dictionary = {
	1: "UNLOCK_SCHOOL_HALLMARK",
	2: "UNLOCK_SHOP_ARCHITECTURE",
	3: "UNLOCK_MASTER_WEAPON_PATINA",
	4: "UNLOCK_HEARTH_TROPHY_AND_TITLE",
	5: "UNLOCK_PART_SWAP_DISCOUNT_50"
}
const NPC_FAVORITE_SCHOOL_MORAL_BONUS: int = 0

# ==============================================================================
# 9. FONCTIONS O(1), CONSTANTES LUES DANS BalanceA (SANS floor)
# ==============================================================================
const RARITY_KEYS: Array[String] = ["COMMON", "GOOD", "RARE", "EPIC", "LEGENDARY"]

static func get_piece_budget(ilvl: int, rarity_index: int) -> float:
	return (_BalanceA.LOOT_BUDGET_BASE + _BalanceA.LOOT_BUDGET_PER_ILVL * (ilvl - 1)) * _BalanceA.RARITY_BUDGET_MULT[RARITY_KEYS[rarity_index]]

# S(ilvl) = B(ilvl, Commun) / B(1, Commun)
static func get_level_scale_s(ilvl: int) -> float:
	return get_piece_budget(ilvl, 0) / get_piece_budget(1, 0)

static func get_affix_point_cost(affix_id: String, units: float, ilvl: int) -> float:
	var def: Dictionary = AFFIX_DEFS[affix_id]
	var cost: float = def["base_cost"]
	if def["scales_with_s"]:
		cost *= get_level_scale_s(ilvl)
	return units * cost

static func is_weapon_full_school_set(part_schools: Array[int]) -> bool:
	return part_schools.size() == 3 and part_schools[0] != SchoolId.NONE and part_schools[1] == part_schools[0] and part_schools[2] == part_schools[0]

static func compute_weapon_atk(ilvl: int, rarity_index: int, part_schools: Array[int]) -> float:
	var atk: float = (_BalanceA.WEAPON_BASE_ATK_START + _BalanceA.WEAPON_BASE_ATK_PER_ILVL * (ilvl - 1)) * _BalanceA.WEAPON_RARITY_ATK_MULT[RARITY_KEYS[rarity_index]]
	return atk * (1.0 + SCHOOL_SET_3_WEAPON_ATK_BONUS) if is_weapon_full_school_set(part_schools) else atk

static func get_max_affix_budget_share(rarity_index: int) -> float:
	return MAX_AFFIX_BUDGET_SHARE_BY_COUNT[_BalanceA.RARITY_AFFIX_COUNT[RARITY_KEYS[rarity_index]]]

static func compute_part_swap_gold_cost(isolat_index: int, contract_rank: int) -> int:
	var mult: float = PART_SWAP_RANK5_COST_MULT if contract_rank >= 5 else 1.0
	return roundi(PART_SWAP_BASE_GOLD_COST * _BalanceA.ISOLAT_XP_MULTIPLIERS[isolat_index] * mult)
