extends Area3D

@export var speed: float = 100.0
@export var lifetime: float = 3.0
@export var damage: int = 10

var timer: float = 0.0

func _ready():
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += -global_transform.basis.z * speed * delta
	timer += delta
	if timer > lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	queue_free()
