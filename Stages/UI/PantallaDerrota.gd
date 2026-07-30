extends CanvasLayer

const PATH_MENU: String = "res://Stages/Menu/MainMenu.tscn"

@onready var btn_reintentar: Button = $Panel/VBox/BtnReintentar
@onready var btn_menu: Button       = $Panel/VBox/BtnMenu

# Labels de stats — creá estos nodos en la escena bajo Panel/VBox/Stats/
@onready var lbl_oleadas:   Label = $Panel/VBox/Stats/LblOleadas
@onready var lbl_enemigos:  Label = $Panel/VBox/Stats/LblEnemigos
@onready var lbl_chatarra:  Label = $Panel/VBox/Stats/LblChatarra
@onready var lbl_dano_hecho:    Label = $Panel/VBox/Stats/LblDanoHecho
@onready var lbl_dano_recibido: Label = $Panel/VBox/Stats/LblDanoRecibido
@onready var lbl_tiempo:    Label = $Panel/VBox/Stats/LblTiempo

var _mouse_mode_previo: Input.MouseMode

func _ready() -> void:
	_mouse_mode_previo = Input.mouse_mode
	Input.mouse_mode   = Input.MOUSE_MODE_VISIBLE
	get_tree().paused  = true
	process_mode       = Node.PROCESS_MODE_ALWAYS

	btn_reintentar.pressed.connect(_on_reintentar)
	btn_menu.pressed.connect(_on_menu)
	btn_reintentar.grab_focus()

	_mostrar_stats()

func _mostrar_stats() -> void:
	if lbl_oleadas:
		lbl_oleadas.text        = "Oleadas sobrevividas: %d"  % GameStats.oleadas_sobrevividas
	if lbl_enemigos:
		lbl_enemigos.text       = "Enemigos eliminados: %d"   % GameStats.enemigos_eliminados
	if lbl_chatarra:
		lbl_chatarra.text       = "Chatarra recolectada: %d"  % GameStats.chatarra_recolectada
	if lbl_dano_hecho:
		lbl_dano_hecho.text     = "Daño hecho: %d"            % GameStats.dano_hecho
	if lbl_dano_recibido:
		lbl_dano_recibido.text  = "Daño recibido: %d"         % GameStats.dano_recibido
	if lbl_tiempo:
		lbl_tiempo.text         = "Tiempo: %s"                % GameStats.get_tiempo_formateado()

func _on_reintentar() -> void:
	Input.mouse_mode  = _mouse_mode_previo
	get_tree().paused = false
	GameStats.reiniciar()
	queue_free()
	get_tree().reload_current_scene()

func _on_menu() -> void:
	Input.mouse_mode  = _mouse_mode_previo
	get_tree().paused = false
	GameStats.reiniciar()
	queue_free()
	get_tree().change_scene_to_file(PATH_MENU)
