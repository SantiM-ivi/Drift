class_name AttackState
extends BaseEnemyState

var fire_rate: float = 1.5
var _timer: float = 0.0

func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)

func on_enter() -> void:
	_timer = fire_rate

func physics_process(delta: float) -> void:
	if not is_instance_valid(enemy.player):
		return

	# Predecir un poco la posición incluso atacando
	var posicion_futura = enemy.player.global_position + (enemy.player.linear_velocity * 0.3)
	var dir_al_jugador = enemy.global_position.direction_to(posicion_futura)
	
	enemy.aplicar_giro_directo(dir_al_jugador)

	# 3. LÓGICA DE EMBESTIDA (RAMMING)
	var frente_actual = Vector3(-enemy.global_basis.z.x, 0.0, -enemy.global_basis.z.z).normalized()
	var alineacion = frente_actual.dot(dir_al_jugador)
	
	# Si el enemigo te tiene en la mira (casi de frente), pisa el acelerador a fondo
	if alineacion > 0.85:
		var boost = (enemy.stats.current_speed if enemy.stats else enemy.fuerza_motor) * 1.5
		enemy.get_node("left_back").engine_force = boost
		enemy.get_node("right_back").engine_force = boost

	_disparar(delta)

func _disparar(delta: float) -> void:
	_timer += delta
	if _timer >= fire_rate:
		_timer = 0.0
		if enemy.proyectil_scene and enemy.shoot_point:
			var proyectil = enemy.proyectil_scene.instantiate()
			enemy.get_tree().current_scene.add_child(proyectil)
			proyectil.global_position = enemy.shoot_point.global_position

			var dir = enemy.shoot_point.global_position.direction_to(enemy.player.global_position)
			if "direction" in proyectil:
				proyectil.direction = dir

			enemy.reproducir_disparo()
