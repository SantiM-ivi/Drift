extends CanvasLayer

# --- Nodos ---
@onready var health_bar: ProgressBar = $BottomLeft/Content/HealthBar
@onready var health_label: Label     = $BottomLeft/Content/HealthLabel
@onready var speed_label: Label      = $BottomRight/Content/SpeedLabel
@onready var mission_label: Label    = $TopLeft/Content/MissionTitle

var max_health: float = 100.0
var _mission_manager: Node = null

func _ready() -> void:
	health_bar.max_value = max_health
	set_health(100)
	set_speed(0)
	await get_tree().process_frame
	_mission_manager = get_tree().get_first_node_in_group("MissionManager")
	if _mission_manager:
		_mission_manager.mision_completada.connect(_on_mision_completada)
		_mission_manager.todas_completadas.connect(_on_todas_completadas)
		_actualizar_texto_misiones()
	else:
		push_error("[HUD] No se encontro MissionManager")
		set_mission("Destruye el convoy")

func _process(_delta: float) -> void:
	if _mission_manager:
		_actualizar_texto_misiones()

# -- API publica ----------------------------------------------------------

func set_max_health(value: int) -> void:
	max_health = float(value)
	health_bar.max_value = max_health

func set_health(value: int) -> void:
	health_bar.value = clamp(float(value), 0.0, max_health)
	var ratio = health_bar.value / max_health
	if ratio > 0.5:
		health_bar.modulate = Color(0.2, 1.0, 0.2)
	elif ratio > 0.25:
		health_bar.modulate = Color(1.0, 0.7, 0.0)
	else:
		health_bar.modulate = Color(1.0, 0.15, 0.15)
		_flash(health_bar)

func set_speed(kmh: int) -> void:
	speed_label.text = str(abs(kmh))

func set_mission(title: String) -> void:
	mission_label.text = title.to_upper()

# -- Misiones -------------------------------------------------------------

func _actualizar_texto_misiones() -> void:
	var mm       = _mission_manager
	var llave_ok = mm._llave_completada
	var jefe_ok  = mm._jefe_completado
	var kills_ok = mm._choques_completados
	var lineas: Array[String] = []

	if not jefe_ok:
		lineas.append("JEFE - eliminalo")

	if not kills_ok:
		lineas.append("KILLS - destruidos: " + mm.get_progreso_choques())

	if jefe_ok and kills_ok:
		if not llave_ok:
			if mm.jugador_tiene_llave():
				lineas.append("LLAVE - retener: " + mm.get_tiempo_llave() + "s")
			else:
				lineas.append("LLAVE - elimina al portador")

	mission_label.text = "\n".join(lineas)

func _on_mision_completada(_id: String) -> void:
	_actualizar_texto_misiones()
	var tween = create_tween()
	tween.tween_property(mission_label, "modulate", Color.GREEN, 0.2)
	tween.tween_property(mission_label, "modulate", Color.WHITE, 0.5)

func _on_todas_completadas() -> void:
	mission_label.text = "TODAS COMPLETADAS\nVolviendo al menu..."
	mission_label.modulate = Color.GOLD

# -- Interno --------------------------------------------------------------

func _flash(node: CanvasItem) -> void:
	var tween = create_tween().set_loops(3)
	tween.tween_property(node, "modulate:a", 0.2, 0.12)
	tween.tween_property(node, "modulate:a", 1.0, 0.12)
