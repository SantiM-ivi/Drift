# lluvia_particles.gd
extends GPUParticles3D

func activar() -> void:
	emitting = true
	show()

func desactivar() -> void:
	emitting = false
	# Esperar que las partículas existentes terminen antes de ocultar
	await get_tree().create_timer(lifetime).timeout
	hide()
