extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _draw() -> void:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y
	var y := 0.0
	while y < h:
		draw_line(Vector2(0.0, y), Vector2(w, y), Color(0.0, 0.0, 0.0, 0.07), 1.0)
		y += 3.0
