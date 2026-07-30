extends Node

# ─── STATS DE PARTIDA ─────────────────────────────────────────────────────────

var oleadas_sobrevividas: int  = 0
var enemigos_eliminados: int   = 0
var chatarra_recolectada: int  = 0
var dano_recibido: int         = 0
var dano_hecho: int            = 0
var tiempo_inicio: float       = 0.0
var tiempo_total: float        = 0.0  # se fija al morir

# ─── CONTROL ──────────────────────────────────────────────────────────────────

func reiniciar() -> void:
	oleadas_sobrevividas = 0
	enemigos_eliminados  = 0
	chatarra_recolectada = 0
	dano_recibido        = 0
	dano_hecho           = 0
	tiempo_inicio        = Time.get_ticks_msec() / 1000.0
	tiempo_total         = 0.0

func fijar_tiempo_final() -> void:
	tiempo_total = (Time.get_ticks_msec() / 1000.0) - tiempo_inicio

func get_tiempo_formateado() -> String:
	var t  = int(tiempo_total)
	var m  = t / 60
	var s  = t % 60
	return "%02d:%02d" % [m, s]
