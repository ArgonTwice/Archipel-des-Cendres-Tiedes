extends PanelContainer
# Écran Crédits : attribution de Silkscreen et texte complet de la licence OFL jointe.

const OFL_PATH: String = "res://assets/fonts/silkscreen/OFL.txt" # fichier non-ressource : filtre d'export Android

func _ready() -> void:
	$Margin/VBox/Scroll/Text.text = FileAccess.get_file_as_string(OFL_PATH)
	$Margin/VBox/Close.pressed.connect(hide)
