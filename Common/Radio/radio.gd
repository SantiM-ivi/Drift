# radio.gd
extends Node

@export var canciones: Array[AudioStream] = []

var _encendida: bool = false
var _indice: int = 0
var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	print("[Radio] Apagada. U = encender/apagar | I = cambiar canción")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return
	if Input.is_key_pressed(KEY_U) and event is InputEventKey and event.keycode == KEY_U and event.pressed and not event.echo:
		_toggle_encendido()
	
	if Input.is_key_pressed(KEY_I) and event is InputEventKey and event.keycode == KEY_I and event.pressed and not event.echo:
		if _encendida:
			_siguiente_cancion()
		else:
			print("[Radio] Está apagada.")

func _toggle_encendido() -> void:
	_encendida = not _encendida
	if _encendida:
		_reproducir(_indice)
		print("[Radio] Encendida 🔊 - Canción ", _indice + 1, " de ", canciones.size())
	else:
		_player.stop()
		print("[Radio] Apagada 📻")

func _siguiente_cancion() -> void:
	_indice = (_indice + 1) % canciones.size()
	_reproducir(_indice)
	print("[Radio] Canción ", _indice + 1, " de ", canciones.size())

func _reproducir(indice: int) -> void:
	if canciones.is_empty():
		print("[Radio] No hay canciones cargadas.")
		return
	_player.stream = canciones[indice]
	_player.play()
