extends VBoxContainer

@export var enemy_scene: PackedScene
@export var spawn_point: Node3D
@export var spawn_point_item: Node3D
@export var spawn_point_item2: Node3D
@export var spawn_point_item_aleatorio: Node3D



func _process(delta: float) -> void:
	if Input.is_action_just_pressed("1"):
		crear_enemigo()
	elif Input.is_action_just_pressed("3"):
		crear_item_directo("FolaCapo", spawn_point_item)
	elif Input.is_action_just_pressed("4"):
		crear_item_directo("TuboCapo", spawn_point_item2)
	elif Input.is_action_just_pressed("5"):
		crear_item_aleatorio()
	elif Input.is_action_just_pressed("0"):
		cerrar_juego()

# --- Funciones de creación ---

func crear_enemigo() -> void:
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		# Asignar el path ANTES del add_child
		var player_node = get_tree().current_scene.get_node("Jugador")
		if player_node:
			enemy_instance.player_path = player_node.get_path()
		get_tree().current_scene.add_child(enemy_instance)
		enemy_instance.global_position = spawn_point.global_position if spawn_point else Vector3.ZERO
		print("Enemigo creado")

func crear_item_directo(nombre: String, spawn: Node3D) -> void:
	var scene = load(ItemPool.item_paths[nombre]) as PackedScene
	if scene:
		var item_instance = scene.instantiate()
		item_instance.global_position = spawn.global_position if spawn else Vector3.ZERO
		get_tree().current_scene.add_child(item_instance)
		print("Item creado:", nombre)

func crear_item_aleatorio() -> void:
	var scene = ItemPool.get_random_item()
	if scene:
		var item_instance = scene.instantiate()
		item_instance.global_position = spawn_point_item_aleatorio.global_position if spawn_point_item_aleatorio else Vector3.ZERO
		get_tree().current_scene.add_child(item_instance)
		print("Item aleatorio creado:", item_instance.name)
		
func cerrar_juego() -> void:
	print("Cerrando juego...")
	get_tree().quit()
