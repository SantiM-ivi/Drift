class_name AttackState
extends BaseEnemyState
var fire_rate: float = 2.0   # podés moverlo a Stats también si querés
var _timer: float = 0.0
var _steer_actual: float = 0.0
func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)
func on_enter() -> void:
	_timer = fire_rate
func physics_process(delta: float) -> void:
	if not is_instance_valid(enemy.player): return
	_apuntar(delta)
	_moverse()
	_disparar(delta)
func _apuntar(delta: float) -> void:
	var steer_speed = enemy.stats.current_steer_speed if enemy.stats else 2.0
	var next = enemy.nav.get_next_path_position()
	var local_dir = enemy.global_transform.basis.inverse() * enemy.global_position.direction_to(next)
	var steer_target = clamp(-local_dir.x, -1.0, 1.0)
	_steer_actual = move_toward(_steer_actual, steer_target, steer_speed * delta)
	enemy.get_node("left_front").steering  = _steer_actual
	enemy.get_node("right_front").steering = _steer_actual
func _moverse() -> void:
	var engine_force = enemy.stats.current_attack_speed if enemy.stats else 200.0
	enemy.get_node("left_back").engine_force  = engine_force
	enemy.get_node("right_back").engine_force = engine_force
func _disparar(delta: float) -> void:
	_timer += delta
	if _timer >= fire_rate:
		_timer = 0.0
		var proyectil = enemy.proyectil_scene.instantiate()
		enemy.get_tree().current_scene.add_child(proyectil)
		proyectil.global_position = enemy.shoot_point.global_position
		var dir = enemy.shoot_point.global_position.direction_to(enemy.player.global_position)
		proyectil.direction = dir
		enemy.reproducir_disparo()
