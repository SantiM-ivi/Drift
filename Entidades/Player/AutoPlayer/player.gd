extends RigidBody3D

# ═══════════════════════════════════════════════════════════════════════════════
#  HOVER CAR CONTROLLER
# ═══════════════════════════════════════════════════════════════════════════════

enum Estado { QUIETO, ACELERANDO, FRENANDO, EN_AIRE, BOOST, DRIFT }

@export_group("Flotacion")
@export var altura_flotacion: float = 0.6
@export var fuerza_resorte: float   = 600.0
@export var amortiguacion: float    = 30.0

@export_group("Movimiento")
@export var velocidad_maxima: float   = 30.0
@export var fuerza_avance: float      = 800.0
@export var fuerza_frenado: float     = 1200.0
@export var agarre_lateral: float     = 0.95
@export var tiempo_aceleracion: float = 5.0
@export var tiempo_frenado: float     = 8.0

@export_group("Boost")
@export var bonus_velocidad_boost: float = 20.0
@export var duracion_boost: float        = 1.5
@export var cooldown_boost: float        = 4.0

@export_group("Drift")
@export var agarre_drift: float         = 0.15
@export var velocidad_giro_drift: float = 3.5
@export var inclinacion_drift: float    = 18.0

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
# ─── ESTADO INTERNO ──────────────────────────────────────────────────────────

const MAX_ANGULO_RUEDA: float = 25.0
const SUAVIDAD_RUEDA: float   = 8.0

var _angulo_rueda_actual: float = 0.0
var _estado: Estado             = Estado.QUIETO
var _inclinacion_actual: float  = 0.0
var _velocidad_actual: float    = 0.0
var _drift_dir: float           = 0.0
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
	if stats:
		stats.health_depleted.connect(_on_health_depleted)
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
	var frenando  = Input.is_action_pressed("ui_accept")
	var boosting  = Input.is_action_just_pressed("boost")

	_drift_dir = 0.0
	if Input.is_action_pressed("drift_izq"):
		_drift_dir = 1.0
	elif Input.is_action_pressed("drift_der"):
		_drift_dir = -1.0

	_tick_boost(delta, boosting)
	_actualizar_estado(en_suelo, accel_inp, frenando)
	_aplicar_flotacion()
	_aplicar_anti_volteo(en_suelo)
	_actualizar_visual(delta, Input.get_axis("ui_right", "ui_left"))
	_intentar_saltar(en_suelo)
	
	var giro = Input.get_axis("ui_right", "ui_left")
	if en_suelo:
		if _estado == Estado.DRIFT:
			camara_pivot.rotate_y(_drift_dir * velocidad_giro_drift * delta)
		else:
			camara_pivot.rotate_y(giro * velocidad_giro * delta)

	_intentar_recoger()

	if not en_suelo:
		_aplicar_propulsor(delta)

	_aplicar_movimiento(delta, giro, accel_inp, frenando)
	_cooldown_disparo -= delta
	_manejar_disparo()
	if Input.is_action_just_pressed("Bocina"):
		bocina_sfx.play()
# ─── STATE MACHINE ───────────────────────────────────────────────────────────

func _actualizar_estado(en_suelo: bool, accel_inp: float, frenando: bool) -> void:
	var previo = _estado
	if _boost_activo:
		_estado = Estado.BOOST
	elif not en_suelo:
		_estado = Estado.EN_AIRE
	elif _drift_dir != 0.0:
		_estado = Estado.DRIFT
	elif frenando:
		_estado = Estado.FRENANDO
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


func _intentar_saltar(en_suelo: bool) -> void:
	if Input.is_action_just_pressed("jump") and en_suelo:
		apply_central_impulse(Vector3.UP * 8.0 * mass)
		# Mantener velocidad horizontal al saltar
		var vel_horizontal = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		apply_central_impulse(vel_horizontal * mass * 0.5)

func _aplicar_propulsor(delta: float) -> void:
	if not Input.is_action_pressed("boost") or _tiempo_cooldown > 0.0:
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

# ─── ANTI-VOLTEO ─────────────────────────────────────────────────────────────

