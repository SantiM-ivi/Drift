extends Control

# ─────────────────────────────────────────
#  DRIFT - Main Menu
#  Godot 4.6
# ─────────────────────────────────────────

@onready var btn_jugar   : Button = $CenterContainer/VBoxContainer/BtnJugar
@onready var btn_opciones: Button = $CenterContainer/VBoxContainer/BtnOpciones
@onready var btn_salir   : Button = $CenterContainer/VBoxContainer/BtnSalir
@onready var anim        : AnimationPlayer = $AnimationPlayer

# Ruta a tu escena de juego — ajustala si es distinta
const SCENE_JUEGO   := "res://Stages/Levels/ToyBox/ToyBox.tscn"
# Opciones todavía no existe, la creamos como placeholder
const SCENE_OPCIONES := "res://Stages/Menu/Opciones/Options.tscn"

func _ready() -> void:
	btn_jugar.pressed.connect(_on_jugar_pressed)
	btn_opciones.pressed.connect(_on_opciones_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)

	# Animación de entrada si existe
	if anim:
		anim.play("intro")

# ── Botones ──────────────────────────────

func _on_jugar_pressed() -> void:
	_cambiar_escena(SCENE_JUEGO)

func _on_opciones_pressed() -> void:
	_cambiar_escena(SCENE_OPCIONES)

func _on_salir_pressed() -> void:
	get_tree().quit()

# ── Helpers ──────────────────────────────

func _cambiar_escena(path: String) -> void:
	# Pequeño fade antes de cambiar (opcional)
	if anim and anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished
	get_tree().change_scene_to_file(path)
