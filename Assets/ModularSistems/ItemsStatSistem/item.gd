extends Node3D
class_name ItemMundo

@export var nombre_item: String
@export var slot: String
@export var stats: ItemsStats

const OUTLINE_SHADER := preload("res://Common/Shaders/item.gdshader")

func _ready() -> void:
	_apply_outline_to_meshes(self)

func _apply_outline_to_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_add_outline_material(node)
	for child in node.get_children():
		_apply_outline_to_meshes(child)

func _add_outline_material(mesh_instance: MeshInstance3D) -> void:
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = OUTLINE_SHADER
	outline_mat.set_shader_parameter("color", Color.WHITE)
	outline_mat.set_shader_parameter("size", 1.05)

	for i in mesh_instance.mesh.get_surface_count():
		# Obtenemos el material actual de la superficie (original o override)
		var current_mat := mesh_instance.get_active_material(i)
		if current_mat == null:
			# Si no tiene material, asignamos el outline directo
			mesh_instance.set_surface_override_material(i, outline_mat)
		else:
			# Lo encadenamos como next_pass para no pisar el material original
			var mat_copy := current_mat.duplicate() as Material
			mat_copy.next_pass = outline_mat
			mesh_instance.set_surface_override_material(i, mat_copy)
