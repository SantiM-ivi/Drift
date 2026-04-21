class_name TurboComponent
extends Node

@export var data: TurboResource

var carga: float = 1.0

func tick(delta: float, vehicle: VehicleBody3D) -> void:
	if Input.is_action_pressed("turbo") and carga > 0.0:
		var dir = -vehicle.global_transform.basis.z
		vehicle.apply_central_force(dir * data.turbo_force)
		carga -= delta / data.duration
		carga = maxf(carga, 0.0)
	else:
		carga += delta / data.cooldown
		carga = minf(carga, 1.0)
