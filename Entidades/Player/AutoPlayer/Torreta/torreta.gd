extends Node3D
class_name Turret

@onready var camera: Camera3D = $"../../CameraRig/Camera3D"
@export var gun: Node3D        # el cañón (padre del Muzzle)
@export var muzzle: Node3D     # el punto de salida de la bala
@export var projectile_scene: PackedScene = preload("res://Common/Projectiles/Bullets/bullet.tscn")
@export var fire_rate: float = 0.1
@export var projectile_speed: float = 100.0
@export var target_yaw_speed: float = 30.0
@export var target_pitch_speed: float = 15.0
@export var sonido_disparo: AudioStreamPlayer3D

var can_fire: bool = true

func _process(delta: float) -> void:
	if not camera:
		return

	# Definimos un punto lejano hacia donde mira la cámara
	var target = camera.global_transform.origin - camera.global_transform.basis.z * 1000

	# --- Yaw (rotación horizontal de la torreta) ---
	var local_target = to_local(target)
	local_target.y = 0
	var angle = Vector3.BACK.signed_angle_to(local_target, Vector3.UP)
	rotation.y += angle * clamp(delta * target_yaw_speed, 0, 1)

	# --- Pitch (elevación del cañón) ---
	var gun_local = gun.to_local(target)
	gun_local.x = 0
	var pitch_angle = Vector3.BACK.signed_angle_to(gun_local, Vector3.RIGHT)
	gun.rotation.x += pitch_angle * clamp(delta * target_pitch_speed, 0, 1)

	# Disparo
	if Input.is_action_pressed("shoot") and can_fire:
		fire()
		sonido_disparo.play()

func fire() -> void:
	if projectile_scene and muzzle:
		var projectile = projectile_scene.instantiate()
		projectile.global_transform = muzzle.global_transform
		get_tree().current_scene.add_child(projectile)
		projectile.scale = Vector3(0.8, 0.8, 0.8)

		# En vez de linear_velocity, pasamos dirección y velocidad
		if projectile.has_method("set_initial_direction"):
			projectile.set_initial_direction(-muzzle.global_transform.basis.z, projectile_speed)

		can_fire = false
		await get_tree().create_timer(fire_rate).timeout
		can_fire = true
