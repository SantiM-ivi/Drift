# event_manager.gd
extends Node

@export var intervalo: float = 20.0
@export var duracion_transicion: float = 3.0
var lluvia_particles: GPUParticles3D = null
var _timer: float = 0.0
var _ultimo_evento: int = -1
var _env: Environment

# Estado visual por evento
const EVENTOS_VISUAL = {
	"ROCAS": {
		"fog_color": Color(0.4, 0.3, 0.2),       # marrón polvoriento
		"fog_density": 0.03,
		"sky_color": Color(0.5, 0.4, 0.3),
		"light_color": Color(0.6, 0.5, 0.4),
	},
	"LLUVIA": {
		"fog_color": Color(0.2, 0.25, 0.35),      # azul grisáceo
		"fog_density": 0.02,
		"sky_color": Color(0.15, 0.2, 0.3),
		"light_color": Color(0.3, 0.35, 0.5),
	},
	"TORMENTA": {
		"fog_color": Color(0.1, 0.08, 0.15),      # violeta oscuro
		"fog_density": 0.04,
		"sky_color": Color(0.05, 0.05, 0.1),
		"light_color": Color(0.2, 0.15, 0.3),
	},
}

# Transición
var _transicionando: bool = false
var _t: float = 0.0
var _fog_color_origen: Color
var _fog_color_destino: Color
var _fog_density_origen: float
var _fog_density_destino: float
var _light_color_origen: Color
var _light_color_destino: Color

enum Evento { ROCAS, LLUVIA, TORMENTA }

func _ready() -> void:
	var we = get_tree().current_scene.get_node("WorldEnvironment")
	_env = we.environment
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		lluvia_particles = jugador.get_node_or_null("GPUParticles3D")
		print("[EventManager] Lluvia particles: ", lluvia_particles)
	else:
		print("[EventManager] No se encontró el jugador")
	print("[EventManager] Listo. Primer evento en ", intervalo, " segundos.")

func _process(delta: float) -> void:
	if _transicionando:
		_t += delta / duracion_transicion
		_t = clamp(_t, 0.0, 1.0)
		_env.fog_light_color = _fog_color_origen.lerp(_fog_color_destino, _t)
		_env.fog_density = lerp(_fog_density_origen, _fog_density_destino, _t)
		_env.volumetric_fog_albedo = _fog_color_origen.lerp(_fog_color_destino, _t)
		_env.fog_light_color = _light_color_origen.lerp(_light_color_destino, _t)
		if _t >= 1.0:
			_transicionando = false

	_timer += delta
	if _timer >= intervalo:
		_timer = 0.0
		_lanzar_evento_aleatorio()

func _lanzar_evento_aleatorio() -> void:
	var opciones = [Evento.ROCAS, Evento.LLUVIA, Evento.TORMENTA]
	if _ultimo_evento != -1:
		opciones.erase(_ultimo_evento)
	var elegido = opciones[randi() % opciones.size()]
	_ultimo_evento = elegido

	match elegido:
		Evento.ROCAS:    _evento_rocas()
		Evento.LLUVIA:   _evento_lluvia()
		Evento.TORMENTA: _evento_tormenta()

func _aplicar_visual(nombre_evento: String) -> void:
	var v = EVENTOS_VISUAL[nombre_evento]
	_fog_color_origen = _env.fog_light_color
	_fog_color_destino = v["fog_color"]
	_fog_density_origen = _env.fog_density
	_fog_density_destino = v["fog_density"]
	_light_color_origen = _env.fog_light_color
	_light_color_destino = v["light_color"]
	_t = 0.0
	_transicionando = true

func _evento_lluvia() -> void:
	print("[Evento] 🌧️ LLUVIA - Comienza la lluvia intensa!")
	_aplicar_visual("LLUVIA")
	if lluvia_particles:
		lluvia_particles.emitting = true
		lluvia_particles.show()

func _evento_rocas() -> void:
	print("[Evento] 🪨 ROCAS - Empiezan a caer rocas!")
	_aplicar_visual("ROCAS")
	if lluvia_particles:
		lluvia_particles.emitting = false

func _evento_tormenta() -> void:
	print("[Evento] ⚡ TORMENTA - Tormenta eléctrica!")
	_aplicar_visual("TORMENTA")
	if lluvia_particles:
		lluvia_particles.emitting = false
