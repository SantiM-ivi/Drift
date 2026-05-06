extends Node
class_name PlayerEquipment

@onready var items_equipados: Node3D = $"../VisualRoot/ItemsEquipados"

var equipado: Dictionary = {}
var buffs_activos: Dictionary = {}
var jugador_stats: Stats
var velocidad_base: float = 0.0
var arma_activa: ItemsStats = null

func _ready() -> void:
	for item in items_equipados.get_children():
		item.hide()

func inicializar(stats: Stats, vel_base: float) -> void:
	jugador_stats = stats
	velocidad_base = vel_base

func equipar(slot: String, nombre_item: String, drop_position: Vector3, item_stats: ItemsStats) -> void:
	print("equipar llamado — slot: ", slot, " | item: ", nombre_item, " | tipo: ", item_stats.tipo if item_stats else "NULL")
	if item_stats == null:
		return
	match item_stats.tipo:
		ItemsStats.TipoItem.CONSUMIBLE_VIDA:
			_aplicar_vida(item_stats)
			return
		ItemsStats.TipoItem.CONSUMIBLE_NITRO:
			_aplicar_nitro(item_stats)
			return
		ItemsStats.TipoItem.CONSUMIBLE_CHATARRA:
			_aplicar_chatarra(item_stats)
			return
		ItemsStats.TipoItem.ARMA:
			_equipar_arma(nombre_item, item_stats)
			return

	# Equipable — hacer swap
	if equipado.has(slot) and equipado[slot] != null:
		_quitar_stats(slot)
		_tirar_al_suelo(equipado[slot].name, drop_position)
		equipado[slot].visible = false

	var nuevo = items_equipados.get_node_or_null(nombre_item)
	if nuevo == null:
		push_warning("Item no encontrado: %s" % nombre_item)
		return

	nuevo.visible = true
	equipado[slot] = nuevo
	_aplicar_stats(item_stats, slot)

func _equipar_arma(nombre_item: String, item_stats: ItemsStats) -> void:
	print("buscando arma: ", nombre_item)
	print("hijos de items_equipados: ")
	for hijo in items_equipados.get_children():
		print("  - ", hijo.name)
	if equipado.has("Arma") and equipado["Arma"] != null:
		if equipado["Arma"].has_method("desactivar"):
			equipado["Arma"].desactivar()

	var nuevo = items_equipados.get_node_or_null(nombre_item)
	if nuevo == null:
		push_warning("Arma no encontrada: %s" % nombre_item)
		return

	if nuevo.has_method("activar"):
		nuevo.activar(item_stats)

	equipado["Arma"] = nuevo
	arma_activa = item_stats
	print("Arma equipada: %s" % nombre_item)

func _aplicar_stats(item_stats: ItemsStats, slot: String) -> void:
	if not jugador_stats:
		return
	var buffs: Array[StatBuff] = []
	if item_stats.bonus_damage != 0:
		var b = StatBuff.new(Stats.BuffableStats.ATTACK, item_stats.bonus_damage, StatBuff.BuffType.ADD)
		jugador_stats.add_buff(b)
		buffs.append(b)
	if item_stats.bonus_defense != 0:
		var b = StatBuff.new(Stats.BuffableStats.DEFENSE, item_stats.bonus_defense, StatBuff.BuffType.ADD)
		jugador_stats.add_buff(b)
		buffs.append(b)
	if item_stats.bonus_ram_damage != 0:
		var b = StatBuff.new(Stats.BuffableStats.RAM_DAMAGE, item_stats.bonus_ram_damage, StatBuff.BuffType.ADD)
		jugador_stats.add_buff(b)
		buffs.append(b)
	buffs_activos[slot] = buffs
	print("Stats aplicados — slot: %s | ataque: %d | defensa: %d | vida: %d/%d" % [
		slot,
		jugador_stats.current_attack,
		jugador_stats.current_defense,
		jugador_stats.health,
		jugador_stats.current_max_health
	])

func _quitar_stats(slot: String) -> void:
	if not jugador_stats or not buffs_activos.has(slot):
		return
	for buff in buffs_activos[slot]:
		jugador_stats.remove_buff(buff)
	buffs_activos.erase(slot)
	print("Stats removidos — slot: %s | ataque: %d | defensa: %d | vida: %d/%d" % [
		slot,
		jugador_stats.current_attack,
		jugador_stats.current_defense,
		jugador_stats.health,
		jugador_stats.current_max_health
	])

func _aplicar_vida(item_stats: ItemsStats) -> void:
	if not jugador_stats:
		return
	jugador_stats.health += item_stats.vida_cantidad
	print("Vida recuperada: +%d | vida actual: %d/%d" % [
		item_stats.vida_cantidad,
		jugador_stats.health,
		jugador_stats.current_max_health
	])

func _aplicar_nitro(item_stats: ItemsStats) -> void:
	print("Nitro activado por %.1f segundos" % item_stats.nitro_duracion)
	get_parent().activar_nitro(item_stats.nitro_duracion, item_stats.nitro_multiplicador)

func _aplicar_chatarra(item_stats: ItemsStats) -> void:
	Chatarra.agregar(item_stats.chatarra_cantidad)

func _tirar_al_suelo(nombre: String, position: Vector3) -> void:
	if not ItemPool.item_paths.has(nombre):
		push_warning("No hay path para tirar: %s" % nombre)
		return
	var scene = load(ItemPool.item_paths[nombre]) as PackedScene
	if scene == null:
		return
	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = position + Vector3(0, 0.5, 0)
