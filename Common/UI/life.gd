extends ColorRect

@onready var jugador: Node = get_tree().current_scene.get_node("Jugador")

var ancho_maximo: float = 0.0

func _ready() -> void:
	ancho_maximo = size.x  # guardamos el ancho completo como 100%
	
	# Conectar a las stats del jugador
	if jugador and jugador.stats:
		jugador.stats.health_changed.connect(_on_health_changed)
		# Inicializar con la vida actual
		_on_health_changed(jugador.stats.health, jugador.stats.current_max_health)

func _on_health_changed(cur_health: int, max_health: int) -> void:
	var porcentaje = float(cur_health) / float(max_health)
	size.x = ancho_maximo * porcentaje
