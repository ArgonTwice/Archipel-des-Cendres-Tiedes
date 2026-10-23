extends Node2D
# PLACEHOLDER : grille de 16 px pour tester le zoom plié / déplié. À supprimer quand le village arrive.

const CELL: int = 16
const HALF_CELLS: int = 40

func _draw() -> void:
	var edge: float = CELL * HALF_CELLS
	for i in range(-HALF_CELLS, HALF_CELLS + 1):
		var c: Color = Color(1.0, 0.55, 0.2, 0.6) if i == 0 else Color(1.0, 1.0, 1.0, 0.2)
		draw_line(Vector2(i * CELL, -edge), Vector2(i * CELL, edge), c)
		draw_line(Vector2(-edge, i * CELL), Vector2(edge, i * CELL), c)
