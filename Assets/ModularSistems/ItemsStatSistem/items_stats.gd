extends Resource
class_name ItemsStats

enum TipoItem {
	EQUIPABLE,
	CONSUMIBLE_VIDA,
	CONSUMIBLE_NITRO,
	CONSUMIBLE_CHATARRA,
}

@export var tipo: TipoItem = TipoItem.EQUIPABLE

# Stats equipables
@export var bonus_damage: int = 0
@export var bonus_defense: int = 0
@export var bonus_speed: float = 0.0
@export var bonus_ram_damage: int = 5

# Consumibles
@export var vida_cantidad: int = 0       # cuánto cura
@export var nitro_duracion: float = 0.0  # segundos de boost
@export var nitro_multiplicador: float = 1.5
@export var chatarra_cantidad: int = 0   # cuánto da a la economía
