extends VBoxContainer

@export var enemy_scene: PackedScene   # arrastrá aquí la escena Enemy.tscn desde el inspector
@export var spawn_point: Node3D        # opcional: un nodo en la escena que indique dónde spawnear

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("1"):
		crear_enemigo()
	elif Input.is_action_just_pressed("2"):
		crear_item_vida()
	elif Input.is_action_just_pressed("3"):
		crear_item_armadura()
	elif Input.is_action_just_pressed("4"):
		crear_item_municion()
	elif Input.is_action_just_pressed("5"):
		crear_item_aleatorio()
	elif Input.is_action_just_pressed("6"):
		ganar_partida()
	elif Input.is_action_just_pressed("7"):
		perder_partida()
	elif Input.is_action_just_pressed("8"):
		perder_vida(1)
	elif Input.is_action_just_pressed("9"):
		perder_vida(10)
	elif Input.is_action_just_pressed("0"):
		cerrar_juego()
	elif Input.is_action_just_pressed("guardar"):
		guardar_partida()

# --- Acciones de prueba ---

func crear_enemigo() -> void:
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		
		if spawn_point:
			enemy_instance.global_position = spawn_point.global_position
		else:
			enemy_instance.global_position = Vector3.ZERO
		
		# --- Asignar el PlayerPath ---
		var player_node = get_tree().current_scene.get_node("car") # ajustá el nombre exacto del nodo
		if player_node:
			enemy_instance.player_path = player_node.get_path()
		
		get_tree().current_scene.add_child(enemy_instance)
		print("Enemigo creado en la escena con PlayerPath asignado")

func crear_item_vida() -> void:
	print("Crear Item Vida")

func crear_item_armadura() -> void:
	print("Crear Item Armadura")

func crear_item_municion() -> void:
	print("Crear Item Municion")

func crear_item_aleatorio() -> void:
	print("Crear Item Aleatorio")

func ganar_partida() -> void:
	print("Ganar Partida")

func perder_partida() -> void:
	print("Perder Partida")

func perder_vida(cantidad: int) -> void:
	print("Perder %s de Vida" % cantidad)

func guardar_partida() -> void:
	print("Guardar Partida")

func cerrar_juego() -> void:
	print("Cerrando juego...")
	get_tree().quit()
