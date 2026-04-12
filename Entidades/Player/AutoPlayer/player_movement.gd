extends VehicleBody3D

@export var engine_force_value: float = 800.0   # más potencia
@export var steer_limit: float = 3.0            # más ángulo de giro
@export var steer_speed: float = 4.0            # giro más responsivo
@export var steer_return: float = 6.0           # vuelve al centro rápido
@export var jump_force: float = 10.0
@export var freno_fuerza: float = 15.0
@export var agarre_normal: float = 3.5          # fricción lateral normal
@export var agarre_derrape: float = 0.1 # fricción al frenar/derrapar

@onready var equipment: PlayerEquipment = $PlayerEquipment
@onready var pickup_area: Area3D = $AreaDeInteraccion

var items_en_rango: Array[ItemMundo] = []
var steer_actual: float = 0.0

func _ready() -> void:
	# Agarre inicial de todas las ruedas
	_set_agarre(agarre_normal)
	pickup_area.area_entered.connect(_on_area_entered)
	pickup_area.area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	_mover(delta)
	_intentar_recoger()

func _mover(delta: float) -> void:
	var velocidad = linear_velocity.length()

	# Motor
	if Input.is_action_pressed("forward"):
		$left_back.engine_force  = engine_force_value
		$right_back.engine_force = engine_force_value
	elif Input.is_action_pressed("backward"):
		$left_back.engine_force  = -engine_force_value * 0.6
		$right_back.engine_force = -engine_force_value * 0.6
	else:
		$left_back.engine_force  = 0
		$right_back.engine_force = 0

	# Giro arcade — el límite baja a alta velocidad para estabilidad
	var steer_limit_actual = lerp(steer_limit, steer_limit * 0.5, clamp(velocidad / 20.0, 0.0, 1.0))
	var dir = Input.get_action_strength("left") - Input.get_action_strength("right")
	var target = clamp(dir, -steer_limit_actual, steer_limit_actual)

	# Si no hay input, vuelve al centro más rápido
	if dir == 0.0:
		steer_actual = move_toward(steer_actual, 0.0, steer_return * delta)
	else:
		steer_actual = move_toward(steer_actual, target, steer_speed * delta)

	$left_front.steering  = steer_actual
	$right_front.steering = steer_actual

	# Freno con derrape
	if Input.is_action_pressed("ui_select"):
		$left_back.brake  = freno_fuerza
		$right_back.brake = freno_fuerza
		$left_back.wheel_friction_slip  = agarre_derrape
		$right_back.wheel_friction_slip = agarre_derrape
		$left_front.wheel_friction_slip  = agarre_normal
		$right_front.wheel_friction_slip = agarre_normal
		
		# Empujón de rotación en la dirección del giro
		if abs(steer_actual) > 0.1:
			apply_torque(Vector3.UP * steer_actual * 800.0)
	else:
		$left_back.brake  = 0.0
		$right_back.brake = 0.0
		_set_agarre(agarre_normal)

	# Salto
	if Input.is_action_just_pressed("jump"):
		var en_suelo = $left_back.is_in_contact() or $right_back.is_in_contact()
		if en_suelo:
			apply_central_impulse(Vector3.UP * jump_force * mass)
			# Anti-roll — contrarresta el tambaleo
			var vel_angular = angular_velocity
			angular_velocity = Vector3(
				lerp(vel_angular.x, 0.0, 0.15),  # estabiliza pitch
				vel_angular.y,                     # deja el yaw libre (giro normal)
				lerp(vel_angular.z, 0.0, 0.15)   # estabiliza roll
			)



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

	equipment.equipar(closest.slot, closest.nombre_item, global_position)
	items_en_rango.erase(closest)
	closest.queue_free()

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is ItemMundo:
		items_en_rango.append(parent)

func _on_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is ItemMundo:
		items_en_rango.erase(parent)
