extends RigidBody3D

enum Estado { QUIETO, ACELERANDO, EN_AIRE, BOOST }

@export_group("Flotacion")
@export var altura_flotacion: float = 0.6
@export var fuerza_resorte: float   = 600.0
@export var amortiguacion: float    = 30.0

@export_group("Movimiento")
@export var velocidad_maxima: float   = 30.0
@export var fuerza_avance: float      = 800.0
@export var agarre_lateral: float     = 0.95
@export var tiempo_aceleracion: float = 5.0
@export var tiempo_frenado: float     = 8.0

@export_group("Boost")
@export var bonus_velocidad_boost: float = 20.0
@export var duracion_boost: float        = 1.5
@export var cooldown_boost: float        = 4.0

@export_group("Camara")
@export var velocidad_giro: float = 2.0
@export var camara_pivot: Node3D

@export_group("Visual")
@export var inclinacion_lateral: float  = 8.0
@export var adelanto_giro: float        = 25.0
@export var suavidad_inclinacion: float = 100.0

@export_group("Referencias")
@export var stats: Stats

# ─── NODOS ───────────────────────────────────────────────────────────────────

@onready var rueda_fl: Node3D          = $VisualRoot/FrontLeft
@onready var rueda_fr: Node3D          = $VisualRoot/FrontRight
@onready var rueda_bl: Node3D          = $VisualRoot/BackLeft
@onready var rueda_br: Node3D          = $VisualRoot/BackRight
@onready var raiz_visual: Node3D       = $VisualRoot
@onready var rayos: Array[RayCast3D]   = [$RayFL, $RayFR, $RayBL, $RayBR]
@onready var debug_label: Label3D      = $DebugLabel
@onready var debug_vel_label: Label3D  = $DebugVelocidadLabel
@onready var equipment: PlayerEquipment = $PlayerEquipment
@onready var pickup_area: Area3D        = $AreaDeInteraccion
@onready var bocina_sfx: AudioStreamPlayer3D = $BocinaSFX
@onready var hud = $"../HUD"
# ─── ESTADO INTERNO ──────────────────────────────────────────────────────────

const MAX_ANGULO_RUEDA: float = 25.0
const SUAVIDAD_RUEDA: float   = 8.0

var _angulo_rueda_actual: float = 0.0
var _estado: Estado             = Estado.QUIETO
var _inclinacion_actual: float  = 0.0
var _velocidad_actual: float    = 0.0
var _boost_activo: bool         = false
var _bonus_velocidad: float     = 0.0
var _tiempo_boost: float        = 0.0
var _tiempo_cooldown: float     = 0.0
var _nitro_activo: bool         = false
var _items_en_rango: Array[ItemMundo] = []
var _cooldown_disparo: float = 0.0
# ─── INIT ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if camara_pivot == null:
		push_error("Player: asigná CameraRig en el Inspector")
	for rayo in rayos:
		rayo.target_position = Vector3.DOWN * (altura_flotacion * 2.5)
		rayo.enabled = true

	# Sistemas de juego
	if equipment:
		equipment.inicializar(stats, velocidad_maxima)
		equipment.equipar_inicio()
	if stats:
		stats.health_depleted.connect(_on_health_depleted)
		stats.health_changed.connect(_on_health_changed)
	pickup_area.area_entered.connect(_on_area_entered)
	pickup_area.area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)

# ─── LOOP PRINCIPAL ──────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if camara_pivot == null:
		return
	_sincronizar_camara()

	var en_suelo  = _algun_rayo_toca()
	var accel_inp = Input.get_axis("ui_up", "ui_down")
	var boosting  = Input.is_action_just_pressed("boost")


	_tick_boost(delta, boosting)
	_actualizar_estado(en_suelo, accel_inp)
	_aplicar_flotacion()
	_actualizar_visual(delta, Input.get_axis("ui_right", "ui_left"))

	
	var giro = Input.get_axis("ui_right", "ui_left")
	if en_suelo:
		camara_pivot.rotate_y(giro * velocidad_giro * delta)
	_intentar_recoger()

	if not en_suelo:
		_estabilizar_en_aire(delta)
		_aplicar_propulsor(delta)

	_aplicar_movimiento(delta, giro, accel_inp)
	_cooldown_disparo -= delta
	_manejar_disparo()
	if Input.is_action_just_pressed("Bocina"):
		bocina_sfx.play()
	if hud:
		var vel_kmh = int(Vector2(linear_velocity.x, linear_velocity.z).length() * 3.6)
		hud.set_speed(vel_kmh)

