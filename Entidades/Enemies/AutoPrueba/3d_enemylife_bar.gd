extends Sprite3D

@onready var barra: ProgressBar = $"../3DHud/LifeBarTexture"

func _ready() -> void:
	var enemigo = get_parent()
	if enemigo and enemigo.stats:
		enemigo.stats.health_changed.connect(_on_health_changed)
		_on_health_changed(enemigo.stats.health, enemigo.stats.current_max_health)

func _on_health_changed(cur_health: int, max_health: int) -> void:
	barra.max_value = max_health
	barra.value = cur_health
