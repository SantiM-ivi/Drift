class_name EnemySpawner
extends Node3D
@export var enemigo_scene: PackedScene
@export var enemigo_scene_2: PackedScene
@export var enemigo_scene_3: PackedScene
@export var jefe_scene: PackedScene
@export var max_enemigos: int = 10
var _enemigos_activos: int = 0
@onready var timer: Timer = $Timer
@onready var puntos_spawn: Array[Node3D] = [
	$RayCastNorte,
	$RayCastSur,
	$RayCastEste,
	$RayCastOeste
]
var _wave_manager: Node = null
var _objetivo_oleada: int = 0
var _spawneados_oleada: int = 0
func _ready() -> void:
	print("[EnemySpawner] _ready ejecutado")
	add_to_group("EnemySpawner")

	# Conectar señal del timer ANTES del await
	timer.timeout.connect(_intentar_spawn)

	await get_tree().process_frame
	print("[EnemySpawner] después del await")
	_wave_manager = get_tree().get_first_node_in_group("WaveManager")
	if not _wave_manager:
		push_error("[EnemySpawner] No se encontró WaveManager")
		return
	_wave_manager.jugador_derrotado.connect(_on_jugador_derrotado)
	print("[EnemySpawner] _ready completo")
# ── Spawn de oleada (llamado desde WaveManager) ─────────────────────
func iniciar_oleada(cantidad: int) -> void:
	_objetivo_oleada = cantidad
	_spawneados_oleada = 0
	timer.start()
# ── Spawn normal ──────────────────────────────────────────────────
func _intentar_spawn() -> void:
	print("[EnemySpawner] _intentar_spawn — activos: ", _enemigos_activos)
	if _spawneados_oleada >= _objetivo_oleada:
		timer.stop()
		return
	if _enemigos_activos >= max_enemigos:
		return
	var punto = _get_punto_libre()
	if not punto:
		return
	_spawnear(punto, false)
# ── Spawn jefe (llamado desde WaveManager en oleada de boss) ───────
func spawnear_jefe() -> void:
	var punto = puntos_spawn[0]
	_spawnear(punto, true)
func _spawnear(punto: RayCast3D, es_jefe: bool) -> void:
	var scene = jefe_scene if es_jefe else _elegir_enemigo_comun()
	if not scene:
		push_error("[EnemySpawner] Asigná enemigo_scene/jefe_scene en el inspector")
		return
	var enemigo = scene.instantiate()
	if enemigo.stats:
		enemigo.stats = enemigo.stats.duplicate()
	get_tree().current_scene.add_child(enemigo)

	# Usar el punto de colisión, no la posición del RayCast
	if punto.is_colliding():
		enemigo.global_position = punto.get_collision_point()
	else:
		enemigo.global_position = punto.global_position  # fallback

	_enemigos_activos += 1
	_spawneados_oleada += 1
	# Descontar cuando muera
	enemigo.enemigo_muerto.connect(func(_e): _enemigos_activos -= 1)
	await get_tree().process_frame
	if es_jefe:
		_wave_manager._registrar_jefe(enemigo)
		print("[EnemySpawner] 👹 Jefe spawneado")
	else:
		_wave_manager._registrar_enemigo_oleada(enemigo)
		print("[EnemySpawner] Enemigo spawneado — activos: ", _enemigos_activos)
func _elegir_enemigo_comun() -> PackedScene:
	var disponibles = [enemigo_scene, enemigo_scene_2, enemigo_scene_3].filter(func(s): return s != null)
	if disponibles.is_empty():
		return null
	return disponibles[randi() % disponibles.size()]
func _get_punto_libre() -> RayCast3D:
	var validos = puntos_spawn.filter(func(rc): return rc.is_colliding())
	if validos.is_empty():
		return null
	return validos[randi() % validos.size()]
func _on_jugador_derrotado() -> void:
	timer.stop()
