class_name ChaseState
extends BaseEnemyState

var _steer_actual: float = 0.0

func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)

func on_enter() -> void:
	enemy.nav.target_position = enemy.player.global_position

func physics_process(delta: float) -> void:
	if not is_instance_valid(enemy.player): return

	enemy.nav.target_position = enemy.player.global_position

	var next = enemy.nav.get_next_path_position()
	var dir_to_next = enemy.global_position.direction_to(next)
	var local_dir = enemy.global_transform.basis.inverse() * dir_to_next

	var steer_limit = enemy.stats.current_steer_limit if enemy.stats else 0.5
	var steer_speed = enemy.stats.current_steer_speed if enemy.stats else 150.0
	var engine_force = enemy.stats.current_speed if enemy.stats else 400.0

	var steer_target = clamp(-local_dir.x, -steer_limit, steer_limit)
	_steer_actual = move_toward(_steer_actual, steer_target, steer_speed * delta)

	enemy.get_node("left_front").steering  = _steer_actual
	enemy.get_node("right_front").steering = _steer_actual
	enemy.get_node("left_back").engine_force  = engine_force
	enemy.get_node("right_back").engine_force = engine_force
