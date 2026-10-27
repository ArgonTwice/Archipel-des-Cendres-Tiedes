class_name BalanceF
extends RefCounted

const _BalanceA = preload("res://balance/balance_a.gd")
const _BalanceB = preload("res://balance/balance_b.gd")
const _BalanceC = preload("res://balance/balance_c.gd")

# Volet F valide le 26/10/2026 (messages Claude <-> Argon n°34 et n°35, audits par script).
# Eclats, Forge et equipement de la tranche verticale. Constantes nouvelles uniquement :
# aucune valeur des Volets A a E n'est dupliquee ni modifiee.

# ==============================================================================
# 1. CYCLE D'UN ECLAT (PURIFICATION) ET CRAFT DE FORGE
# ==============================================================================
# Purification d'Eclat : 1 Eclat -> 1 piece (0 minerai, 0 Cendre Vive, 0 XP Forgeron, 0 % Superieur)
const SHARD_PURIFY_COST_SHARDS: int = 1
const SHARD_PURIFY_COST_MINERALS: int = 0
const SHARD_PURIFY_COST_CENDRE: int = 0
const SHARD_PURIFY_FORGE_XP: int = 0
const SHARD_PURIFY_SUPERIOR_CHANCE: float = 0.0
const SHARD_PURIFY_BRAZIER_MAX_PER_RUN: int = 2 # SOCLE A3 : purifier 1-2 Eclats au Bivouac

# Craft a la Forge du village : consomme BalanceB.CRAFT_MINERAL_COST_EQUIPMENT (4) minerais, 0 Eclat
const CRAFT_REQUIRES_SHARD: bool = false
const CRAFT_ALLOW_SLOT_CHOICE: bool = true
const CRAFT_ALLOW_NO_CENDRE_EQUIPMENT: bool = true
const CRAFT_NO_CENDRE_SUPERIOR_CHANCE: float = 0.0
const CRAFT_NO_CENDRE_MAX_RARITY_INDEX: int = 0 # Toujours COMMON sans Cendre Vive
# Ecole d'une arme forgee en tranche (sans Contrats d'Ecole) : Lame VERTICAL_SLICE_DROP_WEIGHTS, Garde/Pommeau DROP_PART_SAME_SCHOOL_PROB (n°35)
const CRAFT_WEAPON_USES_DROP_SCHOOL_RULES: bool = true

# ==============================================================================
# 2. EMPLACEMENTS, TYPES D'ARME EN TRANCHE, RARETES ET ILVL
# ==============================================================================
enum EquipmentSlot {
	WEAPON = 0,
	HELMET = 1,
	CHESTPLATE = 2,
	BOOTS = 3
}

# Poids de tirage des 4 emplacements sur un Eclat purifie (somme = 100)
const SLOT_DROP_WEIGHTS: Array[int] = [25, 25, 25, 25]

# Seule l'Epee & Ecu est active dans la tranche verticale
const VERTICAL_SLICE_WEAPON_TYPES: Array[int] = [_BalanceC.WeaponType.SWORD_SHIELD]

# Poids de rarete [COMMON, GOOD, RARE] (somme = 100, plafonne par BalanceC.VERTICAL_SLICE_MAX_RARITY_INDEX = 2)
const SHARD_NORMAL_RARITY_WEIGHTS: Array[int] = [65, 25, 10] # Monstre normal ou noeud de Brume
const SHARD_ELITE_RARITY_WEIGHTS: Array[int] = [40, 40, 20]  # Elite porteur de braise
const CRAFT_WITH_CENDRE_BASE_RARITY_WEIGHTS: Array[int] = [65, 25, 10]
const CRAFT_RARITY_SHIFT_PER_FORGE_LVL: int = 1 # Par niveau > 1 : -2 COMMON, +1 GOOD, +1 RARE
const CRAFT_COMMON_MIN_WEIGHT: int = 20
# Qualite Superieure : ilvl_base clamp dans la plage de l'isolat, puis +SUPERIOR_QUALITY_ILVL_BONUS (jusqu'a ilvl 12 au Nv10) (n°35)
const SUPERIOR_BONUS_EXCEEDS_ISOLAT_ILVL_CAP: bool = true

# ==============================================================================
# 3. TIRAGE DES AFFIXES, PARTAGE DU BUDGET B ET ARMURES
# ==============================================================================
const VERTICAL_SLICE_ALLOW_UTILITY_AFFIXES: bool = false
const AFFIX_DRAW_WITHOUT_REPLACEMENT: bool = true
const AFFIX_MIN_BUDGET_SHARE: float = 0.20
const AFFIX_DISPLAY_DECIMALS: int = 1
# Commun (K = 1) : tirage restreint aux affixes FLAT_*, poids d'origine renormalises, 100 % du budget B utilise (n°35)
const COMMON_SINGLE_AFFIX_FLAT_ONLY: bool = true
const COMMON_ALLOWED_AFFIXES: Array[String] = ["FLAT_ATK", "FLAT_HP", "FLAT_DEF"]

# Les armures n'ont aucune stat de base hors affixes
const ARMOR_HAS_INNATE_BASE_STATS: bool = false

