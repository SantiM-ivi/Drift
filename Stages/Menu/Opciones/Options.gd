extends Control

# ─────────────────────────────────────────
#  DRIFT - Options Menu
#  Godot 4.6
# ─────────────────────────────────────────

@onready var slider_musica   : HSlider  = $CenterContainer/Panel/VBoxContainer/RowMusica/SliderMusica
@onready var slider_sfx      : HSlider  = $CenterContainer/Panel/VBoxContainer/RowSFX/SliderSFX
@onready var check_fullscreen: CheckBox = $CenterContainer/Panel/VBoxContainer/RowFullscreen/CheckFullscreen
@onready var btn_volver      : Button   = $CenterContainer/Panel/VBoxContainer/BtnVolver
@onready var lbl_musica_val  : Label    = $CenterContainer/Panel/VBoxContainer/RowMusica/LblMusicaVal
@onready var lbl_sfx_val     : Label    = $CenterContainer/Panel/VBoxContainer/RowSFX/LblSFXVal

const SCENE_MENU := "res://Stages/Menu/MainMenu.tscn"

# Bus de audio — verificá que coincidan con los nombres en Project > Audio
const BUS_MUSICA := "Music"
const BUS_SFX    := "SFX"

func _ready() -> void:
	_cargar_ajustes()

	slider_musica.value_changed.connect(_on_musica_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)
	btn_volver.pressed.connect(_on_volver_pressed)

# ── Carga valores guardados (o defaults) ─

func _cargar_ajustes() -> void:
	var vol_musica : float = ProjectSettings.get_setting("drift/vol_musica", 0.8)
	var vol_sfx    : float = ProjectSettings.get_setting("drift/vol_sfx",    0.8)
	var fullscreen : bool  = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	slider_musica.value = vol_musica
	slider_sfx.value    = vol_sfx
	check_fullscreen.button_pressed = fullscreen

	lbl_musica_val.text = "%d%%" % int(vol_musica * 100)
	lbl_sfx_val.text    = "%d%%" % int(vol_sfx * 100)

	_aplicar_volumen(BUS_MUSICA, vol_musica)
	_aplicar_volumen(BUS_SFX,    vol_sfx)

# ── Callbacks ────────────────────────────

func _on_musica_changed(value: float) -> void:
	lbl_musica_val.text = "%d%%" % int(value * 100)
	_aplicar_volumen(BUS_MUSICA, value)
	_guardar("drift/vol_musica", value)

func _on_sfx_changed(value: float) -> void:
	lbl_sfx_val.text = "%d%%" % int(value * 100)
	_aplicar_volumen(BUS_SFX, value)
	_guardar("drift/vol_sfx", value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_guardar("drift/fullscreen", pressed)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_MENU)

# ── Helpers ──────────────────────────────

func _aplicar_volumen(bus_name: String, valor: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("Audio bus '%s' no encontrado. Crealo en Project > Audio." % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(valor))
	AudioServer.set_bus_mute(idx, valor == 0.0)

func _guardar(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()
