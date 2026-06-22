extends CanvasLayer

const PATH_MENU: String = "res://Stages/Menu/MainMenu.tscn"

@onready var btn_reintentar: Button = $Panel/VBox/BtnReintentar
@onready var btn_menu: Button       = $Panel/VBox/BtnMenu

var _mouse_mode_previo: Input.MouseMode

func _ready() -> void:
	_mouse_mode_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)
	btn_reintentar.grab_focus()

func _on_reintentar() -> void:
	Input.mouse_mode = _mouse_mode_previo
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()

func _on_menu() -> void:
	Input.mouse_mode = _mouse_mode_previo
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file(PATH_MENU)
