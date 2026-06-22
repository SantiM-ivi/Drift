# ── Agregar en MissionManager.gd ──────────────────────────────

const PANTALLA_VICTORIA: PackedScene = preload("res://UI/PantallaVictoria.tscn")

# En _ready(), conectar la señal que ya existe:
#     todas_completadas.connect(_on_todas_completadas_victoria)

func _on_todas_completadas_victoria() -> void:
	var pantalla = PANTALLA_VICTORIA.instantiate()
	get_tree().root.add_child(pantalla)