# ─── STATE MACHINE ───────────────────────────────────────────────────────────

func _actualizar_estado(en_suelo: bool, accel_inp: float) -> void:
	var previo = _estado
	if _boost_activo:
		_estado = Estado.BOOST
	elif not en_suelo:
		_estado = Estado.EN_AIRE
	elif abs(accel_inp) > 0.05:
		_estado = Estado.ACELERANDO
	else:
		_estado = Estado.QUIETO
	if _estado != previo and debug_label:
		debug_label.text = Estado.keys()[_estado]

# ─── BOOST ───────────────────────────────────────────────────────────────────

func _tick_boost(delta: float, boosting: bool) -> void:
	if _tiempo_cooldown > 0.0:
		_tiempo_cooldown -= delta
	if boosting and _tiempo_cooldown <= 0.0 and not _boost_activo:
		_boost_activo    = true
		_tiempo_boost    = duracion_boost
		_bonus_velocidad = bonus_velocidad_boost
	if _boost_activo:
		_tiempo_boost -= delta
		if _tiempo_boost <= 0.0:
			_boost_activo    = false
			_tiempo_cooldown = cooldown_boost
			_bonus_velocidad = 0.0

func _estabilizar_en_aire(delta: float) -> void:
	if _algun_rayo_toca():
		return

	# Enderezar eje Y hacia arriba
	var alineacion = global_basis.y.dot(Vector3.UP)
	if alineacion < 0.99:
		var eje = global_basis.y.cross(Vector3.UP).normalized()
		var fuerza = (1.0 - alineacion) * 600.0
		apply_torque(eje * fuerza)

	# Frenar rotación en el aire para que no gire a lo loco
	angular_velocity = angular_velocity.lerp(Vector3.ZERO, delta * 5.0)

func _aplicar_propulsor(delta: float) -> void:
	if not Input.is_action_pressed("boost") or _tiempo_cooldown > 0.0:
		return

	# No aplicar fuerza si ya superamos la velocidad máxima con boost
	var vel_actual = linear_velocity.length()
	if vel_actual >= velocidad_maxima + bonus_velocidad_boost:
		return

	var direccion = -camara_pivot.global_basis.z
	apply_central_force(direccion * fuerza_avance * 1.5)
	_tiempo_boost -= delta
	if _tiempo_boost <= 0.0:
		_boost_activo    = false
		_tiempo_cooldown = cooldown_boost
		_bonus_velocidad = 0.0

# ─── CÁMARA ──────────────────────────────────────────────────────────────────

func _sincronizar_camara() -> void:
	camara_pivot.global_position = global_position
	camara_pivot.rotation.x      = 0.0
	camara_pivot.rotation.z      = 0.0

# ─── DISPARO ──────────────────────────────────────────────────────────────────
func _manejar_disparo() -> void:
	if not Input.is_action_just_pressed("shoot"):
		return
	if not equipment or not equipment.arma_activa:
		return
	if _cooldown_disparo > 0.0:
		return

	# Punto de disparo — el MuzzlePoint del ArmaSlot
	var arma_node = equipment.equipado.get("Arma")
	if arma_node == null:
		return

	var muzzle = arma_node.get_node_or_null("Muzzle")
	var origen = muzzle.global_position if muzzle else global_position
	var direccion = -global_transform.basis.z  # hacia donde mira el auto

	_cooldown_disparo = equipment.arma_activa.fire_rate

# ─── FLOTACION ───────────────────────────────────────────────────────────────

func _aplicar_flotacion() -> void:
	for rayo in rayos:
		rayo.force_raycast_update()
		if not rayo.is_colliding():
			continue
		var pos_rayo  = rayo.global_position
		var distancia = pos_rayo.distance_to(rayo.get_collision_point())
		var extension = altura_flotacion - distancia
		var vel_rel   = Vector3.UP.dot(linear_velocity + angular_velocity.cross(pos_rayo - to_global(center_of_mass)))
		var fuerza    = max((extension * fuerza_resorte) - (vel_rel * amortiguacion), 0.0)
		apply_force(Vector3.UP * fuerza, pos_rayo - global_position)



