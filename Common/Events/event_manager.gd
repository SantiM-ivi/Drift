# event_manager.gd
extends Node

signal evento_iniciado(nombre: String)
signal evento_finalizado(nombre: String)

@export var intervalo: float = 20.0
@export var duracion_transicion: float = 3.0
@export var duracion_evento: float = 15.0

# --- Rocas ---
@export var roca_escena: PackedScene = preload("res://Entidades/Eventos/rock.tscn")
@export var roca_spawn_radio: float = 15.0
@export var roca_altura: float = 20.0
@export var roca_intervalo_spawn: float = 2.0

# --- Lluvia ---
@export var lluvia_speed_bonus: float = 3.0

# --- Tormenta ---
@export var tornado_escena: PackedScene = preload("res://Entidades/Eventos/tornado.tscn")
@export var tornado_cantidad: int = 2
@export var tornado_spawn_radio: float = 20.0

var lluvia_particles: GPUParticles3D = null
var _timer: float = 0.0
var _evento_timer: float = 0.0
var _roca_spawn_timer: float = 0.0
var _ultimo_evento: int = -1
var _evento_activo: int = -1
var _env: Environment
var _player: RigidBody3D = null

var _rocas_activas: Array = []
var _tornados_activos: Array = []

const EVENTOS_VISUAL = {
	"ROCAS": {
		"fog_color":    Color(0.4, 0.3, 0.2),
		"fog_density":  0.03,
		"sky_color":    Color(0.5, 0.4, 0.3),
		"light_color":  Color(0.6, 0.5, 0.4),
	},
	"LLUVIA": {
		"fog_color":    Color(0.2, 0.25, 0.35),
		"fog_density":  0.02,
		"sky_color":    Color(0.15, 0.2, 0.3),
		"light_color":  Color(0.3, 0.35, 0.5),
	},
	"TORMENTA": {
		"fog_color":    Color(0.1, 0.08, 0.15),
		"fog_density":  0.04,
		"sky_color":    Color(0.05, 0.05, 0.1),
		"light_color":  Color(0.2, 0.15, 0.3),
	},
}

var _transicionando: bool = false
var _t: float = 0.0
var _fog_color_origen:    Color
var _fog_color_destino:   Color
var _fog_density_origen:  float
var _fog_density_destino: float
var _light_color_origen:  Color
var _light_color_destino: Color
var _sky_color_origen:    Color
var _sky_color_destino:   Color

enum Evento { ROCAS, LLUVIA, TORMENTA }

func _ready() -> void:
	var we = get_tree().current_scene.get_node_or_null("WorldEnvironment")
	if we:
		_env = we.environment
	else:
		push_error("[EventManager] No se encontró WorldEnvironment")
		return

	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		lluvia_particles = player.get_node_or_null("LluviaParticles")
	if not lluvia_particles:
		push_warning("[EventManager] No se encontró LluviaParticles en el jugador")


func _process(delta: float) -> void:
	# Lazy load del player
	if not _player:
		_player = get_tree().get_first_node_in_group("Player") as RigidBody3D
		if not _player:
			return

	# Transición visual
	if _transicionando:
		_t = clamp(_t + delta / duracion_transicion, 0.0, 1.0)
		_env.fog_light_color     = _fog_color_origen.lerp(_fog_color_destino, _t)
		_env.fog_density         = lerp(_fog_density_origen, _fog_density_destino, _t)
		_env.ambient_light_color = _light_color_origen.lerp(_light_color_destino, _t)
		if _t >= 1.0:
			_transicionando = false

	# Spawn de rocas escalonado
	if _evento_activo == Evento.ROCAS:
		_roca_spawn_timer += delta
		if _roca_spawn_timer >= roca_intervalo_spawn:
			_roca_spawn_timer = 0.0
			_spawnear_roca()

	# Timer duración del evento
	if _evento_activo != -1:
		_evento_timer += delta
		if _evento_timer >= duracion_evento:
			_finalizar_evento()
		return  # no avanza el _timer mientras hay evento activo

	# Timer entre eventos — solo corre si no hay evento activo
	_timer += delta
	if _timer >= intervalo:
		_timer = 0.0
		_lanzar_evento_aleatorio()


func _lanzar_evento_aleatorio() -> void:
	var opciones = [Evento.ROCAS, Evento.LLUVIA, Evento.TORMENTA]
	if _ultimo_evento != -1:
		opciones.erase(_ultimo_evento)
	var elegido: int = opciones[randi() % opciones.size()]
	_ultimo_evento = elegido
	_evento_activo = elegido
	_evento_timer  = 0.0

	match elegido:
		Evento.ROCAS:    _evento_rocas()
		Evento.LLUVIA:   _evento_lluvia()
		Evento.TORMENTA: _evento_tormenta()


