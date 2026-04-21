extends VehicleBody3D

# --- CONFIGURACIÓN DE MOVIMIENTO ---
@export_group("Movimiento")
@export var engine_force_value: float = 600.0
@export var velocidad_base: float = 600.0
@export var steer_limit: float = 100.0
@export var steer_speed: float = 2.0
@export var steer_return: float = 10.0
@export var jump_force: float = 10.0
@export var freno_fuerza: float = 50.0

# --- MECÁNICAS ESPECIALES ---
@export_group("Mecánicas Turbo y Vuelo")
@export var aire_rotacion_fuerza: float = 500.0
@export var agarre_normal: float = 5.0
@export var agarre_derrape: float = 0.1


# --- REFERENCIAS ---
@export_group("Referencias")
@export var stats: Stats

@onready var equipment: PlayerEquipment = $PlayerEquipment
@onready var pickup_area: Area3D = $AreaDeInteraccion
# En player_vehicle.gd, un componente dedicado
@onready var turbo: TurboComponent = $TurboComponent
# --- VARIABLES INTERNAS ---
var steer_actual: float = 0.0
var _nitro_activo: bool = false
var _state_stack: StateStack
var items_en_rango: Array[ItemMundo] = []

func _ready() -> void:
	if equipment:
		equipment.inicializar(stats, velocidad_base)
	_set_agarre(agarre_normal)
	center_of_mass = Vector3(0, -0.2, 0)

	pickup_area.area_entered.connect(_on_area_entered)
	pickup_area.area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)

	_state_stack = StateStack.new()
	_state_stack.push(DrivingState.new(self, _state_stack))

func _physics_process(delta: float) -> void:
	_state_stack.process_all(delta)
	turbo.tick(delta, self)
	_intentar_recoger()
func _esta_en_suelo() -> bool:
	return $left_back.is_in_contact() or $right_back.is_in_contact() or \
		   $left_front.is_in_contact() or $right_front.is_in_contact()

func _set_agarre(valor: float) -> void:
	$left_back.wheel_friction_slip  = valor
	$right_back.wheel_friction_slip = valor
	$left_front.wheel_friction_slip = valor
	$right_front.wheel_friction_slip = valor

func _intentar_recoger() -> void:
	if not Input.is_action_just_pressed("Tecla E") or items_en_rango.is_empty():
		return

	var closest: ItemMundo = null
	var min_dist: float = INF

	for item in items_en_rango:
		if not is_instance_valid(item): continue
		var d = global_position.distance_to(item.global_position)
		if d < min_dist:
			min_dist = d
			closest = item

	if closest:
		equipment.equipar(closest.slot, closest.nombre_item, global_position, closest.stats)
		items_en_rango.erase(closest)
		closest.queue_free()

func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if not parent is ItemMundo: return

	if parent.stats != null and parent.stats.tipo != ItemsStats.TipoItem.EQUIPABLE:
		equipment.equipar(parent.slot, parent.nombre_item, global_position, parent.stats)
		parent.queue_free()
	else:
		items_en_rango.append(parent)

func _on_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is ItemMundo:
		items_en_rango.erase(parent)

func apply_damage(amount: int) -> void:
	if stats:
		var final_damage = max(0, amount - int(stats.current_defense))
		stats.health -= final_damage
		if stats.health <= 0:
			print("Jugador muerto")

func activar_nitro(duracion: float, multiplicador: float) -> void:
	if _nitro_activo: return
	_nitro_activo = true

	engine_force_value *= multiplicador
	turbo.data.turbo_force *= multiplicador

	await get_tree().create_timer(duracion).timeout

	engine_force_value = velocidad_base
	turbo.data.turbo_force /= multiplicador
	_nitro_activo = false

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage") and stats:
		var velocidad = linear_velocity.length()
		if velocidad > 5.0:
			var dano_choque = int(stats.current_ram_damage * (velocidad / 20.0))
			body.apply_damage(dano_choque)

			if body.has_method("apply_knockback"):
				var direccion = (body.global_position - global_position).normalized()
				var fuerza = velocidad * 8.0
				if has_node("CrashSFX"): $CrashSFX.play()
				body.apply_knockback(direccion, fuerza)
