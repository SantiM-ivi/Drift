extends Camera3D

@export var follow_target: VehicleBody3D
@export var distance: float = 5.0
@export var height: float = 3.0
@export var sensitivity: float = 0.01

var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, -1.0, 1.0) # limitar ángulo vertical

func _process(delta: float) -> void:
	if not follow_target:
		return
	
	# Posición detrás del auto
	var offset = Vector3(
		sin(yaw) * distance,
		height,
		cos(yaw) * distance
	)
	global_position = follow_target.global_position + offset
	
	# Mirar al auto pero aplicando pitch
	look_at(follow_target.global_position, Vector3.UP)
	rotation.x += pitch
