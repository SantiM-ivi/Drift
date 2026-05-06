extends CharacterBody3D

const SPEED: float = 4.0
const ATTACK_RANGE: float = 100.0
const DETECTION_RANGE: float = 25.0
const DAMAGE: float = 2.0


@export var stats: Stats
@export var bullet_scene: PackedScene = preload("res://Common/Projectiles/Bullets/bullet_enemy.tscn")
@export var fire_rate: float = 1.5

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")


var attack_locked: bool = false
var can_shoot: bool = true
var knockback_velocity: Vector3 = Vector3.ZERO
var player: RigidBody3D = null

func _ready() -> void:
	anim_tree.active = true
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.health_depleted.connect(_on_health_depleted)

	var players = get_tree().get_nodes_in_group("Player")
	print("Players encontrados:", players)
	if players.size() > 0:
		player = players[0] as RigidBody3D
		print("Enemy targeting:", player.name)


func _physics_process(delta: float) -> void:
	# Aplicar knockback si existe
	if knockback_velocity.length() > 0.1:
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 0.15)
		return

	if stats and stats.health <= 0:
		state_machine.travel("Death")
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not player or not is_instance_valid(player):
		return

	aim_at_player()
	var distance = global_position.distance_to(player.global_position)

	if distance <= ATTACK_RANGE:
		velocity = Vector3.ZERO
		move_and_slide()
		if state_machine.get_current_node() != "Attack":
			state_machine.travel("Attack")
		handle_attack()
	elif distance <= DETECTION_RANGE:
		nav_agent.set_target_position(player.global_position)
		var next_nav_point = nav_agent.get_next_path_position()
		velocity = (next_nav_point - global_position).normalized() * SPEED
		move_and_slide()
		if state_machine.get_current_node() != "Walk":
			state_machine.travel("Walk")
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		if state_machine.get_current_node() != "Idle":
			state_machine.travel("Idle")

func handle_attack() -> void:
	if not attack_locked:
		shoot_at_player()
		attack_locked = true
		await get_tree().create_timer(fire_rate).timeout
		if not is_inside_tree():
			return
		attack_locked = false
		print("bala")

func shoot_at_player() -> void:
	if not is_inside_tree():
		return
	if not can_shoot or not bullet_scene or not player:
		return
	if not is_instance_valid(player):
		return
	var bullet = bullet_scene.instantiate()
	print("bala")
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 1.5, 0)
	bullet.direction = (player.global_position - global_position).normalized()
	can_shoot = false
	var t = Timer.new()
	t.wait_time = fire_rate
	t.one_shot = true
	t.connect("timeout", Callable(self, "_reset_shoot"))
	add_child(t)
	t.start()

func _reset_shoot() -> void:
	can_shoot = true

func aim_at_player() -> void:
	var target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(target, Vector3.UP)
	rotation.y += PI

func apply_knockback(direccion: Vector3, fuerza: float) -> void:
	knockback_velocity = direccion * fuerza + Vector3.UP * fuerza * 0.4

func _on_health_changed(cur_health: int, max_health: int) -> void:
	print("Enemy HP:", cur_health, "/", max_health)

func _on_health_depleted() -> void:
	attack_locked = true
	state_machine.travel("Death")
	velocity = Vector3.ZERO
	move_and_slide()
	await get_tree().create_timer(3.5).timeout
	var scene = ItemPool.get_random_item()
	if scene:
		var item_instance = scene.instantiate()
		item_instance.global_position = global_position
		get_tree().current_scene.add_child(item_instance)
	queue_free()

func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - stats.current_defense)
		stats.health -= final_damage
		print("Enemy recibió daño:", final_damage, "HP restante:", stats.health)