func _aplicar_visual(nombre_evento: String) -> void:
	var v = EVENTOS_VISUAL[nombre_evento]
	_fog_color_origen    = _env.fog_light_color
	_fog_color_destino   = v["fog_color"]
	_fog_density_origen  = _env.fog_density
	_fog_density_destino = v["fog_density"]
	_light_color_origen  = _env.ambient_light_color
	_light_color_destino = v["light_color"]
	_sky_color_origen    = _env.ambient_light_color
	_sky_color_destino   = v["sky_color"]
	_t = 0.0
	_transicionando = true


func _finalizar_evento() -> void:
	var nombre = Evento.keys()[_evento_activo]
	print("[EventManager] Evento ", nombre, " finalizado.")
	emit_signal("evento_finalizado", nombre)

	match _evento_activo:
		Evento.LLUVIA:   _limpiar_lluvia()
		Evento.ROCAS:    _limpiar_rocas()
		Evento.TORMENTA: _limpiar_tornados()

	_evento_activo = -1


# ─── LLUVIA ───────────────────────────────────────────────────────────────────

func _evento_lluvia() -> void:
	print("[Evento] 🌧️ LLUVIA")
	_aplicar_visual("LLUVIA")
	if lluvia_particles:
		lluvia_particles.activar()
	if _player:
		_player.velocidad_maxima += lluvia_speed_bonus
	emit_signal("evento_iniciado", "LLUVIA")

func _limpiar_lluvia() -> void:
	if lluvia_particles:
		lluvia_particles.desactivar()
	if _player:
		_player.velocidad_maxima -= lluvia_speed_bonus


# ─── ROCAS ────────────────────────────────────────────────────────────────────

func _evento_rocas() -> void:
	print("[Evento] 🪨 ROCAS")
	_aplicar_visual("ROCAS")
	if lluvia_particles:
		lluvia_particles.emitting = false
	_roca_spawn_timer = roca_intervalo_spawn  # spawnea la primera de inmediato
	emit_signal("evento_iniciado", "ROCAS")

func _spawnear_roca() -> void:
	if not _player or not roca_escena:
		push_error("[Roca] player o escena nulos")
		return

	var roca: Node3D = roca_escena.instantiate()
	get_tree().current_scene.add_child(roca)

	var offset = Vector3(
		randf_range(-roca_spawn_radio, roca_spawn_radio),
		roca_altura,
		randf_range(-roca_spawn_radio, roca_spawn_radio)
	)
	roca.global_position = _player.global_position + offset
	_rocas_activas.append(roca)
	print("[Roca] spawneada en: ", roca.global_position, " | player en: ", _player.global_position)

func _limpiar_rocas() -> void:
	for roca in _rocas_activas:
		if is_instance_valid(roca):
			roca.queue_free()
	_rocas_activas.clear()
	_roca_spawn_timer = 0.0


# ─── TORMENTA ─────────────────────────────────────────────────────────────────

func _evento_tormenta() -> void:
	print("[Evento] ⚡ TORMENTA")
	_aplicar_visual("TORMENTA")
	if lluvia_particles:
		lluvia_particles.emitting = false
	_spawnear_tornados()
	emit_signal("evento_iniciado", "TORMENTA")

func _spawnear_tornados() -> void:
	if not _player or not tornado_escena:
		push_error("[Tornado] player o escena nulos")
		return

	for i in tornado_cantidad:
		var tornado: Node3D = tornado_escena.instantiate()
		get_tree().current_scene.add_child(tornado)

		var angle = (TAU / tornado_cantidad) * i
		var offset = Vector3(cos(angle) * tornado_spawn_radio, 0.0, sin(angle) * tornado_spawn_radio)
		tornado.global_position = _player.global_position + offset
		_tornados_activos.append(tornado)
		print("[Tornado] spawneado en: ", tornado.global_position, " | player en: ", _player.global_position)

func _limpiar_tornados() -> void:
	for tornado in _tornados_activos:
		if is_instance_valid(tornado):
			tornado.queue_free()
	_tornados_activos.clear()


# ─── UTILS ────────────────────────────────────────────────────────────────────

func get_evento_activo() -> String:
	if _evento_activo == -1:
		return "NINGUNO"
	return Evento.keys()[_evento_activo]
