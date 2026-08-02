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

	# Continúa acosando y avanzando frontalmente hacia el jugador mientras está en rango de disparo
	var dir_al_jugador = enemy.global_position.direction_to(enemy.player.global_position)
	enemy.aplicar_giro_directo(dir_al_jugador)

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
