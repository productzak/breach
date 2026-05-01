extends Node2D

const GLITCH_COLORS := [
	Color(0.0, 1.0, 0.45),   # acid green
	Color(1.0, 0.1, 0.55),   # hot pink
	Color(0.15, 0.6, 1.0),   # electric blue
]

func _ready() -> void:
	for i in 14:
		var rect := ColorRect.new()
		var w := randf_range(5.0, 24.0)
		var h := randf_range(1.5, 5.0)
		rect.size = Vector2(w, h)
		rect.color = GLITCH_COLORS[randi() % GLITCH_COLORS.size()]
		rect.position = Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
		rect.modulate.a = randf_range(0.6, 1.0)
		add_child(rect)
		var drift := Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(rect, "position", rect.position + drift, 0.22)
		t.tween_property(rect, "modulate:a", 0.0, 0.22)
	get_tree().create_timer(0.25).timeout.connect(queue_free)
