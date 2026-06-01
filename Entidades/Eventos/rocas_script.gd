extends RigidBody3D

@export var danio: int = 25
var _golpeada: bool = false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _golpeada:
		return
	_golpeada = true

	if body.is_in_group("Player"):
		body.apply_damage(danio)
		print("[Roca] Impacto en jugador — daño: ", danio)
	queue_free()
