extends Node

var item_paths := {
	"FolaCapo": "res://Entidades/Items/Capo/Folacapo/FolaCapo.tscn",
	"TuboCapo": "res://Entidades/Items/Capo/Number2/TuboCapo.tscn",
	"Parachoque": "res://Entidades/Items/ArmaFrontal/Parachoque/parachoque.tscn",
	"Chapa": "res://Entidades/Items/Chatarra/Chapa/chapa.tscn",
	"Clavo": "res://Entidades/Items/Chatarra/Clavo/clavo.tscn",
	"Tuerca": "res://Entidades/Items/Chatarra/Tuerca/tuerca.tscn",
	"Nitro": "res://Entidades/Items/Gasolina/Nitro/nitro.tscn",
	"VidaChica": "res://Entidades/Items/Gasolina/VidaChica/vida_chica.tscn",
	"VidaMediana": "res://Entidades/Items/Gasolina/VidaMediana/vida_mediana.tscn",
	"Metralleta": "res://Entidades/Items/ArmaMetralleta/metralleta_item.tscn",
	"Cañon": "res://Entidades/Items/ArmaCañon/Torreta/cañon_item.tscn",
}

func get_random_item() -> PackedScene:
	if item_paths.is_empty():
		return null
	var keys = item_paths.keys()
	var key = keys[randi() % keys.size()]
	return load(item_paths[key]) as PackedScene
