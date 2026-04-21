class_name DriftState
extends BaseState

var _stack: StateStack

func _init(v: VehicleBody3D, stack: StateStack) -> void:
	super(v)
	_stack = stack

func on_enter() -> void:
	vehicle.get_node("left_back").brake  = vehicle.freno_fuerza
	vehicle.get_node("right_back").brake = vehicle.freno_fuerza
	vehicle._set_agarre(vehicle.agarre_derrape)

func on_exit() -> void:
	vehicle.get_node("left_back").brake  = 0.0
	vehicle.get_node("right_back").brake = 0.0
	vehicle._set_agarre(vehicle.agarre_normal)

func physics_process(_delta: float) -> void:
	if abs(vehicle.steer_actual) > 0.1:
		vehicle.apply_torque(Vector3.UP * vehicle.steer_actual * 800.0)

	if not Input.is_action_pressed("ui_select"):
		_stack.pop()  # vuelve a DrivingState
