extends RefCounted
# Charte d'interface (jalon 20, docs/Charte-UI.md) : couleurs par rôle et icônes, déclarées ici et nulle part ailleurs.
# Statiques pures. Constantes visuelles techniques ; aucune valeur de jeu (les couleurs d'École sont lues dans BalanceC).

const BC = preload("res://balance/balance_c.gd")

# Couleurs par rôle (Charte §1, palette Okabe-Ito)
const TEXT: Color = Color(1, 1, 1) # texte courant, état neutre
const MUTED: Color = Color(1, 1, 1, 0.6) # raisons de grisé, aides, résumés ; PROPOSÉ, à valider (jalon 16 bis)
const TITLE: Color = Color("#56B4E9") # intertitres ; validé sur Fold (jalon 19)
const NEXT: Color = Color("#009E73") # attente, « Demain : … » ; validé sur Fold (jalon 19)
const GOOD: Color = Color("#009E73") # meilleure pièce, Moral haut, rattrapage ; validé sur Fold (jalon 19 bis)
const BAD: Color = Color("#D55E00") # moins bonne pièce, grève ; validé sur Fold (jalon 19 bis)
const ALERT: Color = Color("#E69F00") # Moral bas, manque proche ; validé sur Fold (jalon 19 bis)
const SUPERIOR: Color = Color("#E69F00") # Qualité Supérieure ; PROPOSÉ, à valider (jalon 16 bis)
const DETAIL_BG: Color = Color(1, 1, 1, 0.06) # fond de fiche ; validé sur Fold (jalon 19)
const DETAIL_MARGIN_PX: int = 4 # validé sur Fold (jalon 19)

const MORAL_COLORS: Dictionary = {"STRIKE": BAD, "LOW": ALERT, "NORMAL": TEXT, "HIGH": GOOD} # validé sur Fold (jalon 19 bis)
const VERDICT_COLORS: Dictionary = {1: GOOD, -1: BAD, 0: TEXT} # PROPOSÉ, à valider (jalon 16 bis)
const DIFF_COLORS: Dictionary = {1: GOOD, -1: BAD, 0: TEXT} # écart stat par stat de la carte ; PROPOSÉ, à valider (jalon 20 bis)
const ROLES: Dictionary = {"TEXT": TEXT, "MUTED": MUTED, "GOOD": GOOD, "BAD": BAD, "ALERT": ALERT} # rôle nommé -> couleur (jalons 20 ter, 21)
const HIGHLIGHT_FILL_ALPHA: float = 0.25 # surbrillance du bâtiment visé ; technique, PROPOSÉ, à valider (jalon 21)
const HIGHLIGHT_LINE_PX: float = 2.0 # contour, en pixels monde ; technique, PROPOSÉ, à valider (jalon 21)
const HIGHLIGHT_TEXT_OUTLINE: Color = Color(0, 0, 0) # contour de l'étiquette, lisible sur l'herbe et la brume ; PROPOSÉ (jalon 21)

# Planches
const TD = preload("res://assets/tiles/kenney_tiny_dungeon/tilemap_packed.png")
const TT = preload("res://assets/tiles/kenney_tiny_town/tilemap_packed.png")
const COIN = preload("res://assets/icons/hud/coin_05d.png")
const CAMPFIRE = preload("res://assets/icons/hud/campfire_16x16.png")
const GEM = preload("res://assets/icons/hud/item_gem_quartz.png")
const ORES = preload("res://assets/icons/hud/Stones_ores_gems_without_grass.png")
const FULL: Rect2 = Rect2(0, 0, 16, 16)

# Icônes (Charte §3) : notion -> [planche, région en taille native]. Tuiles Kenney : 12 colonnes (tile_region).
const ICONS: Dictionary = {
	# Bandeau (jalon 17), clés = noms des couples du HUD ; tuiles d'onglet validées sur Fold (jalon 17)
	"or": [COIN, Rect2(1, 1, 14, 15)],
	"cendre": [CAMPFIRE, Rect2(2, 0, 12, 16)], # image 0, animée dans le bandeau (jalon 17 bis)
	"eclats": [GEM, Rect2(1, 1, 14, 14)],
	"ECLAT": [GEM, FULL], # même fichier en 16 px : tête de carte alignée sur les autres (Sacoche, jalon 20)
	"minerai": [ORES, Rect2(0, 22, 15, 10)],
	"TAB_PERSO": [TD, Rect2(64, 144, 16, 16)], # TD 112
	"TAB_SACOCHE": [TT, Rect2(176, 128, 16, 16)], # TT 107
	"TAB_FORGE": [TD, Rect2(32, 96, 16, 16)], # TD 74
	"TAB_PNJ": [TD, Rect2(48, 128, 16, 16)], # TD 99
	"TAB_VILLAGE": [TT, Rect2(128, 128, 16, 16)], # TT 104
	"TAB_OPTIONS": [TT, Rect2(176, 96, 16, 16)], # TT 83
	# Village (jalon 19 bis) : image 0 du feu élargie à 16 px ; tuiles roche, tonneau, enclume de village.json
	"ATRE": [CAMPFIRE, FULL],
	"MAT": [TD, Rect2(0, 32, 16, 16)], # TD 24
	"TAVERN": [TD, Rect2(160, 96, 16, 16)], # TD 82
	"FORGE": [TD, Rect2(32, 96, 16, 16)], # TD 74
	# Perso (jalon 20) : vocations et emplacements ; DB32 = 16x16 RPG Items, CC0
	"COMBATTANT": [TD, Rect2(64, 144, 16, 16)], # TD 112, le héros
	"MINEUR": [preload("res://assets/icons/items/pickaxe_iron.png"), FULL],
	"FORGERON": [TD, Rect2(32, 96, 16, 16)], # TD 74, l'enclume
	"SLOT_0": [preload("res://assets/icons/items/sword_iron.png"), FULL],
	"SLOT_1": [preload("res://assets/icons/items/armor_helmet_iron.png"), FULL],
	"SLOT_2": [preload("res://assets/icons/items/armor_chest_iron.png"), FULL],
	"SLOT_3": [preload("res://assets/icons/items/armor_boots_iron.png"), FULL],
	"CREDITS": [TT, Rect2(176, 96, 16, 16)], # TT 83, même tuile que l'onglet Options (jalon 20 bis)
	"ELITE": [TD, Rect2(32, 144, 16, 16)]} # TD 110, tuile « elite » de village.json (toast d'éveil, jalon 20 ter)
const HUD_KEYS: Array[String] = ["or", "cendre", "eclats", "minerai"]

static func atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var t: AtlasTexture = AtlasTexture.new()
	t.atlas = sheet
	t.region = region
	return t

static func icon(notion: String) -> AtlasTexture:
	return atlas(ICONS[notion][0], ICONS[notion][1])

# Tuile entière d'une planche Kenney à 12 colonnes.
static func tile_region(i: int) -> Rect2:
	return Rect2((i % 12) * 16, (i / 12) * 16, 16, 16)

# Couleur d'École (Volet C) : donnée de jeu lue dans BalanceC, jamais recopiée.
static func school_color(id: int) -> Color:
	return Color(BC.SCHOOL_DATA[id]["color_hex"])
