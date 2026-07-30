class_name AutoEnemigo
extends VehicleBody3D
@onready var sm: StateMachine = $StateMachine
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var shoot_point: Node3D = $ShootPoint
@export var stats: Stats
@export var explosion_scene: PackedScene = preload("res://Common/Effects/explosion_one.tscn")
@export var impacto_scene: PackedScene
var proyectil_scene: PackedScene = preload("res://Common/Projectiles/Bullets/bullet_enemy.tscn")
signal enemigo_muerto(enemigo: AutoEnemigo)
var player: RigidBody3D = null

# ─── AUDIO ───────────────────────────────────────────────────────────────────
@onready var disparo_sfx: AudioStreamPlayer3D = $DisparoSFX
@onready var golpe_sfx: AudioStreamPlayer3D   = $GolpeSFX
@onready var motor_sfx: AudioStreamPlayer3D   = $MotorSFX

@export_group("Audio - Disparo")
@export var disparo_sonidos: Array[AudioStream] = []
@export var disparo_pitch_min: float = 0.9
@export var disparo_pitch_max: float = 1.1

@export_group("Audio - Golpe")
@export var golpe_sonidos: Array[AudioStream] = []
@export var golpe_pitch_min: float = 0.85
@export var golpe_pitch_max: float = 1.15

@export_group("Audio - Motor")
@export var motor_pitch_min: float = 0.8
@export var motor_pitch_max: float = 1.6
@export var motor_velocidad_umbral: float = 0.5

# ─── ATASCO / RETROCESO ─────────────────────────────────────────────────────
@export_group("Atasco")
@export var atasco_velocidad_umbral: float = 1.0
@export var atasco_tiempo_umbral: float = 1.0
@export var retroceso_duracion: float = 1.0
@export var retroceso_fuerza: float = -800.0
@export var retroceso_steering: float = 0.5

# ─── PERSECUCIÓN ─────────────────────────────────────────────────────────────
@export_group("Persecución")
@export var torque_giro: float = 1200.0
@export var amortiguacion_giro: float = 900.0

var _tiempo_atascado: float = 0.0
var _retrocediendo: bool = false
var _tiempo_retroceso: float = 0.0
var _retroceso_steering_dir: float = 1.0

func _ready() -> void:
	center_of_mass = Vector3(0, -1.0, 0)
	mass = 100.0          # más pesado = más estable
	angular_damp = 5.0
	attack_area.body_entered.connect(_on_attack_entered)
	attack_area.body_exited.connect(_on_attack_exited)
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.health_depleted.connect(_on_health_depleted)
	# Siempre sabe dónde estás desde que nace, sin esperar a detectarte.
	player = get_tree().get_first_node_in_group("Player")
	sm.transition_to(ChaseState.new(self, sm))
func _physics_process(delta: float) -> void:
	sm.physics_process(delta)
	_auto_enderezar(delta)
	_manejar_atasco(delta)
	_actualizar_motor_sfx()
func _on_attack_entered(body: Node) -> void:
	if body == player and body.is_in_group("Player"):
		sm.transition_to(AttackState.new(self, sm))
func _on_attack_exited(body: Node) -> void:
	if body == player and body.is_in_group("Player"):
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

# ── Si lleva atascado (casi sin moverse mientras persigue) retrocede y gira ──
func _manejar_atasco(delta: float) -> void:
	if _retrocediendo:
		_tiempo_retroceso -= delta
		var steer = retroceso_steering * _retroceso_steering_dir
		get_node("left_front").steering  = steer
		get_node("right_front").steering = steer
		get_node("left_back").engine_force  = retroceso_fuerza
		get_node("right_back").engine_force = retroceso_fuerza
		if _tiempo_retroceso <= 0.0:
			_retrocediendo = false
			_tiempo_atascado = 0.0
		return

	# Solo chequeamos atasco si el enemigo está activamente tratando de moverse
	if player == null:
		_tiempo_atascado = 0.0
		return

	if linear_velocity.length() < atasco_velocidad_umbral:
		_tiempo_atascado += delta
	else:
		_tiempo_atascado = 0.0

	if _tiempo_atascado >= atasco_tiempo_umbral:
		_iniciar_retroceso()

