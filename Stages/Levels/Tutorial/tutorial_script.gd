extends Control

@onready var hud            : CanvasLayer = $HUD  
@onready var mission_label  : Label = $HUD/TopLeft/Content/MissionTitle

const SCENE_JUEGO := "res://Stages/Levels/ToyBox/ToyBox.tscn"

var missions: Array[Dictionary] = [
	{
		"id": "mover",
		"texto": "Movete por el escenario",
		"hint": "Flechas / WASD",
		"actions": ["ui_up", "ui_down", "ui_left", "ui_right"],
		"require_all": true,
	},
	{
		"id": "disparar",
		"texto": "Probá tu arma",
		"hint": "Click Izquierdo / F",
		"actions": ["shoot"],
		"require_all": false,
	},
	{
		"id": "turbo",
		"texto": "Activá el turbo",
		"hint": "Shift",
		"actions": ["boost"],
		"require_all": false,
	},
	{
		"id": "radio",
		"texto": "Prendé la radio",
		"hint": "U",
		"actions": [],
		"require_all": false,
		"key": KEY_U,
	},
	{
		"id": "bocina",
		"texto": "Tocá la bocina",
		"hint": "Espacio",
		"actions": ["Bocina"],
		"require_all": false,
	},
]

var current_index: int = 0
var _done_actions: Dictionary = {}   # trackea qué actions/keys ya se usaron en la misión actual
var _finished: bool = false

func _ready() -> void:
	_start_mission(0)

func _input(event: InputEvent) -> void:
	if _finished or current_index >= missions.size():
		return
	var mission: Dictionary = missions[current_index]
	var key: Variant = mission.get("key", null)
	if key != null and event is InputEventKey and event.keycode == key and event.pressed and not event.echo:
		_done_actions["_key"] = true

func _process(_delta: float) -> void:
	if _finished or current_index >= missions.size():
		return

	var mission: Dictionary = missions[current_index]
	var actions: Array = mission["actions"]

	for action in actions:
		if not _done_actions.get(action, false) and Input.is_action_just_pressed(action):
			_done_actions[action] = true

	if _mission_complete(mission):
		_next_mission()

# ── Lógica de misiones ───────────────────
func _mission_complete(mission: Dictionary) -> bool:
	var actions: Array = mission["actions"]
	var key: Variant = mission.get("key", null)

	if key != null:
		return _done_actions.get("_key", false)

	if mission.get("require_all", false):
		for action in actions:
			if not _done_actions.get(action, false):
				return false
		return true
	else:
		for action in actions:
			if _done_actions.get(action, false):
				return true
		return false

func _start_mission(index: int) -> void:
	current_index = index
	_done_actions.clear()
	var mission: Dictionary = missions[index]
	if mission_label:
		mission_label.text = "(%d/%d) %s — %s" % [
			index + 1, missions.size(), mission["texto"], mission["hint"]
		]

func _next_mission() -> void:
	if current_index + 1 < missions.size():
		_start_mission(current_index + 1)
	else:
		_finish_tutorial()

func _finish_tutorial() -> void:
	_finished = true
	if mission_label:
		mission_label.text = "¡Listo! Vamos a la pista..."
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(SCENE_JUEGO)
