extends Node2D

func _ready() -> void:
	for i in 7:
		var angle := TAU * i / 7.0 + randf_range(-0.2, 0.2)
		var dist := randf_range(12.0, 28.0)
		var frag := Polygon2D.new()
		frag.polygon = PackedVector2Array([
			Vector2(0.0, -4.0),
			Vector2(2.5, 0.0),
			Vector2(0.0, 4.0),
			Vector2(-2.5, 0.0),
		])
		frag.color = Color(0.95, 0.82, 0.1)
		frag.rotation = angle
		add_child(frag)
		var target := Vector2(cos(angle), sin(angle)) * dist
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(frag, "position", target, 0.45)
		t.tween_property(frag, "modulate:a", 0.0, 0.45)
	get_tree().create_timer(0.48).timeout.connect(queue_free)
