extends Node
class_name PlayerEquipment

@onready var items_equipados: Node3D = $"../ItemsEquipados"

var equipado: Dictionary = {}

func _ready() -> void:
	for item in items_equipados.get_children():
		item.visible = false

func equipar(slot: String, nombre_item: String, drop_position: Vector3) -> void:
	# Tirar el anterior al suelo
	if equipado.has(slot) and equipado[slot] != null:
		_tirar_al_suelo(equipado[slot].name, drop_position)
		equipado[slot].visible = false

	# Mostrar el nuevo
	var nuevo = items_equipados.get_node_or_null(nombre_item)
	if nuevo == null:
		push_warning("Item no encontrado: %s" % nombre_item)
		return

	nuevo.visible = true
	equipado[slot] = nuevo

func _tirar_al_suelo(nombre: String, position: Vector3) -> void:
	print("Intentando tirar: %s" % nombre)
	print("Keys en item_paths: ", ItemPool.item_paths.keys())
	if not ItemPool.item_paths.has(nombre):
		push_warning("No hay path para tirar: %s" % nombre)
		return
	var scene = load(ItemPool.item_paths[nombre]) as PackedScene
	if scene == null:
		print("Scene es null para: %s" % nombre)
		return
	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = position + Vector3(0, 0.5, 0)
	print("Item tirado al suelo: %s" % nombre)
