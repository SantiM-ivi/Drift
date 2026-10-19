class_name AutoEnemigo
extends VehicleBody3D
# ─── EFECTO DE APARICIÓN ─────────────────────────────────────────────────────
@export_group("Aparición")
@export var tiempo_aparicion: float = 1.5 # Segundos que tarda en hacerse visible
@export var humo_spawn_scene: PackedScene # Aquí puedes poner tu escena de humo
var _esta_apareciendo: bool = true # Bloquea la IA mientras aparece

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
@export var atasco_tiempo_umbral: float = 0.8
@export var retroceso_duracion: float = 0.8
@export var retroceso_fuerza: float = -1200.0
@export var retroceso_steering: float = 0.6

# ─── PERSECUCIÓN / EMBESTIDA ─────────────────────────────────────────────────
@export_group("Persecución")
@export var torque_giro: float = 8000.0
@export var amortiguacion_giro: float = 150.0
@export var fuerza_motor: float = 2500.0

# ─── REBOTE CONTRA PAREDES Y OTROS ENEMIGOS ──────────────────────────────────
@export_group("Rebote")
@export var duracion_aturdimiento: float = 0.3
@export var fuerza_rebote_enemigos: float = 30.0
const LAYER_PAREDES: int = 1 << 7  # Layer 8 en el editor (1-indexed)

var _tiempo_atascado: float = 0.0
var _retrocediendo: bool = false
var _tiempo_retroceso: float = 0.0
var _retroceso_steering_dir: float = 1.0
var _tiempo_aturdido: float = 0.0

func _ready() -> void:
	center_of_mass = Vector3(0, -1.0, 0)
	mass = 100.0
	angular_damp = 1.0
	attack_area.body_entered.connect(_on_attack_entered)
	attack_area.body_exited.connect(_on_attack_exited)
	body_entered.connect(_on_body_entered)
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.health_depleted.connect(_on_health_depleted)
		
	_buscar_jugador()
	
	# NUEVO: Iniciamos el efecto de aparición antes de empezar a perseguir
	_iniciar_aparicion()
	
	sm.transition_to(ChaseState.new(self, sm))

# --- NUEVAS FUNCIONES DE APARICIÓN ---

func _iniciar_aparicion() -> void:
	_esta_apareciendo = true
	
	# 1. Instanciar la bomba de humo si tienes una asignada
	if humo_spawn_scene:
		var humo = humo_spawn_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", humo)
		humo.global_position = global_position
		# Si tu humo tiene un método explode() o emit(), llámalo aquí.

	# 2. Buscar todas las mallas (MeshInstance3D) del auto
	var meshes = _obtener_todas_las_mallas(self)
	
	# 3. Crear un Tween para animar la transparencia
	var tween = create_tween()
	tween.set_parallel(true) # Anima todas las piezas al mismo tiempo
	
	for mesh in meshes:
		mesh.transparency = 1.0 # 1.0 = Totalmente invisible al inicio
		# Animamos de 1.0 a 0.0 (opaco)
		tween.tween_property(mesh, "transparency", 0.0, tiempo_aparicion)
		
	# Cuando termina la animación, habilitamos la IA
	tween.chain().tween_callback(func(): _esta_apareciendo = false)

# Función recursiva para encontrar la carrocería, ruedas, etc. (todo lo que sea Mesh)
func _obtener_todas_las_mallas(nodo: Node) -> Array[MeshInstance3D]:
	var lista: Array[MeshInstance3D] = []
	for hijo in nodo.get_children():
		if hijo is MeshInstance3D:
			lista.append(hijo)
		# Buscar dentro de los hijos de los hijos (por si las ruedas están anidadas)
		lista.append_array(_obtener_todas_las_mallas(hijo))
	return lista

func _buscar_jugador() -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as RigidBody3D

func _physics_process(delta: float) -> void:
	# NUEVO: Si está apareciendo, no hacemos nada y frenamos
	if _esta_apareciendo:
		get_node("left_back").engine_force = 0
		get_node("right_back").engine_force = 0
		get_node("left_back").brake = 10.0
		get_node("right_back").brake = 10.0
		return
	else:
		# Soltar el freno cuando ya apareció
		get_node("left_back").brake = 0.0
		get_node("right_back").brake = 0.0

	_buscar_jugador()
	
	if player and is_instance_valid(player) and nav:
		nav.target_position = player.global_position

	if _tiempo_aturdido > 0.0:
		_tiempo_aturdido -= delta
	else:
		sm.physics_process(delta)
		_manejar_atasco(delta)
	_auto_enderezar(delta)
	_actualizar_motor_sfx()

