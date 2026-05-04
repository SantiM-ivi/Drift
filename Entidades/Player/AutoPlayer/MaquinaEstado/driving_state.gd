class_name DrivingState
extends BaseState

var _stack: StateStack

func _init(v: VehicleBody3D, stack: StateStack) -> void:
	super(v)
	_stack = stack

func on_enter() -> void:
	vehicle._set_agarre(vehicle.agarre_normal)

func physics_process(delta: float) -> void:
	_handle_acceleration()
	_handle_steering(delta)
	_handle_jump()
	_limit_speed()
	_check_transitions()

# ============================================================
# ACELERACIÓN
# ============================================================

func _handle_acceleration() -> void:
	var fuerza: float = 0.0

	if Input.is_action_pressed("forward"):
		fuerza = vehicle.engine_force_value
	elif Input.is_action_pressed("backward"):
		fuerza = -vehicle.engine_force_value * 0.6

	vehicle.rueda_bl.engine_force = fuerza
	vehicle.rueda_br.engine_force = fuerza

# ============================================================
# DIRECCIÓN
# ============================================================

func _handle_steering(delta: float) -> void:
	var speed: float  = vehicle.linear_velocity.length()
	var limit: float  = lerp(vehicle.steer_limit, vehicle.steer_limit * 0.75, clampf(speed / 25.0, 0.0, 1.0))
	var dir: float    = Input.get_action_strength("left") - Input.get_action_strength("right")
	var target: float = clampf(dir, -limit, limit)

	if dir == 0.0:
		vehicle.steer_actual = move_toward(vehicle.steer_actual, 0.0, vehicle.steer_return * delta)
	else:
		vehicle.steer_actual = move_toward(vehicle.steer_actual, target, vehicle.steer_speed * delta)

	vehicle.rueda_tl.steering = vehicle.steer_actual
	vehicle.rueda_tr.steering = vehicle.steer_actual

# ============================================================
# SALTO
# ============================================================

func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump") or not vehicle._esta_en_suelo():
		return

	vehicle.apply_central_impulse(Vector3.UP * vehicle.jump_force * vehicle.mass)
	vehicle.angular_velocity.x = lerp(vehicle.angular_velocity.x, 0.0, 0.5)
	vehicle.angular_velocity.z = lerp(vehicle.angular_velocity.z, 0.0, 0.5)

# ============================================================
# LÍMITE DE VELOCIDAD
# ============================================================

func _limit_speed() -> void:
	var vel: float = vehicle.linear_velocity.length()
	if vel > vehicle.velocidad_maxima:
		vehicle.linear_velocity = vehicle.linear_velocity.normalized() * vehicle.velocidad_maxima

# ============================================================
# TRANSICIONES
# ============================================================

func _check_transitions() -> void:
	if Input.is_action_pressed("ui_select"):
		_stack.push(DriftState.new(vehicle, _stack))
	elif not vehicle._esta_en_suelo():
		_stack.push(AirState.new(vehicle, _stack))
