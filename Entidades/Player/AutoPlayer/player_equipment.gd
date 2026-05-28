extends Node
class_name PlayerEquipment

# ============================================================
#  REFERENCIAS
# ============================================================
@onready var items_equipados: Node3D = $"../VisualRoot/ItemsEquipados"
@onready var visual_root: Node3D     = $"../VisualRoot"

# ============================================================
#  EXPORTS
# ============================================================
@export var stats_rueda_inicial: ItemsStats
@export var stats_arma_inicial: ItemsStats

# ============================================================
#  ESTADO
# ============================================================
var equipado: Dictionary       = {}
var buffs_activos: Dictionary  = {}
var jugador_stats: Stats
var velocidad_base: float      = 0.0
var arma_activa: ItemsStats    = null

# ============================================================
#  INICIALIZACIÓN
# ============================================================
func _ready() -> void:
	print("[Equipment] _ready iniciado")
	print("[Equipment] hijos de ItemsEquipados:")
	for hijo in items_equipados.get_children():
		print("  - ", hijo.name)
		hijo.hide()
	print("[Equipment] _ready completo — todo oculto")

func inicializar(stats: Stats, vel_base: float) -> void:
	jugador_stats  = stats
	velocidad_base = vel_base
	print("[Equipment] inicializado — vel_base: %.1f" % vel_base)

func equipar_inicio() -> void:
	print("[Equipment] equipando items iniciales...")
	if stats_rueda_inicial:
		_equipar_rueda("Rueda1", Vector3.ZERO, stats_rueda_inicial)
		print("[Equipment] rueda inicial equipada")
	else:
		push_warning("[Equipment] stats_rueda_inicial no asignado")
	if stats_arma_inicial:
		_equipar_arma("Metralleta", stats_arma_inicial)
		print("[Equipment] arma inicial equipada")
	else:
		push_warning("[Equipment] stats_arma_inicial no asignado")

# ============================================================
#  PUNTO DE ENTRADA PRINCIPAL
# ============================================================
func equipar(slot: String, nombre_item: String, drop_position: Vector3, item_stats: ItemsStats) -> void:
	if item_stats == null:
		print("[Equipment] equipar llamado con item_stats NULL — abortando")
		return
	print("[Equipment] equipar — slot: '%s' | item: '%s' | tipo: %d" % [slot, nombre_item, item_stats.tipo])
	match item_stats.tipo:
		ItemsStats.TipoItem.CONSUMIBLE_VIDA:
			_aplicar_vida(item_stats)
		ItemsStats.TipoItem.CONSUMIBLE_NITRO:
			_aplicar_nitro(item_stats)
		ItemsStats.TipoItem.CONSUMIBLE_CHATARRA:
			_aplicar_chatarra(item_stats)
		ItemsStats.TipoItem.ARMA:
			_equipar_arma(nombre_item, item_stats)
		ItemsStats.TipoItem.RUEDA:
			_equipar_rueda(nombre_item, drop_position, item_stats)
		ItemsStats.TipoItem.EQUIPABLE:
			_equipar_generico(slot, nombre_item, drop_position, item_stats)

# ============================================================
#  EQUIPABLES GENÉRICOS
# ============================================================
func _equipar_generico(slot: String, nombre_item: String, drop_position: Vector3, item_stats: ItemsStats) -> void:
	print("[Generico] equipando '%s' en slot '%s'" % [nombre_item, slot])
	if equipado.has(slot) and equipado[slot] != null:
		print("[Generico] swap — tirando al suelo: %s" % equipado[slot].name)
		_quitar_stats(slot)
		_tirar_al_suelo(equipado[slot].name, drop_position)
		equipado[slot].visible = false

	var nuevo = items_equipados.get_node_or_null(nombre_item)
	if nuevo == null:
		push_warning("[Generico] Item no encontrado en ItemsEquipados: %s" % nombre_item)
		return

	nuevo.visible  = true
	equipado[slot] = nuevo
	_aplicar_stats(item_stats, slot)
	print("[Generico] '%s' visible y equipado en slot '%s'" % [nombre_item, slot])

