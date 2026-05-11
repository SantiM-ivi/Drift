class_name ChaseState
extends BaseEnemyState

var _engine_force: float = 400.0   # más lento
var _steer_speed: float = 150.0      # gira más rápido
var _steer_actual: float = 0.5      # limitá el ángulo máximo
var _steer_limit: float = 0.5 
func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)

func on_enter() -> void:
	enemy.nav.target_position = enemy.player.global_position

func physics_process(delta: float) -> void:
	if not is_instance_valid(enemy.player): return

	# Actualizar destino
	enemy.nav.target_position = enemy.player.global_position

	# Dirección al siguiente punto del path
	var next = enemy.nav.get_next_path_position()
	var dir_to_next = enemy.global_position.direction_to(next)

	# Convertir dirección global a local para saber si girar izq o der
	var local_dir = enemy.global_transform.basis.inverse() * dir_to_next
	var steer_target = clamp(-local_dir.x, -_steer_limit, _steer_limit)

	_steer_actual = move_toward(_steer_actual, steer_target, _steer_speed * delta)

	# Aplicar steering y fuerza
	enemy.get_node("left_front").steering  = _steer_actual
	enemy.get_node("right_front").steering = _steer_actual
	enemy.get_node("left_back").engine_force  = _engine_force
	enemy.get_node("right_back").engine_force = _engine_force
