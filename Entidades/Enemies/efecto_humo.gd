extends GPUParticles3D

func _ready() -> void:
	# Nos aseguramos de que empiece a emitir en cuanto aparece
	emitting = true
	
	# Esperamos a que la partícula avise que ya terminó su ciclo
	await finished
	
	# Se borra de la escena para no consumir RAM
	queue_free()
