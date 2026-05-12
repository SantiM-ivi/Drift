extends CanvasLayer

# --- Nodos ---
@onready var health_bar: ProgressBar = $BottomLeft/Content/HealthBar
@onready var health_label: Label     = $BottomLeft/Content/HealthLabel
@onready var speed_label: Label      = $BottomRight/Content/SpeedLabel
@onready var mission_label: Label    = $TopLeft/Content/MissionTitle
@onready var compass: Control        = $TopCenter/CompassBar

var max_health: float = 100.0

func _ready() -> void:
	set_health(100.0)
	set_speed(0)
	set_mission("Destruye el convoy")

# ── API pública ──────────────────────────────────────

func set_health(value: float) -> void:
	health_bar.value = clamp(value, 0.0, max_health)
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

func set_mission(title: String) -> void:
	mission_label.text = title.to_upper()

# Pasá rotation_degrees.y del vehículo (Node3D)
func set_compass(angle_deg: float) -> void:
	compass.set_angle(angle_deg)

# ── Interno ──────────────────────────────────────────

func _flash(node: CanvasItem) -> void:
	var tween = create_tween().set_loops(3)
	tween.tween_property(node, "modulate:a", 0.2, 0.12)
	tween.tween_property(node, "modulate:a", 1.0, 0.12)
