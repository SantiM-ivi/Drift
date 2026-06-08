# mission_manager.gd
extends Node

signal mision_completada(id: String)
signal todas_completadas

# ─── ESTADO MISIONES ──────────────────────────────────────────────────────────
var _llave_completada: bool = false
var _jefe_completado: bool = false
var _choques_completados: bool = false

# ─── MISIÓN LLAVE ─────────────────────────────────────────────────────────────
var _portador_llave: AutoEnemigo = null
var _jugador_tiene_llave: bool = false
var _tiempo_retencion: float = 0.0
@export var tiempo_retencion_requerido: float = 30.0

# ─── MISIÓN KILLS ─────────────────────────────────────────────────────────────
var _enemigos_chocados: int = 0
@export var enemigos_choque_requeridos: int = 5

# ─── REFS ─────────────────────────────────────────────────────────────────────
var _player: RigidBody3D = null

func _ready() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("Player")
	if not _player:
		push_error("[MissionManager] No se encontró el jugador")
		return

	_iniciar_mision_llave()
	_iniciar_mision_jefe()
	_iniciar_mision_kills()
	print("[MissionManager] Las 3 misiones iniciadas.")


func _process(delta: float) -> void:
	if _jugador_tiene_llave and not _llave_completada:
		_tiempo_retencion += delta
		if _tiempo_retencion >= tiempo_retencion_requerido:
			_completar_mision_llave()


# ─── MISIÓN LLAVE ─────────────────────────────────────────────────────────────

func _iniciar_mision_llave() -> void:
	var enemigos = get_tree().get_nodes_in_group("Enemigo")
	if enemigos.is_empty():
		push_warning("[MissionManager] No hay enemigos para asignar la llave")
		return

	_portador_llave = enemigos[randi() % enemigos.size()]
	_aplicar_color_llave(_portador_llave, true)
	if _portador_llave.stats:
		_portador_llave.stats.health_depleted.connect(_on_portador_muerto)
	print("[MissionManager] Portador de la llave: ", _portador_llave.name)

func _on_portador_muerto() -> void:
	if _llave_completada or _jugador_tiene_llave:
		return
	print("[MissionManager] 🗝️ Llave obtenida — retené ", tiempo_retencion_requerido, " segundos")
	_jugador_tiene_llave = true
	_activar_modo_caza()

func _activar_modo_caza() -> void:
	var todos = get_tree().get_nodes_in_group("Enemigo") + get_tree().get_nodes_in_group("Boss")
	for enemigo in todos:
		if is_instance_valid(enemigo) and enemigo.has_method("activar_modo_caza"):
			enemigo.activar_modo_caza()
	print("[MissionManager] 🚨 Todos los enemigos en modo caza")

func _completar_mision_llave() -> void:
	_llave_completada = true
	print("[MissionManager] ✅ Misión LLAVE completada")
	emit_signal("mision_completada", "LLAVE")
	_verificar_todas()

func _aplicar_color_llave(enemigo: AutoEnemigo, activar: bool) -> void:
	for hijo in enemigo.get_children():
		if hijo is MeshInstance3D:
			if activar:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color.GOLD
				hijo.material_override = mat
			else:
				hijo.material_override = null
			break


# ─── MISIÓN JEFE ──────────────────────────────────────────────────────────────

func _iniciar_mision_jefe() -> void:
	var jefes = get_tree().get_nodes_in_group("Boss")
	if jefes.is_empty():
		push_warning("[MissionManager] No hay ningún nodo en el grupo 'Boss'")
		return
	for jefe in jefes:
		if not jefe.enemigo_muerto.is_connected(_on_jefe_muerto):
			jefe.enemigo_muerto.connect(_on_jefe_muerto)
	print("[MissionManager] Jefe registrado.")

func _on_jefe_muerto(_enemigo: AutoEnemigo) -> void:
	if _jefe_completado:
		return
	_jefe_completado = true
	print("[MissionManager] ✅ Misión JEFE completada")
	emit_signal("mision_completada", "JEFE")
	_verificar_todas()


# ─── MISIÓN KILLS ─────────────────────────────────────────────────────────────

func _iniciar_mision_kills() -> void:
	for enemigo in get_tree().get_nodes_in_group("Enemigo"):
		if not enemigo.enemigo_muerto.is_connected(_on_enemigo_muerto):
			enemigo.enemigo_muerto.connect(_on_enemigo_muerto)
	print("[MissionManager] Misión kills iniciada — objetivo: ", enemigos_choque_requeridos)

func _on_enemigo_muerto(_enemigo: AutoEnemigo) -> void:
	if _choques_completados:
		return
	_enemigos_chocados += 1
	print("[MissionManager] Kills: ", _enemigos_chocados, "/", enemigos_choque_requeridos)
	if _enemigos_chocados >= enemigos_choque_requeridos:
		_choques_completados = true
		print("[MissionManager] ✅ Misión KILLS completada")
		emit_signal("mision_completada", "KILLS")
		_verificar_todas()


# ─── FIN DE NIVEL ─────────────────────────────────────────────────────────────

func _verificar_todas() -> void:
	if _llave_completada and _jefe_completado and _choques_completados:
		print("[MissionManager] 🏁 ¡Todas las misiones completadas! Volviendo al menú...")
		emit_signal("todas_completadas")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Stages/Menu/MainMenu.tscn")


# ─── UTILS ────────────────────────────────────────────────────────────────────

func get_progreso_choques() -> String:
	return "%d/%d" % [_enemigos_chocados, enemigos_choque_requeridos]

func get_tiempo_llave() -> String:
	return "%.1f/%.1f" % [_tiempo_retencion, tiempo_retencion_requerido]

func jugador_tiene_llave() -> bool:
	return _jugador_tiene_llave
