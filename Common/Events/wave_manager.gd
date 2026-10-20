extends Node

signal oleada_iniciada(numero: int)
signal oleada_completada(numero: int)
signal jugador_derrotado
signal chatarra_actualizada(total: int)

@export var enemigos_base: int = 3
@export var incremento_por_oleada: int = 2

@export var chatarra_por_oleada: int = 5
@export var chatarra_radio: float = 40.0
@export var chatarra_altura: float = 1.0
@export var chatarra_intentos_max: int = 8
@export var chatarra_raycast_altura: float = 50.0

var _oleada_actual: int = 0
var _enemigos_vivos_oleada: int = 0
var _oleada_cerrada: bool = false

@export var texto_oleada: Label
@export var texto_chatarra: Label
const SONIDO_OLEADA_COMPLETA: AudioStream = preload("res://Assets/Audio/Music/ventacorrecta (1).wav")

@export var oleada_sfx: AudioStreamPlayer
var _chatarra_recolectada: int = 0

const PANTALLA_DERROTA: PackedScene = preload("res://Stages/UI/PantallaDerrota.tscn")

var _player: RigidBody3D = null
var _spawner: Node = null

func _ready() -> void:
	GameStats.reiniciar()
	add_to_group("WaveManager")
	await get_tree().process_frame
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("Player")
	if not _player:
		push_error("[WaveManager] No se encontró el jugador")
		return
	_spawner = get_tree().get_first_node_in_group("EnemySpawner")
	if not _spawner:
		push_error("[WaveManager] No se encontró el EnemySpawner")
		return

	jugador_derrotado.connect(_on_jugador_derrotado)
	_actualizar_texto_chatarra()
	_iniciar_oleada(1)


func _iniciar_oleada(numero: int) -> void:
	_oleada_cerrada = false
	_oleada_actual = numero
	GameStats.oleadas_sobrevividas = numero - 1
	emit_signal("oleada_iniciada", numero)
	print("[WaveManager] Oleada ", numero, " iniciada")

	_mostrar_texto_oleada(numero)

	_curar_jugador()
	_spawnear_chatarra()

	var cantidad = enemigos_base + (numero - 1) * incremento_por_oleada
	_enemigos_vivos_oleada = cantidad
	_spawner.iniciar_oleada(cantidad)


func _mostrar_texto_oleada(numero: int) -> void:
	if not texto_oleada:
		push_warning("[WaveManager] texto_oleada no está asignado (oleada %d). Asigná el Label en el inspector." % numero)
		return

	texto_oleada.text = "Oleada %d" % numero


func _curar_jugador() -> void:
	if not _player.stats:
		return
	var faltante = _player.stats.current_max_health - _player.stats.health
	if faltante <= 0:
		return
	var curacion = faltante / 2
	_player.stats.health += curacion
	print("[WaveManager] Curación de oleada: +", curacion)


func _spawnear_chatarra() -> void:
	for i in chatarra_por_oleada:
		var escena = ItemPool.get_random_chatarra()
		if not escena:
			continue
		var pos = _punto_chatarra_valido()
		if pos == null:
			print("[WaveManager] No se encontró punto válido para chatarra, se saltea")
			continue
		var item = escena.instantiate()
		get_tree().current_scene.add_child(item)
		item.global_position = pos


func _punto_chatarra_valido() -> Variant:
	var space_state = _player.get_world_3d().direct_space_state
	for intento in chatarra_intentos_max:
		var offset = Vector3(
			randf_range(-chatarra_radio, chatarra_radio),
			0.0,
			randf_range(-chatarra_radio, chatarra_radio)
		)
		var origen  = _player.global_position + offset + Vector3.UP * chatarra_raycast_altura
		var destino = origen + Vector3.DOWN * (chatarra_raycast_altura * 2.0)
		var query = PhysicsRayQueryParameters3D.create(origen, destino)
		var resultado = space_state.intersect_ray(query)
		if resultado:
			return resultado.position + Vector3.UP * chatarra_altura
	return null


func agregar_chatarra(cantidad: int = 1) -> void:
	_chatarra_recolectada += cantidad
	GameStats.chatarra_recolectada += cantidad
	_actualizar_texto_chatarra()
	emit_signal("chatarra_actualizada", _chatarra_recolectada)


func _actualizar_texto_chatarra() -> void:
	if not texto_chatarra:
		return
	texto_chatarra.text = "Chatarra 
		%d" % _chatarra_recolectada


func get_chatarra_recolectada() -> int:
	return _chatarra_recolectada


func _registrar_enemigo_oleada(enemigo: AutoEnemigo) -> void:
	if not enemigo.has_signal("enemigo_muerto"):
		return
	enemigo.enemigo_muerto.connect(_on_enemigo_muerto)


func _on_enemigo_muerto(_enemigo: AutoEnemigo) -> void:
	if _oleada_cerrada:
		return
	_enemigos_vivos_oleada -= 1
	GameStats.enemigos_eliminados += 1
	print("[WaveManager] Enemigos restantes oleada ", _oleada_actual, ": ", _enemigos_vivos_oleada)
	if _enemigos_vivos_oleada <= 0:
		_completar_oleada()


func _completar_oleada() -> void:
	if _oleada_cerrada:
		return
	_oleada_cerrada = true
	print("[WaveManager] Oleada ", _oleada_actual, " completada")
	emit_signal("oleada_completada", _oleada_actual)

	if oleada_sfx:
		oleada_sfx.stream = SONIDO_OLEADA_COMPLETA
		oleada_sfx.play()

	await get_tree().create_timer(2.0).timeout
	_iniciar_oleada(_oleada_actual + 1)


func _on_jugador_derrotado() -> void:
	var pantalla = PANTALLA_DERROTA.instantiate()
	get_tree().root.add_child(pantalla)


func get_oleada_actual() -> int:
	return _oleada_actual

func get_enemigos_restantes() -> int:
	return _enemigos_vivos_oleada
