extends Node

signal chatarra_changed(cantidad: int)

var cantidad: int = 0

func agregar(valor: int) -> void:
	cantidad += valor
	chatarra_changed.emit(cantidad)
	print("Chatarra total: %d" % cantidad)