# ============================================================
#  ARMAS
# ============================================================
func _equipar_arma(nombre_item: String, item_stats: ItemsStats) -> void:
	print("[Arma] equipando '%s'" % nombre_item)
	if equipado.has("Arma") and equipado["Arma"] != null:
		print("[Arma] desactivando arma anterior: %s" % equipado["Arma"].name)
		if equipado["Arma"].has_method("desactivar"):
			equipado["Arma"].desactivar()

	var nuevo = items_equipados.get_node_or_null(nombre_item)
	if nuevo == null:
		push_warning("[Arma] no encontrada en ItemsEquipados: %s" % nombre_item)
		return

	if nuevo.has_method("activar"):
		nuevo.activar(item_stats)
		print("[Arma] activar() llamado")

	equipado["Arma"] = nuevo
	arma_activa      = item_stats
	print("[Arma] equipada: %s" % nombre_item)

# ============================================================
#  RUEDAS
# ============================================================
func _equipar_rueda(nombre_item: String, drop_position: Vector3, item_stats: ItemsStats) -> void:
	const SLOT := "Rueda"
	print("[Rueda] === equipando '%s' ===" % nombre_item)

	if equipado.has(SLOT) and equipado[SLOT] != null:
		print("[Rueda] tirando rueda anterior al suelo: %s" % equipado[SLOT])
		_quitar_stats(SLOT)
		_tirar_al_suelo(equipado[SLOT], drop_position)

	_ocultar_todas_las_ruedas()
	_mostrar_rueda(nombre_item)

	equipado[SLOT] = nombre_item
	_aplicar_stats_rueda(item_stats, SLOT)
	get_parent().ajustar_raycasts(nombre_item)
	print("[Rueda] equipada correctamente: %s" % nombre_item)

func _mostrar_rueda(nombre_item: String) -> void:
	print("[Rueda] buscando nodo '%s' en ItemsEquipados..." % nombre_item)
	var nodo = items_equipados.get_node_or_null(nombre_item)
	if nodo:
		nodo.visible = true
		print("[Rueda] nodo '%s' encontrado y visible = true" % nombre_item)
	else:
		push_warning("[Rueda] nodo '%s' NO encontrado en ItemsEquipados" % nombre_item)

func _ocultar_todas_las_ruedas() -> void:
	print("[Rueda] ocultando todas las ruedas...")
	for nombre in ["Rueda1", "Rueda2", "Rueda3"]:
		var nodo = items_equipados.get_node_or_null(nombre)
		if nodo:
			nodo.visible = false
			print("[Rueda] ocultado: %s" % nombre)
		else:
			print("[Rueda] no encontrado para ocultar: %s" % nombre)

# ============================================================
#  CONSUMIBLES
# ============================================================
func _aplicar_vida(item_stats: ItemsStats) -> void:
	if not jugador_stats:
		return
	var antes = jugador_stats.health
	jugador_stats.health += item_stats.vida_cantidad
	print("[Vida] +%d | %d -> %d/%d" % [item_stats.vida_cantidad, antes, jugador_stats.health, jugador_stats.current_max_health])

func _aplicar_nitro(item_stats: ItemsStats) -> void:
	print("[Nitro] activado por %.1fs x%.1f" % [item_stats.nitro_duracion, item_stats.nitro_multiplicador])
	get_parent().activar_nitro(item_stats.nitro_duracion, item_stats.nitro_multiplicador)

func _aplicar_chatarra(item_stats: ItemsStats) -> void:
	print("[Chatarra] +%d" % item_stats.chatarra_cantidad)
	Chatarra.agregar(item_stats.chatarra_cantidad)

