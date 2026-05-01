extends Node2D

var _lbl: Label = null

func _ready() -> void:
	_lbl = Label.new()
	_lbl.add_theme_font_size_override("font_size", 13)
	_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	_lbl.position = Vector2(-10.0, -8.0)
	add_child(_lbl)

func setup(amount: int) -> void:
	if _lbl == null:
		return
	_lbl.text = str(amount)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "position", position + Vector2(randf_range(-8.0, 8.0), -44.0), 0.72)
	t.tween_property(self, "modulate:a", 0.0, 0.72)
	get_tree().create_timer(0.75).timeout.connect(queue_free)
