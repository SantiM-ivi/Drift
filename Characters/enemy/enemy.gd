extends CharacterBody3D

var player: Node3D
var attack_locked: bool = false

const SPEED: float = 5.0
const DETECTION_RANGE: float = 25.0
const ATTACK_RANGE: float = 10.0
const DAMAGE: float = 2.0

@export var player_path: NodePath
@export var stats: Stats

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	player = get_node(player_path)
	anim_tree.active = true
	set_conditions({"Idle": true, "Walk": false, "Attack": false, "Death": false})

	# Conectar señales del recurso Stats
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.health_depleted.connect(_on_health_depleted)

func _physics_process(delta: float) -> void:
	if stats and stats.health <= 0:
		set_conditions({"Idle": false, "Walk": false, "Attack": false, "Death": true})
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not player:
		return

	aim_at_player()
	var distance = global_position.distance_to(player.global_position)

	if distance <= ATTACK_RANGE:
		set_conditions({"Idle": false, "Walk": false, "Attack": true, "Death": false})
		velocity = Vector3.ZERO
		move_and_slide()
		handle_attack()
	elif distance <= DETECTION_RANGE:
		set_conditions({"Idle": false, "Walk": true, "Attack": false, "Death": false})
		chase_player(delta)
	else:
		set_conditions({"Idle": true, "Walk": false, "Attack": false, "Death": false})
		velocity = Vector3.ZERO
		move_and_slide()

func set_conditions(conditions: Dictionary) -> void:
	anim_tree.set("parameters/conditions/Idle", conditions.get("Idle", false))
	anim_tree.set("parameters/conditions/Walk", conditions.get("Walk", false))
	anim_tree.set("parameters/conditions/Attack", conditions.get("Attack", false))
	anim_tree.set("parameters/conditions/Death", conditions.get("Death", false))

func chase_player(delta: float) -> void:
	nav_agent.target_position = player.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	if next_nav_point != global_position:
		velocity = (next_nav_point - global_position).normalized() * SPEED
		move_and_slide()

func handle_attack() -> void:
	if not attack_locked:
		attack_player()
		attack_locked = true
		await get_tree().create_timer(0.5).timeout
		attack_locked = false

func attack_player() -> void:
	if player and player.has_method("apply_damage"):
		player.apply_damage(DAMAGE)

func aim_at_player():
	var target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(target, Vector3.UP)
	rotation.y += PI   # gira 180° en Y

# --- Señales de Stats ---
func _on_health_changed(cur_health: int, max_health: int) -> void:
	print("Enemy HP:", cur_health, "/", max_health)

func _on_health_depleted() -> void:
	set_conditions({"Idle": false, "Walk": false, "Attack": false, "Death": true})
	velocity = Vector3.ZERO
	move_and_slide()

	await get_tree().create_timer(3.5).timeout
	queue_free()


# --- Método para recibir daño desde la bala ---
func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - stats.current_defense)
		stats.health -= final_damage
		print("Enemy recibió daño:", final_damage, "HP restante:", stats.health)
