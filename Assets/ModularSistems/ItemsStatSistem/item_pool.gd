extends Node

var item_paths := {
	"Capo":  "res://Entidades/Items/Capos/Capo/Capo.tscn",
	"FolaCapo": "res://Entidades/Items/Capos/Folacapo/FolaCapo.tscn",
	"TuboCapo": "res://Entidades/Items/Capos/TuboCapo/TuboCapo.tscn",
	"Parachoque": "res://Entidades/Items/ArmaFrontal/Parachoque/parachoque.tscn",
	"Chapa": "res://Entidades/Items/Chatarra/Chapa/chapa.tscn",
	"Clavo": "res://Entidades/Items/Chatarra/Clavo/clavo.tscn",
	"Tuerca": "res://Entidades/Items/Chatarra/Tuerca/tuerca.tscn",
	"Nitro": "res://Entidades/Items/Gasolina/Nitro/nitro.tscn",
	"VidaChica": "res://Entidades/Items/Gasolina/VidaChica/vida_chica.tscn",
	"VidaMediana": "res://Entidades/Items/Gasolina/VidaMediana/vida_mediana.tscn",
	"Metralleta": "res://Entidades/Items/ArmaMetralleta/metralleta_item.tscn",
	"Cañon": "res://Entidades/Items/ArmaCañon/Torreta/cañon_item.tscn",
	"Escopeta": "res://Entidades/Items/ArmaEscopeta/escopeta_item.tscn",
	"Rueda1": "res://Entidades/Items/Ruedas/Rueda1/rueda1.tscn",
	"Rueda2": "res://Entidades/Items/Ruedas/Rueda2/rueda2.tscn",
	"Rueda3": "res://Entidades/Items/Ruedas/Rueda3/rueda3.tscn",
}



func get_random_item() -> PackedScene:
	if item_paths.is_empty():
		return null
	var keys = item_paths.keys()
	var key = keys[randi() % keys.size()]
	return load(item_paths[key]) as PackedScene
