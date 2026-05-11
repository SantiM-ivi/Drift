class_name StateMachine
extends Node

var current_state: BaseEnemyState

func transition_to(new_state: BaseEnemyState) -> void:
	if current_state:
		current_state.on_exit()
	current_state = new_state
	current_state.on_enter()

func physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)