func _iniciar_retroceso() -> void:
	_retrocediendo = true
	_tiempo_retroceso = retroceso_duracion
	_retroceso_steering_dir = 1.0 if randf() < 0.5 else -1.0
	print("[AutoEnemigo] Atascado — retrocediendo")

# ── Rota el auto directo hacia una dirección, sin depender solo de las ruedas ──
# Llamar desde ChaseState/AttackState con la dirección deseada (al player o al
# próximo punto del path). Se suma al steering de las ruedas, no lo reemplaza.
func aplicar_giro_directo(direccion_deseada: Vector3) -> void:
	var frente_actual = Vector3(-global_basis.z.x, 0.0, -global_basis.z.z).normalized()
	var objetivo = Vector3(direccion_deseada.x, 0.0, direccion_deseada.z).normalized()
	if objetivo.length_squared() < 0.0001:
		return
	var diferencia = frente_actual.signed_angle_to(objetivo, Vector3.UP)
	var torque = clamp(diferencia * torque_giro - angular_velocity.y * amortiguacion_giro, -torque_giro, torque_giro)
	apply_torque(Vector3.UP * torque)

# ─── AUDIO ───────────────────────────────────────────────────────────────────

# ── Llamar desde AttackState al instanciar el proyectil ───────────────────────
func reproducir_disparo() -> void:
	_reproducir_random(disparo_sfx, disparo_sonidos, disparo_pitch_min, disparo_pitch_max)

func _reproducir_golpe() -> void:
	_reproducir_random(golpe_sfx, golpe_sonidos, golpe_pitch_min, golpe_pitch_max)

func _reproducir_random(player_sfx: AudioStreamPlayer3D, sonidos: Array[AudioStream], pitch_min: float, pitch_max: float) -> void:
	if not player_sfx or sonidos.is_empty():
		return
	player_sfx.stream = sonidos[randi() % sonidos.size()]
	player_sfx.pitch_scale = randf_range(pitch_min, pitch_max)
	player_sfx.play()

func _actualizar_motor_sfx() -> void:
	if not motor_sfx:
		return
	var velocidad = linear_velocity.length()
	var moviendose = velocidad > motor_velocidad_umbral

	if moviendose and not motor_sfx.playing:
		motor_sfx.play()
	elif not moviendose and motor_sfx.playing:
		motor_sfx.stop()

	if moviendose:
		var vel_max = stats.current_speed if stats else 20.0
		var ratio = clamp(velocidad / vel_max, 0.0, 1.0)
		motor_sfx.pitch_scale = lerp(motor_pitch_min, motor_pitch_max, ratio)

func _on_health_changed(cur_health: int, max_health: int) -> void:
	print("Enemy HP:", cur_health, "/", max_health)
func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - stats.current_defense)
		stats.health -= final_damage
		GameStats.dano_hecho += final_damage
		_reproducir_golpe()
		_spawnear_impacto()
		print("Enemy recibió daño:", final_damage, "HP restante:", stats.health)
func _on_health_depleted() -> void:
	emit_signal("enemigo_muerto", self)
	_spawnear_explosion()
	var scene = ItemPool.get_random_item()
	if scene:
		var item_instance = scene.instantiate()
		item_instance.global_position = global_position
		get_tree().current_scene.add_child(item_instance)
	queue_free()
func _spawnear_explosion() -> void:
	if not explosion_scene:
		push_error("[AutoEnemigo] No hay explosion_scene asignada")
		return
	var explosion: Node3D = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	explosion.explode()

func _spawnear_impacto() -> void:
	if not impacto_scene:
		return
	var impacto: Node3D = impacto_scene.instantiate()
	get_tree().current_scene.add_child(impacto)
	impacto.global_position = global_position
	if impacto.has_method("explode"):
		impacto.explode()
func apply_knockback(direccion: Vector3, fuerza: float) -> void:
	linear_velocity += direccion * fuerza
func activar_modo_caza() -> void:
	for hijo in detection_area.get_children():
		if hijo is CollisionShape3D and hijo.shape is SphereShape3D:
			# Duplicamos el shape para no pisar el radio de otras instancias
			# que puedan estar compartiendo el mismo recurso.
			hijo.shape = hijo.shape.duplicate()
			hijo.shape.radius *= 2.5
			print("[Enemigo] Modo caza activado — radio ampliado")
			return
	push_warning("[AutoEnemigo] No se encontró CollisionShape3D con SphereShape3D en DetectionArea")
