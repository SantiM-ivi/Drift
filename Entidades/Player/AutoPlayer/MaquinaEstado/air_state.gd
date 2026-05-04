class_name AirState
extends BaseState

var _stack: StateStack

func _init(v: VehicleBody3D, stack: StateStack) -> void:
	super(v)
	_stack = stack

func physics_process(_delta: float) -> void:
	# Cancela la inercia X/Z heredada de la velocidad en tierra
	vehicle.cancelar_inercia_lateral(_delta)

	var auto_roll: float = vehicle.global_transform.basis.z.dot(Vector3.UP)
	vehicle.apply_torque(vehicle.global_transform.basis.z * -auto_roll * vehicle.aire_rotacion_fuerza * 0.1)

	vehicle.angular_velocity = vehicle.angular_velocity.clamp(
		Vector3(-1.5, -1.5, -1.5),
		Vector3( 1.5,  1.5,  1.5)
	)

	if vehicle._esta_en_suelo():
		_stack.pop()
