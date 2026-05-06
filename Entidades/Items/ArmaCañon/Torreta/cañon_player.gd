extends Node3D
class_name Canon

var camera: Camera3D
@export var gun: Node3D
@export var muzzle: Node3D
@export var projectile_scene: PackedScene
@export var target_yaw_speed: float = 30.0
@export var target_pitch_speed: float = 15.0
@export var sonido_disparo: AudioStreamPlayer3D
@export var dispersion: float = 0.05

var fire_rate: float = 0.1
var projectile_speed: float = 100.0
var damage: int = 10
var can_fire: bool = true
var activa: bool = false

func _ready() -> void:
	hide()
	set_process(false)

func activar(stats: ItemsStats) -> void:
	camera = get_viewport().get_camera_3d()
	show()
	set_process(true)
	activa = true
	print("Canon activado | visible: ", "visible | camera: ", camera)
	fire_rate        = stats.fire_rate
	projectile_speed = stats.bullet_speed
	damage           = stats.bullet_damage
	if stats.bullet_scene:
		projectile_scene = stats.bullet_scene

func desactivar() -> void:
	hide()
	set_process(false)
	activa = false

func _process(delta: float) -> void:
	if not camera or not activa:
		print("camera: ", camera, " | activa: ", activa)
		return

	var target = camera.global_transform.origin - camera.global_transform.basis.z * 1000

	var local_target = to_local(target)
	local_target.y = 0
	var angle = Vector3.BACK.signed_angle_to(local_target, Vector3.UP)
	rotation.y += angle * clamp(delta * target_yaw_speed, 0, 1)

	if gun:
		var gun_local = gun.to_local(target)
		gun_local.x = 0
		var pitch_angle = Vector3.BACK.signed_angle_to(gun_local, Vector3.RIGHT)
		gun.rotation.x += pitch_angle * clamp(delta * target_pitch_speed, 0, 1)

	if Input.is_action_pressed("shoot") and can_fire:
		fire()
		print("shoot presionado | can_fire: ", can_fire)
		if sonido_disparo:
			sonido_disparo.play()

func fire() -> void:
	if not projectile_scene or not muzzle:
		return
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

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
	if projectile.has_method("set_damage"):
		projectile.set_damage(damage)
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
