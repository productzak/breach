extends BaseRoom

var _warden: Node = null
var _room_cleared := false
var _check_delay := 2.5

func _on_room_ready() -> void:
	_add_arena_visuals()
	call_deferred("_spawn_warden")

func _add_arena_visuals() -> void:
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a) * 200.0, sin(a) * 200.0))
	ring.polygon = pts
	ring.color = Color(0.7, 0.45, 0.05, 0.10)
	ring.position = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)
	add_child(ring)

	var lbl := Label.new()
	lbl.text = "WARDEN"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.05, 0.55))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(ROOM_W / 2.0 - 120, 80)
	lbl.size = Vector2(240, 22)
	add_child(lbl)

func _spawn_warden() -> void:
	var warden_scene := load("res://scenes/enemies/Warden.tscn") as PackedScene
	_warden = warden_scene.instantiate()
	_warden.position = Vector2(ROOM_W * 0.62, ROOM_H / 2.0)
	_warden.bullet_scene = load("res://scenes/projectiles/EnemyBullet.tscn")
	add_child(_warden)

func _process(delta: float) -> void:
	super._process(delta)
	if _room_cleared:
		return
	if _check_delay > 0.0:
		_check_delay -= delta
		return
	if not is_instance_valid(_warden) and get_tree().get_nodes_in_group("enemies").is_empty():
		_room_cleared = true
		RunManager.on_warden_defeated()
