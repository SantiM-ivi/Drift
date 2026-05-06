extends Camera3D
@export var follow_target: RigidBody3D
@export var distance: float = 5.0
@export var height: float = 3.0
@export var sensitivity: float = 0.01
@export var joystick_sensitivity: float = 2.0  # velocidad del stick
var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, -1.0, 1.0)

func _process(delta: float) -> void:
	# Input del stick derecho
	var stick_x = Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
	var stick_y = Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
	yaw -= stick_x * joystick_sensitivity * delta
	pitch -= stick_y * joystick_sensitivity * delta
	pitch = clamp(pitch, -1.0, 1.0)

	if not follow_target:
		return

	var offset = Vector3(
		sin(yaw) * distance,
		height,
		cos(yaw) * distance
	)
	global_position = follow_target.global_position + offset
	look_at(follow_target.global_position, Vector3.UP)
	rotation.x += pitch
