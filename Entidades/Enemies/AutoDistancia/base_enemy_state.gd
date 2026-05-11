class_name BaseEnemyState
extends RefCounted

var enemy: VehicleBody3D
var sm: StateMachine

func _init(e: VehicleBody3D, s: StateMachine) -> void:
	enemy = e
	sm = s

func on_enter() -> void: pass
func on_exit() -> void: pass
func physics_process(_delta: float) -> void: pass