# ============================================================
#  STATS / BUFFS
# ============================================================
func _aplicar_stats(item_stats: ItemsStats, slot: String) -> void:
	if not jugador_stats:
		return
	print("[Stats] aplicando stats para slot '%s'" % slot)
	var buffs: Array[StatBuff] = []

	if item_stats.bonus_damage != 0:
		buffs.append(_crear_buff(Stats.BuffableStats.ATTACK, item_stats.bonus_damage))
		print("[Stats] ATTACK +%d" % item_stats.bonus_damage)
	if item_stats.bonus_defense != 0:
		buffs.append(_crear_buff(Stats.BuffableStats.DEFENSE, item_stats.bonus_defense))
		print("[Stats] DEFENSE +%d" % item_stats.bonus_defense)
	if item_stats.bonus_ram_damage != 0:
		buffs.append(_crear_buff(Stats.BuffableStats.RAM_DAMAGE, item_stats.bonus_ram_damage))
		print("[Stats] RAM_DAMAGE +%d" % item_stats.bonus_ram_damage)
	if item_stats.bonus_speed != 0.0:
		buffs.append(_crear_buff_float(Stats.BuffableStats.SPEED, item_stats.bonus_speed))
		print("[Stats] SPEED +%.1f" % item_stats.bonus_speed)

	buffs_activos[slot] = buffs
	print("[Stats] resultado — ataque: %d | defensa: %d | vida: %d/%d" % [
		jugador_stats.current_attack,
		jugador_stats.current_defense,
		jugador_stats.health,
		jugador_stats.current_max_health,
	])

func _aplicar_stats_rueda(item_stats: ItemsStats, slot: String) -> void:
	if not jugador_stats:
		return
	print("[StatsRueda] aplicando para slot '%s'" % slot)
	var buffs: Array[StatBuff] = []

	if item_stats.bonus_speed != 0.0:
		buffs.append(_crear_buff_float(Stats.BuffableStats.SPEED, item_stats.bonus_speed))
		print("[StatsRueda] SPEED +%.1f" % item_stats.bonus_speed)
	if item_stats.bonus_defense != 0:
		buffs.append(_crear_buff(Stats.BuffableStats.DEFENSE, item_stats.bonus_defense))
		print("[StatsRueda] DEFENSE +%d" % item_stats.bonus_defense)

	buffs_activos[slot] = buffs
	print("[StatsRueda] resultado — defensa: %d" % jugador_stats.current_defense)

func _quitar_stats(slot: String) -> void:
	if not jugador_stats or not buffs_activos.has(slot):
		print("[Stats] nada que quitar en slot '%s'" % slot)
		return
	print("[Stats] quitando buffs de slot '%s'" % slot)
	for buff in buffs_activos[slot]:
		jugador_stats.remove_buff(buff)
	buffs_activos.erase(slot)
	print("[Stats] removidos — ataque: %d | defensa: %d | vida: %d/%d" % [
		jugador_stats.current_attack,
		jugador_stats.current_defense,
		jugador_stats.health,
		jugador_stats.current_max_health,
	])

func _crear_buff(stat: Stats.BuffableStats, valor: int) -> StatBuff:
	var b = StatBuff.new(stat, valor, StatBuff.BuffType.ADD)
	jugador_stats.add_buff(b)
	return b

func _crear_buff_float(stat: Stats.BuffableStats, valor: float) -> StatBuff:
	var b = StatBuff.new(stat, valor, StatBuff.BuffType.ADD)
	jugador_stats.add_buff(b)
	return b

# ============================================================
#  UTILIDADES
# ============================================================
func _tirar_al_suelo(nombre: String, position: Vector3) -> void:
	print("[Suelo] tirando '%s' en %s" % [nombre, position])
	if not ItemPool.item_paths.has(nombre):
		push_warning("[Suelo] no hay path para: %s" % nombre)
		return
	var scene = load(ItemPool.item_paths[nombre]) as PackedScene
	if scene == null:
		push_warning("[Suelo] escena null para: %s" % nombre)
		return
	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = position + Vector3(0, 0.5, 0)
	print("[Suelo] '%s' instanciado en %s" % [nombre, instance.global_position])
