extends CanvasLayer
# --- Nodos ---
@onready var health_bar: ProgressBar = $BottomLeft/Content/HealthBar
@onready var health_label: Label     = $BottomLeft/Content/HealthLabel
@onready var speed_label: Label      = $BottomRight/Content/SpeedLabel
@export var speed_effect_color_rect:ColorRect


var max_health: float = 100.0
func _ready() -> void:
	ApplySpeedEffect.effect_change.connect(apply_effect)
	health_bar.max_value = max_health
	set_health(100)
	set_speed(0)
# -- API publica ----------------------------------------------------------
func set_max_health(value: int) -> void:
	max_health = float(value)
	health_bar.max_value = max_health
func set_health(value: int) -> void:
	health_bar.value = clamp(float(value), 0.0, max_health)
	var ratio = health_bar.value / max_health
	if ratio > 0.5:
		health_bar.modulate = Color(0.2, 1.0, 0.2)
	elif ratio > 0.25:
		health_bar.modulate = Color(1.0, 0.7, 0.0)
	else:
		health_bar.modulate = Color(1.0, 0.15, 0.15)
		_flash(health_bar)
func set_speed(kmh: int) -> void:
	speed_label.text = str(abs(kmh))
# -- Interno --------------------------------------------------------------
func _flash(node: CanvasItem) -> void:
	var tween = create_tween().set_loops(3)
	tween.tween_property(node, "modulate:a", 0.2, 0.12)
	tween.tween_property(node, "modulate:a", 1.0, 0.12)
func apply_effect(value:float) -> void:
	speed_effect_color_rect.material.set_shader_parameter('effect_power', value)
