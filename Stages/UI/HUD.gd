extends CanvasLayer

# --- Nodos ---
@onready var health_bar: ProgressBar = $BottomLeft/Content/HealthBar
@onready var health_label: Label     = $BottomLeft/Content/HealthLabel
@onready var speed_label: Label      = $BottomRight/Content/SpeedLabel
@onready var mission_label: Label    = $TopLeft/Content/MissionTitle

var max_health: float = 100.0
var _mission_manager: Node = null

func _ready() -> void:
	set_health(100.0)
	set_speed(0)

	# Conectar con MissionManager
	await get_tree().process_frame
	_mission_manager = get_tree().get_first_node_in_group("MissionManager")
	if _mission_manager:
		_mission_manager.mision_completada.connect(_on_mision_completada)
		_mission_manager.todas_completadas.connect(_on_todas_completadas)
		_actualizar_texto_misiones()
	else:
		push_error("[HUD] No se encontró MissionManager")
		set_mission("Destruye el convoy")

func _process(_delta: float) -> void:
	if _mission_manager:
		_actualizar_texto_misiones()

# ── API pública ──────────────────────────────────────
func set_health(value: float) -> void:
	health_bar.value = clamp(value, 0.0, max_health)
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

# ── Misiones ─────────────────────────────────────────
func _actualizar_texto_misiones() -> void:
	var mm = _mission_manager
	var llave_ok   = mm._llave_completada
	var jefe_ok    = mm._jefe_completado
	var kills_ok   = mm._choques_completados

	var lineas: Array[String] = []

	# Misión Jefe
	if not jefe_ok:
		lineas.append("💀 JEFE — elimínalo")
	else:
		lineas.append("✅ JEFE completado")

	# Misión Kills
	if not kills_ok:
		lineas.append("🚗 KILLS — destruidos: " + mm.get_progreso_choques())
	else:
		lineas.append("✅ KILLS completados")

	# Misión Llave — solo aparece si las otras dos están completas
	if jefe_ok and kills_ok:
		if not llave_ok:
			if mm.jugador_tiene_llave():
				lineas.append("🗝️ LLAVE — retener: " + mm.get_tiempo_llave() + "s")
			else:
				lineas.append("🗝️ LLAVE — elimina al portador")
		else:
			lineas.append("✅ LLAVE completada")

	mission_label.text = "\n".join(lineas)

func _on_mision_completada(id: String) -> void:
	_actualizar_texto_misiones()
	# Flash opcional para feedback
	var tween = create_tween()
	tween.tween_property(mission_label, "modulate", Color.GREEN, 0.2)
	tween.tween_property(mission_label, "modulate", Color.WHITE, 0.5)

func _on_todas_completadas() -> void:
	mission_label.text = "🏁 ¡TODAS COMPLETADAS!\nVolviendo al menú..."
	mission_label.modulate = Color.GOLD

# ── Interno ──────────────────────────────────────────
func _flash(node: CanvasItem) -> void:
	var tween = create_tween().set_loops(3)
	tween.tween_property(node, "modulate:a", 0.2, 0.12)
	tween.tween_property(node, "modulate:a", 1.0, 0.12)