# Arme de depart : Epee & Ecu, Commun, ilvl 1, 3 pieces Enclume (FOYER), 0 affixe
const STARTER_WEAPON_TYPE: int = _BalanceC.WeaponType.SWORD_SHIELD
const STARTER_WEAPON_RARITY_INDEX: int = 0
const STARTER_WEAPON_ILVL: int = 1
const STARTER_WEAPON_SCHOOL: int = _BalanceC.SchoolId.FOYER
const STARTER_WEAPON_AFFIX_COUNT: int = 0

# ==============================================================================
# 4. MINERAIS, CARGAISON, MORT ET REGLES DE CUMUL (SORTIES DU JOUR & REPOS)
# ==============================================================================
const MIST_NODE_MINERAL_ITEM_ID: String = "MINERAI_FER_BRAISE"
const MIST_NODE_MINERAL_YIELD: int = 2 # Volet A : 2 minerais par noeud de Brume

# Mort / evacuation d'urgence : seule la cargaison reste au sol ; Cendre et Eclats sont gardes
const KEEP_CENDRE_ON_DEATH: bool = true
const KEEP_SHARDS_ON_DEATH: bool = true
const MAX_DROPPED_CARGO_CRATES: int = 1
const DROPPED_CARGO_MERGE_ON_DEATH: bool = true
const RETURN_MINERALS_TO_PLAYER_CHEST: bool = true
# Caisse egaree, cargaison pleine : on ramasse jusqu'au plafond, le reste reste dans la caisse (n°35)
const PARTIAL_CRATE_LOOT_KEEP_REMAINDER: bool = true

# Changement d'armure : memes regles que les armes (village et Brasero seulement) (n°35)
const ALLOW_ARMOR_SWAP_IN_COMBAT: bool = _BalanceC.ALLOW_WEAPON_SWAP_IN_COMBAT
const ALLOW_ARMOR_SWAP_IN_TRANSIT: bool = _BalanceC.ALLOW_WEAPON_SWAP_IN_TRANSIT
const ALLOW_ARMOR_SWAP_AT_BRAZIER: bool = _BalanceC.ALLOW_WEAPON_SWAP_AT_BRAZIER

# Saturation du segment (80) : mesure la Cendre nominale (2n + 8m <= 80) avant DAILY_RUN_XP_MULT
const SATURATION_USES_NOMINAL_CENDRE: bool = true
# BalanceA.DAILY_RUN_XP_MULT : XP de kills et Cendre Vive seulement ; daily_run_mult = 1.0 pour toute autre action (n°35)
const DAILY_RUN_MULT_KILLS_AND_CENDRE_ONLY: bool = true

# XP de repos : accumule hors session uniquement, ne s'applique pas aux defis de rang
const RESTED_ACCUMULATES_OFFLINE_ONLY: bool = true
const RESTED_APPLIES_TO_RANK_CHALLENGES: bool = false

# ==============================================================================
# 5. FONCTIONS O(1) DU VOLET F
# ==============================================================================
# forgeron_level : clampe a la plage de l'isolat par l'appelant (Volet F §2).
static func get_craft_with_cendre_rarity_weights(forgeron_level: int) -> Array[int]:
	var shift: int = maxi(0, forgeron_level - 1) * CRAFT_RARITY_SHIFT_PER_FORGE_LVL
	var w_common: int = maxi(CRAFT_COMMON_MIN_WEIGHT, CRAFT_WITH_CENDRE_BASE_RARITY_WEIGHTS[0] - 2 * shift)
	var actual_shift: int = (CRAFT_WITH_CENDRE_BASE_RARITY_WEIGHTS[0] - w_common) / 2
	var w_good: int = CRAFT_WITH_CENDRE_BASE_RARITY_WEIGHTS[1] + actual_shift
	var w_rare: int = 100 - w_common - w_good
	return [w_common, w_good, w_rare]

static func compute_cendre_gain_step(nominal_before: int, nominal_gain: int, run_index_today: int) -> int:
	var idx: int = clampi(run_index_today, 0, _BalanceA.DAILY_RUN_XP_MULT.size() - 1)
	var mult: float = _BalanceA.DAILY_RUN_XP_MULT[idx]
	var after: int = nominal_before + nominal_gain
	return floori(float(after) * mult) - floori(float(nominal_before) * mult)

# daily_run_mult : BalanceA.DAILY_RUN_XP_MULT[idx] pour un kill, 1.0 sinon.
static func compute_action_xp_with_catchup_and_rested(base_xp: int, isolat_index: int, daily_run_mult: float, voc_level: int, max_voc_level: int, rested_pool: int) -> Vector2i:
	var m_iso: float = _BalanceA.ISOLAT_XP_MULTIPLIERS[clampi(isolat_index, 0, _BalanceA.ISOLAT_XP_MULTIPLIERS.size() - 1)]
	var xp_act: int = floori(float(base_xp) * m_iso * daily_run_mult)
	var m_catchup: float = _BalanceA.get_action_xp_catchup_mult(voc_level, max_voc_level)
	var xp_after_catchup: int = floori(float(xp_act) * m_catchup)
	var bonus_wanted: int = floori(float(xp_after_catchup) * _BalanceA.RESTED_XP_BONUS_RATE)
	var bonus_rested: int = mini(maxi(0, rested_pool), bonus_wanted)
	return Vector2i(xp_after_catchup + bonus_rested, bonus_rested) # x = xp_final, y = rested_consumed
