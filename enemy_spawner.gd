class_name EnemySpawner
extends Node3D

@export var enemigo_scene: PackedScene
@export var max_enemigos: int = 10
var _enemigos_activos: int = 0
@onready var timer: Timer = $Timer
@onready var puntos_spawn: Array[Node3D] = [
	$RayCastNorte,
	$RayCastSur,
	$RayCastEste,
	$RayCastOeste
]

var _mission_manager: Node = null
var _portador_spawneado: bool = false

func _ready() -> void:
	print("[EnemySpawner] _ready ejecutado")
	add_to_group("EnemySpawner")
	
	# Conectar señal del timer ANTES del await
	timer.timeout.connect(_intentar_spawn)
	
	await get_tree().process_frame
	print("[EnemySpawner] después del await")
	_mission_manager = get_tree().get_first_node_in_group("MissionManager")
	if not _mission_manager:
		push_error("[EnemySpawner] No se encontró MissionManager")
		return
	_mission_manager.todas_completadas.connect(_on_todas_completadas)
	print("[EnemySpawner] _ready completo")
# ── Spawn normal ──────────────────────────────────────────────────
func _intentar_spawn() -> void:
	print("[EnemySpawner] _intentar_spawn — activos: ", _enemigos_activos)
	if _enemigos_activos >= max_enemigos:
		return
	var punto = _get_punto_libre()
	if not punto:
		return
	_spawnear(punto, false)



# ── Spawn portador (llamado desde MissionManager) ─────────────────
func spawnear_portador() -> void:
	if _portador_spawneado:
		return
	_portador_spawneado = true
	var punto = _get_punto_libre()
	if not punto:
		punto = puntos_spawn[0]  # forzar norte si no hay libre
	_spawnear(punto, true)


func _spawnear(punto: RayCast3D, es_portador: bool) -> void:
	if not enemigo_scene:
		push_error("[EnemySpawner] Asigná enemigo_scene en el inspector")
		return
	var enemigo = enemigo_scene.instantiate()
	if enemigo.stats:
		enemigo.stats = enemigo.stats.duplicate()
	get_tree().current_scene.add_child(enemigo)
	enemigo.global_position = punto.global_position
	_enemigos_activos += 1

	# Descontar cuando muera
	enemigo.enemigo_muerto.connect(func(_e): _enemigos_activos -= 1)

	await get_tree().process_frame
	_mission_manager._registrar_enemigo_kill(enemigo)
	if es_portador:
		_mission_manager._configurar_portador_llave(enemigo)
		print("[EnemySpawner] 🗝️ Portador spawneado")
	else:
		print("[EnemySpawner] Enemigo spawneado — activos: ", _enemigos_activos)

func _get_punto_libre() -> RayCast3D:
	var validos = puntos_spawn.filter(func(rc): return rc.is_colliding())
	if validos.is_empty():
		return null
	return validos[randi() % validos.size()]

func _on_todas_completadas() -> void:
	timer.stop()
