extends Node3D
class_name Escopeta
var camera: Camera3D
@export var gun: Node3D
@export var muzzle: Node3D
@export var projectile_scene: PackedScene = preload("res://Common/Projectiles/Bullets/bullet.tscn")
@export var fire_rate: float = 0.1
@export var projectile_speed: float = 100.0
@export var target_yaw_speed: float = 30.0
@export var target_pitch_speed: float = 15.0
@export var sonido_disparo: AudioStreamPlayer3D
@export var max_balas_por_disparo: int = 8
var can_fire: bool = true
var activa: bool = false
var balas_por_disparo: int = 1

func _ready() -> void:
	hide()
	set_process(false)

func activar(item_stats: ItemsStats) -> void:
	camera = get_viewport().get_camera_3d()
	show()
	set_process(true)
	activa = true
	fire_rate        = item_stats.fire_rate
	projectile_speed = item_stats.bullet_speed
	if item_stats.bullet_scene:
		projectile_scene = item_stats.bullet_scene

func desactivar() -> void:
	hide()
	set_process(false)
	activa = false
	balas_por_disparo = 1

func _process(delta: float) -> void:
	if not camera or not activa:
		return
	var target = camera.global_transform.origin - camera.global_transform.basis.z * 1000
	var local_target = to_local(target)
	local_target.y = 0
	var angle = Vector3.FORWARD.signed_angle_to(local_target, Vector3.UP)
	rotation.y += angle * clamp(delta * target_yaw_speed, 0, 1)
	if gun:
		var gun_local = gun.to_local(target)
		gun_local.x = 0
		var pitch_angle = Vector3.FORWARD.signed_angle_to(gun_local, Vector3.RIGHT)
		gun.rotation.x += pitch_angle * clamp(delta * target_pitch_speed, 0, 1)

	if Input.is_action_just_pressed("shoot") and can_fire:
		balas_por_disparo = min(balas_por_disparo + 1, max_balas_por_disparo)
		fire()
		if sonido_disparo:
			sonido_disparo.play()

	if Input.is_action_just_released("shoot"):
		balas_por_disparo = 1

func fire() -> void:
	if not projectile_scene or not muzzle:
		return

	for i in balas_por_disparo:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)

		var dispersion = 0.3 + (balas_por_disparo - 1) * 0.15
		var offset = Vector3(
			randf_range(-dispersion, dispersion),
			randf_range(-dispersion, dispersion),
			0.0
		)
		projectile.global_transform = muzzle.global_transform
		projectile.global_position += muzzle.global_transform.basis * offset
		projectile.scale = Vector3(0.8, 0.8, 0.8)

		if projectile.has_method("set_initial_direction"):
			projectile.set_initial_direction(-muzzle.global_transform.basis.z, projectile_speed)

	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