func _on_attack_entered(body: Node) -> void:
	if body == player and body.is_in_group("Player"):
		sm.transition_to(AttackState.new(self, sm))

func _on_attack_exited(body: Node) -> void:
	if body == player and body.is_in_group("Player"):
		sm.transition_to(ChaseState.new(self, sm))

func _on_body_entered(body: Node) -> void:
	# Rebote entre enemigos (AutoEnemigo)
	if body is AutoEnemigo:
		var direccion_empuje = (global_position - body.global_position)
		direccion_empuje.y = 0.0 # CRÍTICO: 0 para no volcar los coches
		
		if direccion_empuje.length_squared() < 0.001:
			# Si están exactamente en el mismo punto (raro pero posible), empuje aleatorio horizontal
			direccion_empuje = Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
		else:
			direccion_empuje = direccion_empuje.normalized()

		# Aplicamos un impulso más controlado y corto
		apply_central_impulse(direccion_empuje * (fuerza_rebote_enemigos * 0.5) * mass)
		return

	# Rebote contra paredes (layer 8)
	var velocidad := linear_velocity.length()
	if velocidad <= 5.0:
		return
	if body.collision_layer & LAYER_PAREDES == 0:
		return

	var direccion_rebote = -linear_velocity.normalized()
	direccion_rebote.y = 0.0
	direccion_rebote = direccion_rebote.normalized()

	linear_velocity = Vector3.ZERO
	_tiempo_aturdido = duracion_aturdimiento
	var fuerza_rebote = clamp(velocidad * 2.0, 15.0, 60.0)
	apply_central_impulse(direccion_rebote * fuerza_rebote * mass)

func _auto_enderezar(delta: float) -> void:
	var up_local = global_transform.basis.y
	var dot = up_local.dot(Vector3.UP)
	
	if dot < 0.5:
		var correction = up_local.cross(Vector3.UP)
		apply_torque(correction * 10000.0)
		angular_velocity = angular_velocity.lerp(Vector3.ZERO, 0.1)

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

func aplicar_giro_directo(direccion_deseada: Vector3) -> void:
	if _retrocediendo:
		return

	var frente_actual = Vector3(-global_basis.z.x, 0.0, -global_basis.z.z).normalized()
	var objetivo = Vector3(direccion_deseada.x, 0.0, direccion_deseada.z).normalized()
	if objetivo.length_squared() < 0.0001:
		return

	var diferencia = frente_actual.signed_angle_to(objetivo, Vector3.UP)
	var torque = clamp(diferencia * torque_giro - angular_velocity.y * amortiguacion_giro, -torque_giro, torque_giro)
	apply_torque(Vector3.UP * torque)

	var steer_angle = clamp(diferencia, -0.6, 0.6)
	get_node("left_front").steering = steer_angle
	get_node("right_front").steering = steer_angle

	var alineado = frente_actual.dot(objetivo)
	var motor = stats.current_speed if stats else fuerza_motor
	
	# CONDUCCIÓN AGRESIVA: Solo frenan si el giro es extremadamente cerrado
	if alineado > 0.7:
		# Si van en recta hacia el objetivo, ganan un 20% extra de velocidad
		get_node("left_back").engine_force = motor * 1.2
		get_node("right_back").engine_force = motor * 1.2
	elif alineado > -0.2:
		# En curvas normales, apenas pierden velocidad (90%)
		get_node("left_back").engine_force = motor * 0.9
		get_node("right_back").engine_force = motor * 0.9
	else:
		# Curvas muy bruscas, derrapan pero mantienen fuerza (60%)
		get_node("left_back").engine_force = motor * 0.6
		get_node("right_back").engine_force = motor * 0.6

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
			hijo.shape = hijo.shape.duplicate()
			hijo.shape.radius *= 2.5
			print("[Enemigo] Modo caza activado — radio ampliado")
			return
	push_warning("[AutoEnemigo] No se encontró CollisionShape3D con SphereShape3D en DetectionArea")
