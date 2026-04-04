extends Area3D   # mejor usar Area3D para balas, no RigidBody3D

@export var speed: float = 100.0
@export var lifetime: float = 3.0
@export var damage: int = 10

var timer: float = 0.0

func _ready():
	# mover la bala hacia adelante
	var dir = -global_transform.basis.z
	set_physics_process(true)
	$CollisionShape3D.disabled = false
	# conectar la señal de colisión
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += -global_transform.basis.z * speed * delta
	timer += delta
	if timer > lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	print("Bala impactó contra:", body.name)
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
		print("Daño aplicado:", damage)
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	print("Bala impactó un área:", area.name)
	queue_free()
