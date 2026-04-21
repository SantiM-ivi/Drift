class_name BaseState
extends RefCounted

var vehicle: VehicleBody3D  # referencia al nodo padre

func _init(v: VehicleBody3D) -> void:
	vehicle = v

func on_enter() -> void: pass
func on_exit() -> void: pass
func on_suspend() -> void: pass   # cuando otro estado se apila encima
func on_resume() -> void: pass    # cuando el estado de arriba se saca
func physics_process(_delta: float) -> void: pass
