extends Resource
class_name Stats

enum BuffableStats {
	MAX_HEALTH,
	DEFENSE,
	ATTACK,
	RAM_DAMAGE,
	SPEED,     
}

const BASE_LEVEL_XP: float = 100.0

signal health_depleted
signal health_changed(cur_health: int, max_health: int)

# --- IDENTIFICADOR DE ENTIDAD ---
@export var tipo_entidad: String = "Jugador"

# --- STATS BASE CON SETTERS PARA RECALCULAR EN VIVO ---
@export var base_max_health: int = 100:
	set(value): base_max_health = value; _intentar_recalcular()
@export var base_defense: int = 10:
	set(value): base_defense = value; _intentar_recalcular()
@export var base_attack: int = 10:
	set(value): base_attack = value; _intentar_recalcular()
@export var base_ram_damage: int = 10:
	set(value): base_ram_damage = value; _intentar_recalcular()
@export var bonus_ram_damage: int = 0:
	set(value): bonus_ram_damage = value; _intentar_recalcular()

@export var experience: int = 0: set = _on_experience_set

# --- Movimiento ---
@export var base_speed: float        = 400.0:
	set(value): base_speed = value; _intentar_recalcular()
@export var base_attack_speed: float = 200.0:
	set(value): base_attack_speed = value; _intentar_recalcular()
@export var base_steer_limit: float  = 0.5:
	set(value): base_steer_limit = value; _intentar_recalcular()
@export var base_steer_speed: float  = 150.0:
	set(value): base_steer_speed = value; _intentar_recalcular()

var current_speed: float        = 400.0
var current_attack_speed: float = 200.0
var current_steer_limit: float  = 0.5
var current_steer_speed: float  = 150.0

var level: int:
	get(): return floor(max(1.0, sqrt(experience / BASE_LEVEL_XP) + 0.5))

var current_max_health: int = 100
var current_defense: int = 10
var current_attack: int = 10
var current_ram_damage: int = 10
var health: int = 0: set = _on_health_set

var stat_buffs: Array[StatBuff] = []
var _is_setup_done: bool = false

func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	_is_setup_done = true
	recalculate_stats()
	health = current_max_health

func _intentar_recalcular() -> void:
	if _is_setup_done:
		recalculate_stats()

func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()

func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()

func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}

	for buff in stat_buffs:
		var stat_name: String = BuffableStats.keys()[buff.stat].to_lower()
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] *= buff.buff_amount
				if stat_multipliers[stat_name] < 0.0:
					stat_multipliers[stat_name] = 0.0

	# --- Aplicación directa de los valores base del Inspector ---
	current_max_health  = base_max_health
	current_defense     = base_defense
	current_attack      = base_attack
	current_ram_damage  = base_ram_damage + bonus_ram_damage
	
	current_speed        = base_speed
	current_attack_speed = base_attack_speed
	current_steer_limit  = base_steer_limit
	current_steer_speed  = base_steer_speed

	# --- Aplicación de Buffs (si los hay) ---
	for stat_name in stat_multipliers:
		var prop: String = "current_" + stat_name
		set(prop, get(prop) * stat_multipliers[stat_name])

	for stat_name in stat_addends:
		var prop: String = "current_" + stat_name
		set(prop, get(prop) + stat_addends[stat_name])
		
	if health > current_max_health:
		health = current_max_health

func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0, current_max_health)
	
	print("[Stats] " + tipo_entidad + " - Vida actual: " + str(health) + " / " + str(current_max_health))
	
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()

func _on_experience_set(new_value: int) -> void:
	var old_level: int = level
	experience = new_value
	if not old_level == level:
		recalculate_stats()
