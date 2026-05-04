class_name DriftState
extends BaseState

var _stack: StateStack

func _init(v: VehicleBody3D, stack: StateStack) -> void:
	super(v)
	_stack = stack

func on_enter() -> void:
	vehicle.rueda_bl.brake = vehicle.freno_fuerza
	vehicle.rueda_br.brake = vehicle.freno_fuerza
	vehicle._set_agarre(vehicle.agarre_derrape)

func on_exit() -> void:
	vehicle.rueda_bl.brake = 0.0
	vehicle.rueda_br.brake = 0.0
	vehicle._set_agarre(vehicle.agarre_normal)

func physics_process(delta: float) -> void:
	_aplicar_torque_drift(delta)

	if not Input.is_action_pressed("ui_select"):
		_stack.pop()

func _aplicar_torque_drift(delta: float) -> void:
	if abs(vehicle.steer_actual) <= 0.1:
		return
	var torque_fuerza: float = vehicle.steer_actual * vehicle.freno_fuerza * 16.0
	vehicle.apply_torque(Vector3.UP * torque_fuerza * delta)
