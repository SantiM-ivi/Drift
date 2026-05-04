class_name AutoEnemigo
extends VehicleBody3D

@onready var sm: StateMachine = $StateMachine
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var shoot_point: Node3D = $ShootPoint
@export var stats: Stats
var proyectil_scene: PackedScene = preload("res://Common/Projectiles/Bullets/bullet_enemy.tscn")

var player: VehicleBody3D = null

func _ready() -> void:
	center_of_mass = Vector3(0, -1.0, 0)
	mass = 100.0          # más pesado = más estable
	angular_damp = 5.0
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)
	attack_area.body_entered.connect(_on_attack_entered)
	attack_area.body_exited.connect(_on_attack_exited)
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.health_depleted.connect(_on_health_depleted)
	sm.transition_to(IdleState.new(self, sm))

func _physics_process(delta: float) -> void:
	sm.physics_process(delta)
	_auto_enderezar(delta)

func _on_detection_entered(body: Node) -> void:
	if body is VehicleBody3D and body != self:
		player = body
		sm.transition_to(ChaseState.new(self, sm))

func _on_detection_exited(body: Node) -> void:
	if body == player:
		player = null
		sm.transition_to(IdleState.new(self, sm))

func _on_attack_entered(body: Node) -> void:
	if body == player:
		sm.transition_to(AttackState.new(self, sm))

func _on_attack_exited(body: Node) -> void:
	if body == player:
		sm.transition_to(ChaseState.new(self, sm))

func _auto_enderezar(delta: float) -> void:
	var up_local = global_transform.basis.y
	var dot = up_local.dot(Vector3.UP)
	
	# Si el auto está volcado (dot cercano a -1) o de lado (dot cercano a 0)
	if dot < 0.5:
		var correction = up_local.cross(Vector3.UP)
		apply_torque(correction * 10000.0)
		# Frenamos la rotación existente para que no siga girando
		angular_velocity = angular_velocity.lerp(Vector3.ZERO, 0.1)


func _on_health_changed(cur_health: int, max_health: int) -> void:
	print("Enemy HP:", cur_health, "/", max_health)

func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - stats.current_defense)
		stats.health -= final_damage
		print("Enemy recibió daño:", final_damage, "HP restante:", stats.health)
		
		
func _on_health_depleted() -> void:
	var scene = ItemPool.get_random_item()
	if scene:
		var item_instance = scene.instantiate()
		item_instance.global_position = global_position
		get_tree().current_scene.add_child(item_instance)
	queue_free()
	
	