func _aplicar_anti_volteo(en_suelo: bool) -> void:
	var alineacion = global_basis.y.dot(Vector3.UP)
	if not en_suelo:
		if alineacion < 0.7:
			var eje    = global_basis.y.cross(Vector3.UP).normalized()
			var fuerza = (0.7 - alineacion) / 0.7
			apply_torque(eje * fuerza * 400.0)
	else:
		if alineacion < 0.5:
			var eje = global_basis.y.cross(Vector3.UP).normalized()
			apply_torque(eje * 300.0)

# ─── MOVIMIENTO ──────────────────────────────────────────────────────────────

func _aplicar_movimiento(delta: float, giro: float, accel_inp: float, frenando: bool) -> void:
	var direccion = camara_pivot.global_basis.z

	match _estado:
		Estado.FRENANDO:
			_aplicar_frenado(delta, direccion)
		Estado.BOOST:
			_aplicar_aceleracion(delta, accel_inp)
			_aplicar_fuerza_avance(delta, direccion, velocidad_maxima + _bonus_velocidad)
		Estado.DRIFT:
			_aplicar_aceleracion(delta, accel_inp)
			_aplicar_fuerza_avance(delta, direccion, velocidad_maxima)
			apply_central_force(-camara_pivot.global_basis.x * _drift_dir * fuerza_avance * 0.6)
		_:
			_aplicar_aceleracion(delta, accel_inp)
			_aplicar_fuerza_avance(delta, direccion, velocidad_maxima)

	var ratio_vel     = clamp(abs(_velocidad_actual) / velocidad_maxima, 0.2, 1.0)
	var agarre_actual = (agarre_drift if _estado == Estado.DRIFT else agarre_lateral * ratio_vel)
	var deslizamiento = linear_velocity.dot(camara_pivot.global_basis.x)
	var fuerza_lat    = mass * (-deslizamiento) / delta
	apply_central_force(camara_pivot.global_basis.x * clamp(fuerza_lat * agarre_actual, -fuerza_avance, fuerza_avance))

	var offset_giro     = _drift_dir * adelanto_giro * 2.0 if _estado == Estado.DRIFT else giro * adelanto_giro
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

func _aplicar_frenado(delta: float, direccion: Vector3) -> void:
	_velocidad_actual = move_toward(_velocidad_actual, 0.0, velocidad_maxima / tiempo_frenado * delta)
	var vel_freno     = linear_velocity.dot(-direccion)
	apply_central_force(direccion * clamp(vel_freno * mass / delta, -fuerza_frenado, fuerza_frenado))

# ─── VISUAL ──────────────────────────────────────────────────────────────────

func _actualizar_visual(delta: float, giro: float) -> void:
	if raiz_visual == null:
		return

	var inclin_objetivo  = _drift_dir * inclinacion_drift if _estado == Estado.DRIFT else giro * inclinacion_lateral
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
		var final_damage = max(0, amount - int(stats.current_defense))
		stats.health -= final_damage
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
	if not parent is ItemMundo: return

	if parent.stats != null and parent.stats.tipo != ItemsStats.TipoItem.EQUIPABLE and parent.stats.tipo != ItemsStats.TipoItem.ARMA:
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
	print("tiene apply_damage: ", body.has_method("apply_damage"))
	print("stats: ", stats)
	print("body: ", body.name, " | clase: ", body.get_class())
	print("padre: ", body.get_parent().name, " | clase: ", body.get_parent().get_class())
	print("tiene knockback: ", body.has_method("apply_knockback"))
	print("padre tiene knockback: ", body.get_parent().has_method("apply_knockback"))
	if not body.has_method("apply_damage") or not stats:
		return
	var velocidad := linear_velocity.length()
	if velocidad <= 5.0:
		return
	var dano := int(stats.current_ram_damage * (velocidad / 20.0))
	body.apply_damage(dano)

	var direccion: Vector3 = (body.global_position - global_position).normalized()

	# Buscar apply_knockback en el body o en su padre
	var knockback_target = null
	if body.has_method("apply_knockback"):
		knockback_target = body
	elif body.get_parent() and body.get_parent().has_method("apply_knockback"):
		knockback_target = body.get_parent()

	if knockback_target:
		var fuerza = clamp(velocidad * 1.0, 5.0, 50.0)
		knockback_target.apply_knockback(direccion, fuerza)

# ─── UTILS ───────────────────────────────────────────────────────────────────

func _algun_rayo_toca() -> bool:
	for rayo in rayos:
		if rayo.is_colliding():
			return true
	return false
