class_name GenisysEnemy
extends CharacterBody3D

@export var enemy_groups: Array[String] = []
@export var stats: Stats

func _ready() -> void:
	for group in enemy_groups:
		add_to_group(group)

func on_triggered() -> void:
	# Override en clases hijas
	pass
