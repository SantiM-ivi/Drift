extends Node

signal effect_change(value: float)

@export var speed_effect_max: float      = 1.0
@export var speed_effect_suavidad: float = 5.0

var _boost_activo: bool  = false
var _valor_actual: float = 0.0

func _process(delta: float) -> void:
	var objetivo = speed_effect_max if _boost_activo else 0.0
	_valor_actual = lerp(_valor_actual, objetivo, delta * speed_effect_suavidad)
	effect_change.emit(_valor_actual)

# ── Llamar desde el jugador cada vez que cambia el estado del boost ───────────
func set_boost_activo(activo: bool) -> void:
	_boost_activo = activo
