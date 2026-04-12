extends Area3D

@export var roca_scene: PackedScene
@export var cantidad_rocas: int = 5
@export var intervalo: float = 20.0
@export var altura_caida: float = 15.0

var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= intervalo:
		_timer = 0.0
		_evento_rocas()

func _evento_rocas() -> void:
	print("Evento: lluvia de rocas!")
	for i in cantidad_rocas:
		var roca = roca_scene.instantiate()
		get_tree().current_scene.add_child(roca)
		roca.scale = Vector3.ONE
		var spawn = _punto_aleatorio_en_area()
		roca.global_position = spawn
		# Destruir después de 5 segundos
		get_tree().create_timer(10.0).timeout.connect(roca.queue_free)

func _punto_aleatorio_en_area() -> Vector3:
	# Leer el tamaño del CollisionShape3D hijo
	var shape_node = get_node_or_null("CollisionShape3D")
	if shape_node == null or shape_node.shape == null:
		push_warning("EventoRocas: no se encontró CollisionShape3D")
		return global_position + Vector3(0, altura_caida, 0)
	
	var shape = shape_node.shape
	var ext: Vector3 = Vector3.ZERO
	
	if shape is BoxShape3D:
		ext = shape.size * 0.5
	
	return Vector3(
		global_position.x + randf_range(-ext.x, ext.x),
		global_position.y + altura_caida,
		global_position.z + randf_range(-ext.z, ext.z)
	)
