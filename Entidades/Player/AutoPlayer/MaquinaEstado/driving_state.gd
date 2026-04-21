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
	_check_transitions()

func _handle_acceleration() -> void:
	if Input.is_action_pressed("forward"):
		vehicle.get_node("left_back").engine_force  = vehicle.engine_force_value
		vehicle.get_node("right_back").engine_force = vehicle.engine_force_value
	elif Input.is_action_pressed("backward"):
		vehicle.get_node("left_back").engine_force  = -vehicle.engine_force_value * 0.6
		vehicle.get_node("right_back").engine_force = -vehicle.engine_force_value * 0.6
	else:
		vehicle.get_node("left_back").engine_force  = 0
		vehicle.get_node("right_back").engine_force = 0

func _handle_steering(delta: float) -> void:
	var speed = vehicle.linear_velocity.length()
	var limit = lerp(vehicle.steer_limit, vehicle.steer_limit * 0.75, clamp(speed / 25.0, 0.0, 1.0))
	var dir = Input.get_action_strength("left") - Input.get_action_strength("right")
	var target = clamp(dir, -limit, limit)

	if dir == 0.0:
		vehicle.steer_actual = move_toward(vehicle.steer_actual, 0.0, vehicle.steer_return * delta)
	else:
		vehicle.steer_actual = move_toward(vehicle.steer_actual, target, vehicle.steer_speed * delta)

	vehicle.get_node("left_front").steering  = vehicle.steer_actual
	vehicle.get_node("right_front").steering = vehicle.steer_actual

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and vehicle._esta_en_suelo():
		vehicle.apply_central_impulse(Vector3.UP * vehicle.jump_force * vehicle.mass)
		vehicle.angular_velocity.x = lerp(vehicle.angular_velocity.x, 0.0, 0.5)
		vehicle.angular_velocity.z = lerp(vehicle.angular_velocity.z, 0.0, 0.5)

func _check_transitions() -> void:
	if Input.is_action_pressed("ui_select"):
		_stack.push(DriftState.new(vehicle, _stack))
	elif not vehicle._esta_en_suelo():
		_stack.push(AirState.new(vehicle, _stack))
