extends Node

@onready var jugador: VehicleBody3D = %Jugador
var init_transform: Transform3D

func _ready():
	if jugador:
		init_transform = jugador.transform
		print("init transform %s " % init_transform)
	else:
		push_error("Jugador no encontrado, revisá la ruta del nodo.")

func _input(event):
	if event.is_action_pressed("ui_cancel") and jugador:
		PhysicsServer3D.body_set_state(
			jugador.get_rid(),
			PhysicsServer3D.BODY_STATE_TRANSFORM,
			init_transform
		)
		jugador.linear_velocity = Vector3.ZERO
		jugador.angular_velocity = Vector3.ZERO
