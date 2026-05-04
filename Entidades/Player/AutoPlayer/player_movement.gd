class_name PlayerVehicle
extends VehicleBody3D

# ============================================================
# EXPORTS
# ============================================================

@export_group("Movimiento")
@export var engine_force_value: float = 240.0
@export var velocidad_base: float = 600.0
@export var velocidad_maxima: float = 40.0
@export var steer_limit: float = 2.0
@export var steer_speed: float = 2.0
@export var steer_return: float = 10.0
@export var jump_force: float = 10.0
@export var freno_fuerza: float = 50.0

@export_group("Mecánicas Turbo y Vuelo")
@export var aire_rotacion_fuerza: float = 500.0
@export var agarre_normal: float = 5.0
@export var agarre_derrape: float = 0.5

@export_group("Referencias")
@export var stats: Stats

# ============================================================
# NODOS
# ============================================================

@onready var equipment: PlayerEquipment = $PlayerEquipment
@onready var pickup_area: Area3D        = $AreaDeInteraccion
@onready var turbo: TurboComponent      = $TurboComponent

@onready var rueda_tl: VehicleWheel3D = $left_front
@onready var rueda_tr: VehicleWheel3D = $right_front
@onready var rueda_bl: VehicleWheel3D = $left_back
@onready var rueda_br: VehicleWheel3D = $right_back

# ============================================================
# ESTADO INTERNO
# ============================================================

var steer_actual: float = 0.0
var _nitro_activo: bool = false
var _state_stack: StateStack
var _items_en_rango: Array[ItemMundo] = []

const ANTI_ROLL_FORCE: float = 1800.0

# ============================================================
# CICLO DE VIDA
# ============================================================

func _ready() -> void:
	_init_equipment()
	_init_signals()
	_init_state_machine()


func _physics_process(delta: float) -> void:
	_state_stack.process_all(delta)
	turbo.tick(delta, self)
	_intentar_recoger()
	_apply_anti_roll()

# ============================================================
# INICIALIZACIÓN
# ============================================================

func _init_equipment() -> void:
	if equipment:
		equipment.inicializar(stats, velocidad_base)
	_set_agarre(agarre_normal)


func _init_signals() -> void:
	pickup_area.area_entered.connect(_on_area_entered)
	pickup_area.area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	stats.health_depleted.connect(_on_health_depleted)


func _init_state_machine() -> void:
	_state_stack = StateStack.new()
	_state_stack.push(DrivingState.new(self, _state_stack))

# ============================================================
# FÍSICA
# ============================================================

func _apply_anti_roll() -> void:
	_anti_roll_axle(rueda_bl, rueda_br)
	_anti_roll_axle(rueda_tl, rueda_tr)


func _anti_roll_axle(rueda_izq: VehicleWheel3D, rueda_der: VehicleWheel3D) -> void:
	var fuerza := (rueda_izq.get_suspension_travel() - rueda_der.get_suspension_travel()) * ANTI_ROLL_FORCE
	if rueda_izq.is_in_contact():
		apply_force(Vector3.UP * -fuerza, rueda_izq.global_position)
	if rueda_der.is_in_contact():
		apply_force(Vector3.UP *  fuerza, rueda_der.global_position)


# Cancela la inercia rotacional de X/Z heredada del movimiento en tierra
# Lo llama el estado aéreo, no _physics_process
func cancelar_inercia_lateral(delta: float) -> void:
	angular_velocity.x = lerp(angular_velocity.x, 0.0, delta * 10.0)
	angular_velocity.z = lerp(angular_velocity.z, 0.0, delta * 10.0)


func _esta_en_suelo() -> bool:
	return rueda_bl.is_in_contact() or rueda_br.is_in_contact() \
		or rueda_tl.is_in_contact() or rueda_tr.is_in_contact()


func _set_agarre(valor: float) -> void:
	for rueda in [rueda_bl, rueda_br, rueda_tl, rueda_tr]:
		rueda.wheel_friction_slip = valor
# ============================================================
# ITEMS / PICKUP
# ============================================================

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

# ============================================================
# COMBATE
# ============================================================

func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - int(stats.current_defense))
		stats.health -= final_damage
		if stats.health <= 0:
			print("Jugador muerto")


func activar_nitro(duracion: float, multiplicador: float) -> void:
	if _nitro_activo:
		return

	_nitro_activo = true
	engine_force_value    *= multiplicador
	turbo.data.turbo_force *= multiplicador

	await get_tree().create_timer(duracion).timeout

	engine_force_value     = velocidad_base
	turbo.data.turbo_force /= multiplicador
	_nitro_activo = false

# ============================================================
# SEÑALES
# ============================================================

func _on_area_entered(area: Area3D) -> void:
	var parent := area.get_parent()
	if not parent is ItemMundo:
		return

	if parent.stats != null and parent.stats.tipo != ItemsStats.TipoItem.EQUIPABLE:
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
	if not body.has_method("apply_damage") or not stats:
		return

	var velocidad := linear_velocity.length()
	if velocidad <= 5.0:
		return

	var dano := int(stats.current_ram_damage * (velocidad / 20.0))
	body.apply_damage(dano)

	if body.has_method("apply_knockback"):
		var direccion: Vector3 = (body.global_position - global_position).normalized()
		body.apply_knockback(direccion, velocidad * 8.0)

	if has_node("CrashSFX"):
		$CrashSFX.play()
