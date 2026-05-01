extends Node2D

var base_color: Color = Color(1.0, 0.3, 0.1)

func _ready() -> void:
	_shatter()
	get_tree().create_timer(0.55).timeout.connect(queue_free)

func _shatter() -> void:
	var count := 8
	for i in count:
		var angle := TAU * i / float(count)
		var a1 := angle - PI / count
		var a2 := angle + PI / count
		var r := 10.0
		var frag := Polygon2D.new()
		frag.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(cos(a1) * r, sin(a1) * r),
			Vector2(cos(a2) * r, sin(a2) * r),
		])
		frag.color = base_color
		add_child(frag)
		var fly := Vector2(cos(angle), sin(angle)) * randf_range(28.0, 55.0)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(frag, "position", fly, 0.5)
		t.tween_property(frag, "modulate:a", 0.0, 0.5)
