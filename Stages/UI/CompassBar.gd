extends Control

# ── Configuración visual ──
@export var bar_color: Color       = Color(0.18, 1.0, 0.18, 1.0)
@export var tick_color: Color      = Color(0.18, 1.0, 0.18, 0.6)
@export var cardinal_color: Color  = Color(1.0, 0.3, 0.3, 1.0)
@export var text_color: Color      = Color(0.18, 1.0, 0.18, 1.0)
@export var marker_color: Color    = Color(1.0, 1.0, 1.0, 1.0)
@export var font_size: int         = 12

# Ángulo actual en grados (0 = Norte, 90 = Este, 180 = Sur, 270 = Oeste)
var angle_deg: float = 0.0

# Cardinales cada 45°
const CARDINALS = {
	0:   "N",
	45:  "NE",
	90:  "E",
	135: "SE",
	180: "S",
	225: "SO",
	270: "O",
	315: "NO",
}

# Cuántos grados se muestran en total en la barra
const FIELD_OF_VIEW: float = 90.0

func set_angle(deg: float) -> void:
	angle_deg = fmod(deg, 360.0)
	if angle_deg < 0:
		angle_deg += 360.0
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var center_x = w * 0.5
	var half_fov = FIELD_OF_VIEW * 0.5

	# ── Línea base ──
	draw_line(Vector2(0, h * 0.45), Vector2(w, h * 0.45), bar_color, 1.5)

	# ── Ticks y etiquetas ──
	for step in range(-180, 181, 5):
		var world_deg = fmod(angle_deg + step + 360.0, 360.0)
		var rounded = round(world_deg / 5.0) * 5.0
		if abs(step) > half_fov:
			continue

		var px = center_x + (step / half_fov) * center_x
		var is_cardinal = int(rounded) % 45 == 0
		var is_mid = int(rounded) % 10 == 0

		if is_cardinal:
			# Tick largo
			draw_line(Vector2(px, h * 0.18), Vector2(px, h * 0.45), cardinal_color, 2.0)
			# Etiqueta
			var label = CARDINALS.get(int(rounded), "")
			var font = ThemeDB.fallback_font
			var label_w = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var col = cardinal_color if label == "N" else text_color
			draw_string(font, Vector2(px - label_w * 0.5, h * 0.15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
		elif is_mid:
			# Tick mediano
			draw_line(Vector2(px, h * 0.32), Vector2(px, h * 0.45), tick_color, 1.0)
		else:
			# Tick pequeño
			draw_line(Vector2(px, h * 0.38), Vector2(px, h * 0.45), tick_color * Color(1,1,1,0.4), 1.0)

	# ── Marcador central (triángulo apuntando hacia abajo) ──
	var tip    = Vector2(center_x, h * 0.45)
	var left   = Vector2(center_x - 5, h * 0.28)
	var right  = Vector2(center_x + 5, h * 0.28)
	draw_colored_polygon([tip, left, right], marker_color)

	# ── Grados actuales abajo del marcador ──
	var deg_str = "%d°" % int(angle_deg)
	var font = ThemeDB.fallback_font
	var deg_w = font.get_string_size(deg_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x
	draw_string(font, Vector2(center_x - deg_w * 0.5, h * 0.95), deg_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, text_color * Color(1,1,1,0.6))
