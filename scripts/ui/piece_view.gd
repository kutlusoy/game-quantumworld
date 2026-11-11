extends Node2D

var piece := 0
var cell_size := 80.0
var palette: Array = []

func setup(p: int, size: float, pal: Array) -> void:
	piece = p
	cell_size = size
	palette = pal
	queue_redraw()

func _draw() -> void:
	var r := cell_size * 0.4
	var special := piece >> 4
	var color_id := piece & 15
	if special == 3:
		for i in 6:
			draw_arc(Vector2.ZERO, r * (1.0 - i * 0.13), 0.0, TAU, 40, palette[i], r * 0.16)
		draw_circle(Vector2.ZERO, r * 0.2, Color.WHITE)
		return
	var base: Color = palette[color_id]
	draw_circle(Vector2.ZERO, r, base.darkened(0.3))
	draw_circle(Vector2(0, -r * 0.06), r * 0.92, base)
	draw_circle(Vector2(-r * 0.3, -r * 0.38), r * 0.2, Color(1, 1, 1, 0.55))
	_draw_glyph(color_id, r * 0.34)
	if special == 1:
		draw_rect(Rect2(-r * 0.85, -r * 0.09, r * 1.7, r * 0.18), Color(1, 1, 1, 0.95))
	elif special == 2:
		draw_rect(Rect2(-r * 0.09, -r * 0.85, r * 0.18, r * 1.7), Color(1, 1, 1, 0.95))

func _draw_glyph(color_id: int, s: float) -> void:
	var c := Color(1, 1, 1, 0.8)
	match color_id:
		0:
			draw_circle(Vector2.ZERO, s * 0.7, c)
		1:
			draw_rect(Rect2(-s * 0.6, -s * 0.6, s * 1.2, s * 1.2), c)
		2:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(s, s * 0.7), Vector2(-s, s * 0.7)]), c)
		3:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)]), c)
		4:
			draw_arc(Vector2.ZERO, s * 0.7, 0.0, TAU, 24, c, s * 0.3)
		5:
			draw_rect(Rect2(-s * 0.2, -s, s * 0.4, s * 2.0), c)
			draw_rect(Rect2(-s, -s * 0.2, s * 2.0, s * 0.4), c)
