extends VehicleBody3D

@export_group("Movimiento")
@export var engine_force_value: float = 600.0
@export var velocidad_base: float = 600.0
@export var steer_limit: float = 0.8
@export var steer_speed: float = 2.0
@export var steer_return: float = 10.0
@export var jump_force: float = 10.0
@export var freno_fuerza: float = 50.0

@export_group("Mecánicas Turbo y Vuelo")
@export var turbo_fuerza: float = 1500.0
@export var aire_rotacion_fuerza: float = 500.0
@export var agarre_normal: float = 5.0
@export var agarre_derrape: float = 0.1
@export var turbo_duracion: float = 1.0      # segundos de uso máximo
@export var turbo_recarga: float = 5.0       # segundos para recargar

var _turbo_carga: float = 1.0  # 0.0 a 1.0 (1.0 = lleno)
var _turbo_en_uso: bool = false

@export_group("Referencias")
@export var stats: Stats

@onready var equipment: PlayerEquipment = $PlayerEquipment
@onready var pickup_area: Area3D = $AreaDeInteraccion

var items_en_rango: Array[ItemMundo] = []
var steer_actual: float = 0.0
var _nitro_activo: bool = false

func _ready() -> void:
	if equipment:
		equipment.inicializar(stats, velocidad_base)
	_set_agarre(agarre_normal)
	pickup_area.area_entered.connect(_on_area_entered)
	pickup_area.area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	center_of_mass = Vector3(0, -0.2, 0)

func _physics_process(delta: float) -> void:
	_mover(delta)
	_intentar_recoger()
	_manejar_turbo_y_vuelo(delta)

func _mover(delta: float) -> void:
	var velocidad = linear_velocity.length()
	var en_suelo = _esta_en_suelo()

	if Input.is_action_pressed("forward"):
		$left_back.engine_force  = engine_force_value
		$right_back.engine_force = engine_force_value
	elif Input.is_action_pressed("backward"):
		$left_back.engine_force  = -engine_force_value * 0.6
		$right_back.engine_force = -engine_force_value * 0.6
	else:
		$left_back.engine_force  = 0
		$right_back.engine_force = 0

	var steer_limit_actual = lerp(steer_limit, steer_limit * 0.75, clamp(velocidad / 25.0, 0.0, 1.0))
	var dir = Input.get_action_strength("left") - Input.get_action_strength("right")
	var target = clamp(dir, -steer_limit_actual, steer_limit_actual)

	if dir == 0.0:
		steer_actual = move_toward(steer_actual, 0.0, steer_return * delta)
	else:
		steer_actual = move_toward(steer_actual, target, steer_speed * delta)

	$left_front.steering  = steer_actual
	$right_front.steering = steer_actual

	if Input.is_action_pressed("ui_select"):
		$left_back.brake  = freno_fuerza
		$right_back.brake = freno_fuerza
		$left_back.wheel_friction_slip  = agarre_derrape
		$right_back.wheel_friction_slip = agarre_derrape
		if en_suelo and abs(steer_actual) > 0.1:
			apply_torque(Vector3.UP * steer_actual * 800.0)
	else:
		$left_back.brake  = 0.0
		$right_back.brake = 0.0
		if en_suelo:
			_set_agarre(agarre_normal)

	if Input.is_action_just_pressed("jump") and en_suelo:
		apply_central_impulse(Vector3.UP * jump_force * mass)
		angular_velocity.x = lerp(angular_velocity.x, 0.0, 0.5)
		angular_velocity.z = lerp(angular_velocity.z, 0.0, 0.5)

func _manejar_turbo_y_vuelo(delta: float) -> void:
	var en_suelo = _esta_en_suelo()

	# Turbo con límite de tiempo
	if Input.is_action_pressed("turbo") and _turbo_carga > 0.0:
		var direccion_frente = -global_transform.basis.z
		apply_central_force(direccion_frente * turbo_fuerza)
		_turbo_en_uso = true
		# Gastar carga
		_turbo_carga -= delta / turbo_duracion
		_turbo_carga = max(_turbo_carga, 0.0)
	else:
		_turbo_en_uso = false
		# Recargar cuando no se usa
		if _turbo_carga < 1.0:
			_turbo_carga += delta / turbo_recarga
			_turbo_carga = min(_turbo_carga, 1.0)

	if not en_suelo:
		var pitch = Input.get_action_strength("forward") - Input.get_action_strength("backward")
		var roll = Input.get_action_strength("left") - Input.get_action_strength("right")
		apply_torque(global_transform.basis.x * pitch * aire_rotacion_fuerza)
		apply_torque(global_transform.basis.y * roll * aire_rotacion_fuerza)
		var auto_roll = global_transform.basis.z.dot(Vector3.UP)
		apply_torque(global_transform.basis.z * -auto_roll * aire_rotacion_fuerza * 0.5)

func _esta_en_suelo() -> bool:
	return $left_back.is_in_contact() or $right_back.is_in_contact() or $left_front.is_in_contact() or $right_front.is_in_contact()

func _set_agarre(valor: float) -> void:
	$left_back.wheel_friction_slip   = valor
	$right_back.wheel_friction_slip  = valor
	$left_front.wheel_friction_slip  = valor
	$right_front.wheel_friction_slip = valor

func _intentar_recoger() -> void:
	if not Input.is_action_just_pressed("Tecla E"):
		return
	if items_en_rango.is_empty():
		return

	var closest: ItemMundo = null
	var min_dist: float = INF
	for item in items_en_rango:
		if not is_instance_valid(item):
			continue
		var d = global_position.distance_to(item.global_position)
		if d < min_dist:
			min_dist = d
			closest = item

	if closest == null:
		return

	equipment.equipar(closest.slot, closest.nombre_item, global_position, closest.stats)
	items_en_rango.erase(closest)
	closest.queue_free()

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if not parent is ItemMundo:
		return
	if parent.stats != null and parent.stats.tipo != ItemsStats.TipoItem.EQUIPABLE:
		equipment.equipar(parent.slot, parent.nombre_item, global_position, parent.stats)
		parent.queue_free()
	else:
		items_en_rango.append(parent)

func _on_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is ItemMundo and is_instance_valid(parent):
		items_en_rango.erase(parent)

func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - int(stats.current_defense))
		stats.health -= final_damage
		if stats.health <= 0:
			print("Jugador muerto")

func activar_nitro(duracion: float, multiplicador: float) -> void:
	if _nitro_activo:
		return
	_nitro_activo = true
	engine_force_value *= multiplicador
	turbo_fuerza *= multiplicador
	print("Nitro activado! fuerza: %.0f por %.1fs" % [engine_force_value, duracion])
	await get_tree().create_timer(duracion).timeout
	engine_force_value = velocidad_base
	turbo_fuerza /= multiplicador
	_nitro_activo = false
	print("Nitro terminado")

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage") and stats:
		var velocidad = linear_velocity.length()
		if velocidad > 5.0:
			var dano_choque = int(stats.current_ram_damage * (velocidad / 20.0))
			body.apply_damage(dano_choque)
			if body.has_method("apply_knockback"):
				var direccion = (body.global_position - global_position).normalized()
				var fuerza = velocidad * 8.0
				$CrashSFX.play()
				body.apply_knockback(direccion, fuerza)
			print("Choque! velocidad: %.1f | daño: %d" % [velocidad, dano_choque])
