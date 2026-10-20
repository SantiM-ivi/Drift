class_name Escopeta
extends Node3D

@export_group("Referencias")
@export var gun: Node3D
@export var muzzle: Node3D
@export var sonido_disparo: AudioStreamPlayer3D
@export var projectile_scene: PackedScene = preload("res://Common/Projectiles/Bullets/bullet.tscn")

@export_group("Disparo")
@export var fire_rate: float = 0.1
@export var projectile_speed: float = 100.0
@export var max_balas_por_disparo: int = 1
@export var dispersion_grados: float = 4.0

@export_group("Apuntado")
@export var target_yaw_speed: float = 30.0
@export var target_pitch_speed: float = 15.0

var camera: Camera3D
var activa: bool = false
var _cooldown: float = 0.0

func _ready() -> void:
	hide()
	set_process(false)

func activar(item_stats: ItemsStats) -> void:
	camera = get_viewport().get_camera_3d()
	fire_rate = item_stats.fire_rate
	projectile_speed = item_stats.bullet_speed
	if item_stats.bullet_scene:
		projectile_scene = item_stats.bullet_scene
	_cooldown = 0.0
	activa = true
	show()
	set_process(true)

func desactivar() -> void:
	activa = false
	hide()
	set_process(false)

func _process(delta: float) -> void:
	if not activa or not is_instance_valid(camera):
		return
	_cooldown = max(_cooldown - delta, 0.0)
	_apuntar(delta)
	if Input.is_action_just_pressed("shoot") and _cooldown <= 0.0:
		_disparar()

func _apuntar(delta: float) -> void:
	var target = camera.global_position - camera.global_basis.z * 1000.0
	var local_target = to_local(target)
	local_target.y = 0.0
	var angle = Vector3.FORWARD.signed_angle_to(local_target, Vector3.UP)
	rotation.y += angle * clamp(delta * target_yaw_speed, 0.0, 1.0)
	if gun:
		var gun_local = gun.to_local(target)
		gun_local.x = 0.0
		var pitch_angle = Vector3.FORWARD.signed_angle_to(gun_local, Vector3.RIGHT)
		gun.rotation.x += pitch_angle * clamp(delta * target_pitch_speed, 0.0, 1.0)

func _disparar() -> void:
	if not projectile_scene or not muzzle:
		return
	_cooldown = fire_rate
	for i in max_balas_por_disparo:
		_lanzar_proyectil()
	if sonido_disparo:
		sonido_disparo.play()

func _lanzar_proyectil() -> void:
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var spread = deg_to_rad(dispersion_grados)
	var base = muzzle.global_basis.orthonormalized()
	base = base.rotated(base.y, randf_range(-spread, spread))
	base = base.rotated(base.x, randf_range(-spread, spread))
	projectile.global_transform = Transform3D(base, muzzle.global_position)

	if projectile.has_method("set_initial_direction"):
		projectile.set_initial_direction(-base.z, projectile_speed)