# ─── MOVIMIENTO ──────────────────────────────────────────────────────────────

func _aplicar_movimiento(delta: float, giro: float, accel_inp: float) -> void:
	var direccion = camara_pivot.global_basis.z

	match _estado:
		Estado.BOOST:
			_aplicar_aceleracion(delta, accel_inp)
			_aplicar_fuerza_avance(delta, direccion, velocidad_maxima + _bonus_velocidad)
		_:
			_aplicar_aceleracion(delta, accel_inp)
			_aplicar_fuerza_avance(delta, direccion, velocidad_maxima)

	var ratio_vel     = clamp(abs(_velocidad_actual) / velocidad_maxima, 0.2, 1.0)
	var agarre_actual = agarre_lateral * ratio_vel
	var deslizamiento = linear_velocity.dot(camara_pivot.global_basis.x)
	var fuerza_lat    = mass * (-deslizamiento) / delta
	apply_central_force(camara_pivot.global_basis.x * clamp(fuerza_lat * agarre_actual, -fuerza_avance, fuerza_avance))

	var offset_giro = giro * adelanto_giro
	var angulo_objetivo = camara_pivot.global_rotation_degrees.y + offset_giro
	var frente_objetivo = Vector3(sin(deg_to_rad(angulo_objetivo)), 0.0, cos(deg_to_rad(angulo_objetivo)))
	var frente_actual   = Vector3(global_basis.z.x, 0.0, global_basis.z.z).normalized()
	var diferencia      = frente_actual.signed_angle_to(frente_objetivo, Vector3.UP)
	apply_torque(Vector3.UP * clamp(diferencia * 80.0 - angular_velocity.y * 8.0, -120.0, 120.0))

func _aplicar_aceleracion(delta: float, accel_inp: float) -> void:
	var vel_max = velocidad_maxima + _bonus_velocidad
	if abs(accel_inp) > 0.05:
		var objetivo = vel_max * (-1.0 if accel_inp > 0.0 else 1.0)
		var ritmo    = tiempo_aceleracion if abs(objetivo) > abs(_velocidad_actual) else tiempo_frenado
		_velocidad_actual = move_toward(_velocidad_actual, objetivo, vel_max / ritmo * delta)
	else:
		_velocidad_actual = move_toward(_velocidad_actual, 0.0, vel_max / tiempo_frenado * delta)

func _aplicar_fuerza_avance(delta: float, direccion: Vector3, vel_max: float) -> void:
	var vel_deseada = -direccion * _velocidad_actual
	var error       = mass * (vel_deseada - linear_velocity) / delta
	var limite      = fuerza_avance if _velocidad_actual >= -velocidad_maxima else fuerza_avance * 0.3
	apply_central_force(Vector3(
		clamp(error.x, -limite, limite),
		0.0,
		clamp(error.z, -limite, limite)
	))


# ─── VISUAL ──────────────────────────────────────────────────────────────────

func _actualizar_visual(delta: float, giro: float) -> void:
	if raiz_visual == null:
		return

	var inclin_objetivo = giro * inclinacion_lateral
	_inclinacion_actual  = lerp(_inclinacion_actual, inclin_objetivo, suavidad_inclinacion * delta)
	raiz_visual.rotation_degrees.z = _inclinacion_actual

	var angulo_objetivo  = giro * MAX_ANGULO_RUEDA
	_angulo_rueda_actual = lerp(_angulo_rueda_actual, angulo_objetivo, SUAVIDAD_RUEDA * delta)

	if rueda_fl: rueda_fl.rotation_degrees.y = _angulo_rueda_actual
	if rueda_fr: rueda_fr.rotation_degrees.y = _angulo_rueda_actual

	if debug_vel_label:
		var vel_real = Vector2(linear_velocity.x, linear_velocity.z).length()
		debug_vel_label.text = "KM %.1f | interna: %.1f | max: %.1f" % [vel_real, abs(_velocidad_actual), velocidad_maxima]

# ─── ITEMS / PICKUP ──────────────────────────────────────────────────────────

