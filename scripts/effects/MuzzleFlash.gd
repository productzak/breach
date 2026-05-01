extends Node2D

func _ready() -> void:
	var count := randi_range(4, 6)
	for i in count:
		var angle := randf_range(0.0, TAU)
		var length := randf_range(5.0, 11.0)
		var frag := Polygon2D.new()
		frag.polygon = PackedVector2Array([
			Vector2(-1.0, -1.0),
			Vector2(length, 0.0),
			Vector2(-1.0, 1.0),
		])
		frag.rotation = angle
		frag.color = Color(0.1, 1.0, 0.85, 0.9)
		add_child(frag)
		var t := create_tween()
		t.set_parallel(true)
		var fly := Vector2(cos(angle), sin(angle)) * randf_range(6.0, 14.0)
		t.tween_property(frag, "position", fly, 0.11)
		t.tween_property(frag, "modulate:a", 0.0, 0.11)
	get_tree().create_timer(0.13).timeout.connect(queue_free)
