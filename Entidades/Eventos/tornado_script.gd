extends Node3D

@export var velocidad_movimiento: float = 4.0
@export var velocidad_rotacion: float   = 5.0
@export var radio_danio: float          = 5.0
@export var danio_por_segundo: float    = 1.0
@export var tiempo_cambio_dir: float    = 3.0
@export var duracion_salida: float      = 1.5  # cuánto tarda en bajar

var _dir: Vector3 = Vector3.ZERO
var _dir_timer: float = 0.0
var _player: RigidBody3D = null
var _saliendo: bool = false  # bloquea movimiento y daño durante la salida

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	if not _player:
		push_error("[Tornado] No se encontró ningún nodo en el grupo 'Player'")
	_elegir_nueva_direccion()

func _process(delta: float) -> void:
	if _saliendo:
		return
	rotate_y(velocidad_rotacion * delta)
	global_position += _dir * velocidad_movimiento * delta
	_dir_timer += delta
	if _dir_timer >= tiempo_cambio_dir:
		_dir_timer = 0.0
		_elegir_nueva_direccion()
	if _player and is_instance_valid(_player):
		if global_position.distance_to(_player.global_position) <= radio_danio:
			_player.apply_damage(int(danio_por_segundo * delta))

func _elegir_nueva_direccion() -> void:
	var angulo = randf() * TAU
	_dir = Vector3(cos(angulo), 0.0, sin(angulo)).normalized()

func iniciar_salida() -> void:
	if _saliendo:
		return
	_saliendo = true
	var destino_y = global_position.y - 30.0  # cuánto baja antes de desaparecer
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position:y", destino_y, duracion_salida)
	tween.tween_callback(queue_free)
