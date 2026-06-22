extends Node3D

@onready var debris = $Debris
@onready var smoke = $Smoke
@onready var fire = $Fire
@onready var explosion_sound = $ExplosionSound
@export var escala_explosion: float = 20.0  

func explode():
	scale = Vector3.ONE * escala_explosion
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	explosion_sound.play()
	await get_tree().create_timer(3.0).timeout
	queue_free()
