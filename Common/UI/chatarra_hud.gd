extends Label

func _ready() -> void:
	Chatarra.chatarra_changed.connect(_on_chatarra_changed)
	text = "Chatarra: 0"

func _on_chatarra_changed(cantidad: int) -> void:
	text = "Chatarra: %d" % cantidad
