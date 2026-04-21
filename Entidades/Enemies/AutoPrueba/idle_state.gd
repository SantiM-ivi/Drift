class_name IdleState
extends BaseEnemyState

func _init(e: VehicleBody3D, s: StateMachine) -> void:
	super(e, s)

func physics_process(_delta: float) -> void:
	# Frenar el auto
	enemy.get_node("left_back").engine_force  = 0
	enemy.get_node("right_back").engine_force = 0
	enemy.get_node("left_back").brake  = 10.0
	enemy.get_node("right_back").brake = 10.0
