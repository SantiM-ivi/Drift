extends Resource
class_name Stats

enum BuffableStats {
	MAX_HEALTH,
	DEFENSE,
	ATTACK,
	RAM_DAMAGE,
	SPEED,     
}

const STAT_CURVES: Dictionary[BuffableStats, Curve] = {
	BuffableStats.MAX_HEALTH: preload("uid://bl4di0h8srmiu"),
	BuffableStats.DEFENSE:    preload("uid://dk6jwiov8fm8h"),
	BuffableStats.ATTACK:     preload("uid://c55yl8ie1k14y"),
	BuffableStats.RAM_DAMAGE: preload("uid://c55yl8ie1k14y"), 
}

const BASE_LEVEL_XP: float = 100.0

signal health_depleted
signal health_changed(cur_health: int, max_health: int)

@export var base_max_health: int = 100
@export var base_defense: int = 10
@export var base_attack: int = 10
@export var base_ram_damage: int = 10  
@export var bonus_ram_damage: int = 0
@export var experience: int = 0: set = _on_experience_set
# --- Movimiento ---
@export var base_speed: float        = 400.0  # engine_force en chase
@export var base_attack_speed: float = 200.0  # engine_force en attack (más lento)
@export var base_steer_limit: float  = 0.5    # ángulo máximo de giro
@export var base_steer_speed: float  = 150.0  # qué tan rápido gira

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
var stat_buffs: Array[StatBuff]

func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	recalculate_stats()
	health = current_max_health

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

	var stat_sample_pos: float = (float(level) / 100.0) - 0.1
	current_max_health  = base_max_health  * STAT_CURVES[BuffableStats.MAX_HEALTH].sample(stat_sample_pos)
	current_defense     = base_defense     * STAT_CURVES[BuffableStats.DEFENSE].sample(stat_sample_pos)
	current_attack      = base_attack      * STAT_CURVES[BuffableStats.ATTACK].sample(stat_sample_pos)
	current_ram_damage  = base_ram_damage  * STAT_CURVES[BuffableStats.RAM_DAMAGE].sample(stat_sample_pos)
	current_speed        = base_speed
	current_attack_speed = base_attack_speed
	current_steer_limit  = base_steer_limit
	current_steer_speed  = base_steer_speed


	for stat_name in stat_multipliers:
		var prop: String = "current_" + stat_name
		set(prop, get(prop) * stat_multipliers[stat_name])

	for stat_name in stat_addends:
		var prop: String = "current_" + stat_name
		set(prop, get(prop) + stat_addends[stat_name])

func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0, current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()

func _on_experience_set(new_value: int) -> void:
	var old_level: int = level
	experience = new_value
	if not old_level == level:
		recalculate_stats()
