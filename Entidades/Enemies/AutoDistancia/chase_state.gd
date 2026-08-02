class_name ChaseState
extends BaseEnemyState

func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)

func on_enter() -> void:
	if is_instance_valid(enemy.player):
		enemy.nav.target_position = enemy.player.global_position

func physics_process(delta: float) -> void:
	if not is_instance_valid(enemy.player):
		return

	enemy.nav.target_position = enemy.player.global_position

	var next = enemy.nav.get_next_path_position()
	var dir_to_next = enemy.global_position.direction_to(next)


	if enemy.global_position.distance_to(enemy.player.global_position) < 8.0:
		dir_to_next = enemy.global_position.direction_to(enemy.player.global_position)

	enemy.aplicar_giro_directo(dir_to_next) 
