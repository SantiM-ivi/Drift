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
var _enemigos_registrados: Array = []
const PANTALLA_VICTORIA: PackedScene = preload("res://Stages/UI/PantallaVictoria.tscn")

# ─── AUDIO ─────────────────────────────────────────────────────────────────────
@onready var tic_tac: AudioStreamPlayer = $TicTac
const DURACION_FADE_OUT: float = 1.0

# ─── REFS ─────────────────────────────────────────────────────────────────────
var _player: RigidBody3D = null

func _ready() -> void:
	add_to_group("MissionManager")
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("Player")
	if not _player:
		push_error("[MissionManager] No se encontró el jugador")
		return

	_iniciar_mision_jefe()
	_iniciar_mision_kills()
	todas_completadas.connect(_on_todas_completadas_victoria)



func _process(delta: float) -> void:
	if _jugador_tiene_llave and not _llave_completada:
		_tiempo_retencion += delta
		if _tiempo_retencion >= tiempo_retencion_requerido:
			_completar_mision_llave()


# ─── MISIÓN LLAVE ─────────────────────────────────────────────────────────────

func _configurar_portador_llave(enemigo: AutoEnemigo) -> void:
	_portador_llave = enemigo
	_aplicar_color_llave(_portador_llave, true)
	await get_tree().process_frame
	if _portador_llave.stats:
		_portador_llave.stats.health_depleted.connect(_on_portador_muerto)
	print("[MissionManager] Portador configurado: ", _portador_llave.name)

func _on_portador_muerto() -> void:
	if _llave_completada or _jugador_tiene_llave:
		return
	print("[MissionManager] Llave obtenida — retené ", tiempo_retencion_requerido, " segundos")
	_jugador_tiene_llave = true
	_activar_modo_caza()
	_iniciar_musica_tension()

func _completar_mision_llave() -> void:
	_llave_completada = true
	print("[MissionManager] Misión LLAVE completada")
	_detener_musica_tension()
	emit_signal("mision_completada", "LLAVE")
	_verificar_todas()

func _activar_modo_caza() -> void:
	var todos = get_tree().get_nodes_in_group("Enemigo") + get_tree().get_nodes_in_group("Boss")
	for enemigo in todos:
		if is_instance_valid(enemigo) and enemigo.has_method("activar_modo_caza"):
			enemigo.activar_modo_caza()
	print("[MissionManager] Todos los enemigos en modo caza")

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


# ─── AUDIO — TENSIÓN LLAVE ─────────────────────────────────────────────────────

func _iniciar_musica_tension() -> void:
	if not tic_tac:
		return
	tic_tac.volume_db = 0.0
	tic_tac.play()

func _detener_musica_tension() -> void:
	if not tic_tac or not tic_tac.playing:
		return
	var tween = create_tween()
	tween.tween_property(tic_tac, "volume_db", -40.0, DURACION_FADE_OUT)
	tween.tween_callback(tic_tac.stop)
	tween.tween_callback(func(): tic_tac.volume_db = 0.0)


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
	print("[MissionManager] Misión JEFE completada")
	emit_signal("mision_completada", "JEFE")
	_verificar_todas()


# ─── MISIÓN KILLS ─────────────────────────────────────────────────────────────

func _iniciar_mision_kills() -> void:
	await get_tree().process_frame
	for enemigo in get_tree().get_nodes_in_group("Enemigo"):
		_registrar_enemigo_kill(enemigo)
	print("[MissionManager] Misión kills iniciada — objetivo: ", enemigos_choque_requeridos)

func _registrar_enemigo_kill(enemigo: Node) -> void:
	if enemigo in _enemigos_registrados:
		return
	if not enemigo.has_signal("enemigo_muerto"):
		return
	enemigo.enemigo_muerto.connect(_on_enemigo_muerto)
	_enemigos_registrados.append(enemigo)

func _on_enemigo_muerto(_enemigo: AutoEnemigo) -> void:
	if _choques_completados:
		return
	_enemigos_chocados += 1
	print("[MissionManager] Kills: ", _enemigos_chocados, "/", enemigos_choque_requeridos)
	if _enemigos_chocados >= enemigos_choque_requeridos:
		_choques_completados = true
		print("[MissionManager] Misión KILLS completada")
		emit_signal("mision_completada", "KILLS")
		_verificar_todas()


# ─── FIN DE NIVEL ─────────────────────────────────────────────────────────────

func _verificar_todas() -> void:
	# Cuando jefe Y kills completos, spawnear el portador de la llave
	if _jefe_completado and _choques_completados and not _portador_llave and not _llave_completada:
		var spawner = get_tree().get_first_node_in_group("EnemySpawner")
		if spawner:
			spawner.spawnear_portador()
		else:
			push_error("[MissionManager] No se encontró EnemySpawner")

	if _llave_completada and _jefe_completado and _choques_completados:
		print("[MissionManager] Todas las misiones completadas")
		emit_signal("todas_completadas")


# ─── UTILS ────────────────────────────────────────────────────────────────────

func get_progreso_choques() -> String:
	return "%d/%d" % [_enemigos_chocados, enemigos_choque_requeridos]

func get_tiempo_llave() -> String:
	return "%.1f/%.1f" % [_tiempo_retencion, tiempo_retencion_requerido]

func jugador_tiene_llave() -> bool:
	return _jugador_tiene_llave

func _on_todas_completadas_victoria() -> void:
	var pantalla = PANTALLA_VICTORIA.instantiate()
	get_tree().root.add_child(pantalla)