func _intentar_recoger() -> void:
	if not Input.is_action_just_pressed("Tecla E") or _items_en_rango.is_empty():
		return
	var closest := _item_mas_cercano()
	if not closest:
		return
	equipment.equipar(closest.slot, closest.nombre_item, global_position, closest.stats)
	_items_en_rango.erase(closest)
	closest.queue_free()

func _item_mas_cercano() -> ItemMundo:
	var closest: ItemMundo = null
	var min_dist: float    = INF
	for item: ItemMundo in _items_en_rango:
		if not is_instance_valid(item):
			continue
		var d := global_position.distance_to(item.global_position)
		if d < min_dist:
			min_dist = d
			closest  = item
	return closest

# ─── COMBATE ─────────────────────────────────────────────────────────────────

func apply_damage(amount: int) -> void:
	if stats:
		var reduccion = clamp(stats.current_defense / 100.0, 0.0, 0.9)  # max 90% reducción
		var final_damage = max(1, int(amount * (1.0 - reduccion)))
		stats.health -= final_damage
		print("[Player] daño recibido: %d | defensa: %.0f | reduccion: %.0f%% | daño final: %d | vida: %d/%d" % [
			amount,
			stats.current_defense,
			reduccion * 100,
			final_damage,
			stats.health,
			stats.current_max_health,
		])
		if stats.health <= 0:
			print("Jugador muerto")

func activar_nitro(duracion: float, multiplicador: float) -> void:
	if _nitro_activo:
		return
	_nitro_activo     = true
	velocidad_maxima *= multiplicador
	_bonus_velocidad  = 0.0  # resetear para que no se apile con boost
	await get_tree().create_timer(duracion).timeout
	velocidad_maxima /= multiplicador
	_nitro_activo     = false
	print("Nitro terminado")

# ─── SEÑALES ─────────────────────────────────────────────────────────────────

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if not parent is ItemMundo:
		return

	var tipo = parent.stats.tipo if parent.stats != null else -1
	var es_auto = (
		tipo != ItemsStats.TipoItem.EQUIPABLE and
		tipo != ItemsStats.TipoItem.ARMA and
		tipo != ItemsStats.TipoItem.RUEDA        # <-- esto faltaba
	)

	if parent.stats != null and es_auto:
		equipment.equipar(parent.slot, parent.nombre_item, global_position, parent.stats)
		parent.queue_free()
	else:
		_items_en_rango.append(parent)

func _on_area_exited(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent is ItemMundo:
		_items_en_rango.erase(parent)

func _on_health_depleted() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	var velocidad := linear_velocity.length()
	if velocidad <= 5.0:
		return

	var objetivo = body
	while objetivo != null:
		if objetivo.has_method("apply_damage"):
			break
		objetivo = objetivo.get_parent()

	if objetivo == null or not stats:
		return

	var dano := int(stats.current_ram_damage * (velocidad / 20.0))
	objetivo.apply_damage(dano)

	var direccion: Vector3 = (objetivo.global_position - global_position).normalized()

	if objetivo.has_method("apply_knockback"):
		var fuerza = clamp(velocidad * 2.0, 20.0, 150.0)
		objetivo.apply_knockback(direccion, fuerza)

	# Rebote explosivo hacia atrás
	var direccion_rebote = -direccion
	direccion_rebote.y = 0.0
	direccion_rebote = direccion_rebote.normalized()

	linear_velocity = linear_velocity * 0.2
	var fuerza_rebote = clamp(velocidad * 2.0, 15.0, 60.0)
	apply_central_impulse(direccion_rebote * fuerza_rebote * mass)
# ─── UTILS ───────────────────────────────────────────────────────────────────

func _algun_rayo_toca() -> bool:
	for rayo in rayos:
		if rayo.is_colliding():
			return true
	return false

func _on_health_changed(cur_health: int, max_health: int) -> void:
	if hud:
		hud.set_health(cur_health)
		hud.health_bar.max_value = max_health

func ajustar_raycasts(nombre_rueda: String) -> void:
	match nombre_rueda:
		"Rueda3":
			altura_flotacion = 1.2   # más alto
		_:
			altura_flotacion = 0.6   # valor original

	for rayo in rayos:
		rayo.target_position = Vector3.DOWN * (altura_flotacion * 2.5)
	print("[Player] flotacion ajustada para %s — altura: %.1f" % [nombre_rueda, altura_flotacion])
