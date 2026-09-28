class_name ChaseState
extends BaseEnemyState

func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)

func on_enter() -> void:
	pass

func physics_process(delta: float) -> void:
	if not is_instance_valid(enemy.player):
		return

	# 1. Obtenemos nuestra posición de flanqueo única
	var target_pos = _obtener_objetivo_flanqueo()
	
	enemy.nav.target_position = target_pos

	var next = enemy.nav.get_next_path_position()
	var dir_to_next = enemy.global_position.direction_to(next)

	var distance_to_player = enemy.global_position.distance_to(enemy.player.global_position)
	if distance_to_player < 15.0:
		# Si estamos cerca, ignoramos el navmesh y apuntamos directo a nuestro flanco
		dir_to_next = enemy.global_position.direction_to(target_pos)

	# 2. Evasión de emergencia (por si se cruzan en el camino)
	var fuerza_separacion = Vector3.ZERO
	var enemigos_cercanos = enemy.get_tree().get_nodes_in_group("Enemigos")
	
	for otro in enemigos_cercanos:
		if otro == enemy or not is_instance_valid(otro): 
			continue
		var dist_enemigo = enemy.global_position.distance_to(otro.global_position)
		if dist_enemigo < 8.0:
			var alejar = enemy.global_position - otro.global_position
			alejar.y = 0.0 # Nunca empujar hacia arriba o abajo
			fuerza_separacion += alejar.normalized() * (8.0 - dist_enemigo)

	if fuerza_separacion != Vector3.ZERO:
		dir_to_next = (dir_to_next + (fuerza_separacion * 0.5)).normalized()

	enemy.aplicar_giro_directo(dir_to_next)

# --- NUEVO: ASIGNACIÓN DE CARRILES / FLANCOS ---
func _obtener_objetivo_flanqueo() -> Vector3:
	var player = enemy.player
	# Predecir un poco la posición para que el flanqueo sea en movimiento
	var base_pos = player.global_position + (player.linear_velocity * 0.5) 
	
	var grupo = enemy.get_tree().get_nodes_in_group("Enemigo")
	var mi_indice = grupo.find(enemy)
	
	# Obtenemos los vectores laterales y traseros del auto del jugador
	var right_vec = player.global_transform.basis.x.normalized()
	var back_vec = player.global_transform.basis.z.normalized()
	
	var offset = Vector3.ZERO
	var distancia = 12.0 # Metros de separación a los lados
	
	# Repartimos las posiciones según el número de enemigo que sea (0, 1, 2, 3...)
	match mi_indice % 5:
		0: 
			offset = Vector3.ZERO # El primero va directo a chocarte (centro)
		1: 
			offset = -right_vec * distancia + back_vec * (distancia * 0.2) # Izquierda
		2: 
			offset = right_vec * distancia + back_vec * (distancia * 0.2) # Derecha
		3: 
			offset = -right_vec * (distancia * 1.5) + back_vec * distancia # Atrás a la izquierda
		4: 
			offset = right_vec * (distancia * 1.5) + back_vec * distancia # Atrás a la derecha
			
	return base_pos + offset
