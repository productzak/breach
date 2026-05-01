extends BaseRoom

var _overseer: Node = null
var _room_cleared := false
var _check_delay := 2.5

func _on_room_ready() -> void:
	_add_boss_arena_visuals()
	call_deferred("_spawn_boss")

func _add_boss_arena_visuals() -> void:
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a) * 210.0, sin(a) * 210.0))
	ring.polygon = pts
	ring.color = Color(0.55, 0.05, 0.75, 0.10)
	ring.position = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)
	add_child(ring)

	var lbl := Label.new()
	lbl.text = "OVERSEER"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.1, 0.85, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(ROOM_W / 2.0 - 120, 80)
	lbl.size = Vector2(240, 20)
	add_child(lbl)

func _spawn_boss() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0
	var bullet_tscn := load("res://scenes/projectiles/EnemyBullet.tscn")

	var overseer_scene := load("res://scenes/enemies/Overseer.tscn") as PackedScene
	_overseer = overseer_scene.instantiate()
	_overseer.position = Vector2(cx + 180, cy)
	_overseer.bullet_scene = bullet_tscn
	add_child(_overseer)

	var turret_scene := load("res://scenes/enemies/Turret.tscn") as PackedScene
	for pos in [Vector2(cx + 380, cy - 200), Vector2(cx + 380, cy + 200)]:
		var t := turret_scene.instantiate()
		t.position = pos
		t.bullet_scene = bullet_tscn
		add_child(t)

	var terminal_scene := load("res://scenes/enemies/OverseerTerminal.tscn") as PackedScene
	for pos in [Vector2(cx - 360, cy - 160), Vector2(cx - 360, cy), Vector2(cx - 360, cy + 160)]:
		var term := terminal_scene.instantiate()
		term.position = pos
		add_child(term)

func _process(delta: float) -> void:
	super._process(delta)
	if _room_cleared:
		return
	if _check_delay > 0.0:
		_check_delay -= delta
		return
	if not is_instance_valid(_overseer):
		_room_cleared = true
		RunManager.on_enemies_killed(1)
		RunManager.on_boss_defeated()
